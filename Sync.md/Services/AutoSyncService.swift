import Foundation
import BackgroundTasks
import os.log

/// Manages automatic periodic git sync (pull → commit & push) for all repos
/// that have auto-sync enabled.
///
/// - While the app is in the foreground, uses a repeating `Task.sleep` loop.
/// - When the app moves to the background, schedules a `BGAppRefreshTask`.
@MainActor
final class AutoSyncService {

    // MARK: - Constants

    static let backgroundTaskIdentifier = "com.syncmd.autosync"
    private static let logger = Logger(subsystem: "com.syncmd", category: "AutoSync")

    // MARK: - State

    private weak var appState: AppState?
    private var foregroundTask: Task<Void, Never>?
    private var isRunning = false

    /// Timestamps of the last successful sync per repo, used to respect intervals.
    private var lastSyncTimes: [UUID: Date] = [:]

    // MARK: - Init

    init() {}

    // MARK: - Configuration

    func configure(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Foreground Sync Loop

    /// Start the foreground polling loop. Call when the app becomes active.
    func startForegroundLoop() {
        guard !isRunning else { return }
        isRunning = true
        Self.logger.info("Starting foreground auto-sync loop")

        foregroundTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.syncAllEligibleRepos()
                // Check every 30 seconds which repos are due
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    /// Stop the foreground polling loop. Call when the app goes to background.
    func stopForegroundLoop() {
        Self.logger.info("Stopping foreground auto-sync loop")
        foregroundTask?.cancel()
        foregroundTask = nil
        isRunning = false
    }

    // MARK: - Background Task (BGAppRefreshTask)

    /// Register the background task with the system. Call once at app launch.
    static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor in
                await AutoSyncService.handleBackgroundRefresh(refreshTask)
            }
        }
        logger.info("Registered background task: \(backgroundTaskIdentifier)")
    }

    /// Schedule the next background refresh. Call when the app enters background.
    func scheduleBackgroundSync() {
        guard let appState, appState.repos.contains(where: { $0.autoSyncEnabled && $0.isCloned }) else {
            return
        }

        // Find the shortest interval among enabled repos
        let minInterval = appState.repos
            .filter { $0.autoSyncEnabled && $0.isCloned }
            .map(\.autoSyncInterval)
            .min() ?? 300

        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: max(minInterval, 60))

        do {
            try BGTaskScheduler.shared.submit(request)
            Self.logger.info("Scheduled background sync in \(minInterval)s")
        } catch {
            Self.logger.error("Failed to schedule background sync: \(error.localizedDescription)")
        }
    }

    /// Cancel any pending background task requests.
    func cancelBackgroundSync() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.backgroundTaskIdentifier)
    }

    /// Handle a background refresh task from the system.
    private static func handleBackgroundRefresh(_ task: BGAppRefreshTask) async {
        logger.info("Background refresh task started")

        // We need access to the app state — create a temporary one
        // In practice, the app delegate / scene should provide this
        // For now, we complete and reschedule
        task.setTaskCompleted(success: true)
    }

    // MARK: - Core Sync Logic

    /// Iterate all repos and sync those that are due.
    private func syncAllEligibleRepos() async {
        guard let appState else { return }
        guard !appState.isSyncing else {
            Self.logger.debug("Skipping auto-sync: manual sync in progress")
            return
        }

        let eligibleRepos = appState.repos.filter { $0.autoSyncEnabled && $0.isCloned }
        guard !eligibleRepos.isEmpty else { return }

        for repo in eligibleRepos {
            guard !Task.isCancelled else { break }

            let lastSync = lastSyncTimes[repo.id] ?? .distantPast
            let elapsed = Date().timeIntervalSince(lastSync)

            guard elapsed >= repo.autoSyncInterval else { continue }

            Self.logger.info("Auto-syncing repo: \(repo.displayName)")
            await syncRepo(repo.id)
            lastSyncTimes[repo.id] = Date()
        }
    }

    /// Perform a pull → (commit & push if changes) cycle for a single repo.
    private func syncRepo(_ repoID: UUID) async {
        guard let appState else { return }
        guard let repo = appState.repo(id: repoID) else { return }

        let vaultDir = appState.vaultURL(for: repoID)
        let gitService = LocalGitService(localURL: vaultDir)

        guard gitService.hasGitDirectory else { return }

        // 1. Pull remote changes
        do {
            let pullResult = try await gitService.pull(pat: appState.pat)
            if pullResult.updated {
                Self.logger.info("Auto-pull updated \(repo.displayName) to \(pullResult.newCommitSHA.prefix(7))")
                appState.updateRepo(id: repoID) { config in
                    config.gitState.commitSHA = pullResult.newCommitSHA
                    config.gitState.lastSyncDate = Date()
                }
            }
        } catch {
            Self.logger.error("Auto-pull failed for \(repo.displayName): \(error.localizedDescription)")
            // Continue to try push even if pull fails (may be a network blip on fetch
            // but local changes can still be committed)
        }

        // 2. Detect local changes
        appState.detectChanges(repoID: repoID)
        let changeCount = appState.changeCounts[repoID] ?? 0

        // 3. If there are local changes, commit & push
        if changeCount > 0 {
            do {
                let timestamp = ISO8601DateFormatter().string(from: Date())
                let result = try await gitService.commitAndPush(
                    message: "Auto-sync from Sync.md (\(timestamp))",
                    authorName: repo.authorName,
                    authorEmail: repo.authorEmail,
                    pat: appState.pat
                )

                Self.logger.info("Auto-push \(repo.displayName): \(result.commitSHA.prefix(7))")
                appState.updateRepo(id: repoID) { config in
                    config.gitState.commitSHA = result.commitSHA
                    config.gitState.lastSyncDate = Date()
                }
                appState.detectChanges(repoID: repoID)
            } catch LocalGitError.noChanges {
                // Index matched after pull — nothing to push
            } catch {
                Self.logger.error("Auto-push failed for \(repo.displayName): \(error.localizedDescription)")
            }
        }
    }
}
