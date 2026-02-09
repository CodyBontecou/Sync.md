import Foundation
import SwiftUI
import CommonCrypto

// MARK: - App State

@Observable
final class AppState {

    // MARK: - Repositories

    var repos: [RepoConfig] = []
    var changeCounts: [UUID: Int] = [:]

    // MARK: - Sync State

    var isSyncing: Bool = false
    var syncingRepoID: UUID? = nil
    var syncProgress: String = ""

    // MARK: - OAuth / Auth

    var isSignedIn: Bool = false
    var gitHubUsername: String = ""
    var gitHubDisplayName: String = ""
    var gitHubAvatarURL: String = ""
    var defaultAuthorName: String = ""
    var defaultAuthorEmail: String = ""
    var gitHubRepos: [GitHubRepo] = []
    var isLoadingRepos: Bool = false

    // MARK: - Errors

    var lastError: String? = nil
    var showError: Bool = false

    // MARK: - Security-Scoped URLs (runtime only)

    private var resolvedCustomURLs: [UUID: URL] = [:]
    private var accessingSecurityScope: Set<UUID> = []

    // MARK: - PAT

    var pat: String {
        get { KeychainService.load(key: "github_pat") ?? "" }
        set { KeychainService.save(key: "github_pat", value: newValue) }
    }

    // MARK: - Init

    init() {
        loadState()
    }

    // MARK: - Persistence

    private static var reposFileURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("SyncMD", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("repos.json")
    }

    private func loadState() {
        let defaults = UserDefaults.standard
        gitHubUsername = defaults.string(forKey: "gitHubUsername") ?? ""
        gitHubDisplayName = defaults.string(forKey: "gitHubDisplayName") ?? ""
        gitHubAvatarURL = defaults.string(forKey: "gitHubAvatarURL") ?? ""
        defaultAuthorName = defaults.string(forKey: "authorName") ?? ""
        defaultAuthorEmail = defaults.string(forKey: "authorEmail") ?? ""
        isSignedIn = !pat.isEmpty

        // Try to load multi-repo state
        if let data = try? Data(contentsOf: Self.reposFileURL) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let decoded = try? decoder.decode([RepoConfig].self, from: data) {
                repos = decoded
            }
        } else {
            // Migration from single-repo state
            migrateFromLegacy()
        }

        // Resolve custom vault bookmarks
        for repo in repos {
            resolveVaultBookmark(for: repo.id)
        }

        // Detect changes for all cloned repos
        for repo in repos where repo.isCloned {
            detectChanges(repoID: repo.id)
        }
    }

    private func migrateFromLegacy() {
        let defaults = UserDefaults.standard
        let legacyRepoURL = defaults.string(forKey: "repoURL") ?? ""
        let legacyIsSetUp = defaults.bool(forKey: "isSetUp")

        guard legacyIsSetUp, !legacyRepoURL.isEmpty else { return }

        let legacyGitState = GitState.loadLegacy() ?? .empty

        let config = RepoConfig(
            repoURL: legacyRepoURL,
            branch: defaults.string(forKey: "branch") ?? "main",
            authorName: defaults.string(forKey: "authorName") ?? "",
            authorEmail: defaults.string(forKey: "authorEmail") ?? "",
            vaultFolderName: defaults.string(forKey: "vaultFolderName") ?? "vault",
            customVaultBookmarkData: defaults.data(forKey: "vaultBookmark"),
            gitState: legacyGitState
        )

        repos = [config]
        saveRepos()

        // Clean up legacy keys
        GitState.deleteLegacy()
        defaults.removeObject(forKey: "isSetUp")
        defaults.removeObject(forKey: "repoURL")
        defaults.removeObject(forKey: "branch")
        defaults.removeObject(forKey: "vaultFolderName")
        defaults.removeObject(forKey: "vaultBookmark")
    }

    func saveRepos() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(repos) {
            try? data.write(to: Self.reposFileURL, options: .atomic)
        }
    }

    func saveGlobalSettings() {
        let defaults = UserDefaults.standard
        defaults.set(gitHubUsername, forKey: "gitHubUsername")
        defaults.set(gitHubDisplayName, forKey: "gitHubDisplayName")
        defaults.set(gitHubAvatarURL, forKey: "gitHubAvatarURL")
        defaults.set(defaultAuthorName, forKey: "authorName")
        defaults.set(defaultAuthorEmail, forKey: "authorEmail")
    }

    // MARK: - Repo Access

    func repo(id: UUID) -> RepoConfig? {
        repos.first { $0.id == id }
    }

    func repoIndex(id: UUID) -> Int? {
        repos.firstIndex { $0.id == id }
    }

    func vaultURL(for repoID: UUID) -> URL {
        if let customURL = resolvedCustomURLs[repoID] {
            return customURL
        }
        guard let repo = repo(id: repoID) else {
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        return repo.defaultVaultURL
    }

    func vaultDisplayPath(for repoID: UUID) -> String {
        if let customURL = resolvedCustomURLs[repoID] {
            return customURL.path
        }
        guard let repo = repo(id: repoID) else { return "" }
        return "On My iPhone › Sync.md › \(repo.vaultFolderName)"
    }

    func isUsingCustomLocation(for repoID: UUID) -> Bool {
        resolvedCustomURLs[repoID] != nil
    }

    // MARK: - Vault Location

    func setCustomVaultLocation(_ url: URL, for repoID: UUID) {
        // Stop any previous security-scoped access for this repo
        clearCustomLocation(for: repoID)

        guard url.startAccessingSecurityScopedResource() else { return }

        guard let bookmark = try? url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else {
            url.stopAccessingSecurityScopedResource()
            return
        }

        if let idx = repoIndex(id: repoID) {
            repos[idx].customVaultBookmarkData = bookmark
            saveRepos()
        }

        resolvedCustomURLs[repoID] = url
        accessingSecurityScope.insert(repoID)
    }

    func clearCustomLocation(for repoID: UUID) {
        if accessingSecurityScope.contains(repoID), let url = resolvedCustomURLs[repoID] {
            url.stopAccessingSecurityScopedResource()
            accessingSecurityScope.remove(repoID)
        }
        resolvedCustomURLs.removeValue(forKey: repoID)
        if let idx = repoIndex(id: repoID) {
            repos[idx].customVaultBookmarkData = nil
            saveRepos()
        }
    }

    private func resolveVaultBookmark(for repoID: UUID) {
        guard let repo = repo(id: repoID),
              let bookmarkData = repo.customVaultBookmarkData else { return }

        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return }

        if url.startAccessingSecurityScopedResource() {
            accessingSecurityScope.insert(repoID)
        }
        resolvedCustomURLs[repoID] = url

        if isStale {
            if let newBookmark = try? url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ), let idx = repoIndex(id: repoID) {
                repos[idx].customVaultBookmarkData = newBookmark
                saveRepos()
            }
        }
    }

    // MARK: - Change Detection

    func detectChanges(repoID: UUID) {
        guard let repo = repo(id: repoID), repo.isCloned else { return }
        let vaultDir = vaultURL(for: repoID)
        var count = 0

        let currentFiles = allFilePaths(in: vaultDir)

        for path in currentFiles {
            let url = vaultDir.appendingPathComponent(path)
            guard let data = try? Data(contentsOf: url) else { continue }
            let hash = gitBlobSHA1(data)
            if let storedSHA = repo.gitState.blobSHAs[path] {
                if hash != storedSHA { count += 1 }
            } else {
                count += 1
            }
        }

        for path in repo.gitState.blobSHAs.keys {
            if !currentFiles.contains(path) { count += 1 }
        }

        changeCounts[repoID] = count
    }

    private func allFilePaths(in directory: URL) -> Set<String> {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var paths = Set<String>()
        for case let url as URL in enumerator {
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if !isDir {
                let relative = url.path.replacingOccurrences(of: directory.path + "/", with: "")
                paths.insert(relative)
            }
        }
        return paths
    }

    private func computeChanges(repoID: UUID) -> [FileChange] {
        guard let repo = repo(id: repoID) else { return [] }
        let vaultDir = vaultURL(for: repoID)
        var changes: [FileChange] = []
        let currentFiles = allFilePaths(in: vaultDir)

        for path in currentFiles {
            let url = vaultDir.appendingPathComponent(path)
            guard let data = try? Data(contentsOf: url) else { continue }
            let hash = gitBlobSHA1(data)
            if let storedSHA = repo.gitState.blobSHAs[path] {
                if hash != storedSHA {
                    changes.append(FileChange(path: path, type: .modified, content: data))
                }
            } else {
                changes.append(FileChange(path: path, type: .added, content: data))
            }
        }

        for path in repo.gitState.blobSHAs.keys {
            if !currentFiles.contains(path) {
                changes.append(FileChange(path: path, type: .deleted, content: nil))
            }
        }

        return changes
    }

    /// Compute the Git blob SHA-1 hash for file content.
    /// Git hashes blobs as: SHA1("blob <size>\0" + <content>)
    private func gitBlobSHA1(_ data: Data) -> String {
        let header = "blob \(data.count)\0"
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        var ctx = CC_SHA1_CTX()
        CC_SHA1_Init(&ctx)
        header.utf8.withContiguousStorageIfAvailable { buf in
            CC_SHA1_Update(&ctx, buf.baseAddress, CC_LONG(buf.count))
        }
        data.withUnsafeBytes { buf in
            CC_SHA1_Update(&ctx, buf.baseAddress, CC_LONG(buf.count))
        }
        CC_SHA1_Final(&hash, &ctx)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - GitHub Service

    private func makeService(for repoID: UUID) -> GitHubService? {
        guard let repo = repo(id: repoID),
              let parsed = GitHubService.parseRepoURL(repo.repoURL) else { return nil }
        let token = pat
        guard !token.isEmpty else { return nil }
        return GitHubService(pat: token, owner: parsed.owner, repo: parsed.repo)
    }

    // MARK: - Git Operations

    func clone(repoID: UUID) async {
        guard let service = makeService(for: repoID),
              let idx = repoIndex(id: repoID) else {
            showError(message: "Invalid repository URL or missing PAT")
            return
        }

        isSyncing = true
        syncingRepoID = repoID
        syncProgress = "Detecting default branch..."

        do {
            var repo = repos[idx]

            if repo.branch.isEmpty {
                repo.branch = try await service.getDefaultBranch()
            }

            syncProgress = "Cloning repository..."
            let result = try await service.cloneRepository(branch: repo.branch)

            let vaultDir = vaultURL(for: repoID)
            let fm = FileManager.default
            if fm.fileExists(atPath: vaultDir.path) {
                try fm.removeItem(at: vaultDir)
            }
            try fm.createDirectory(at: vaultDir, withIntermediateDirectories: true)

            syncProgress = "Writing \(result.files.count) files..."
            for (path, content) in result.files {
                let fileURL = vaultDir.appendingPathComponent(path)
                let dir = fileURL.deletingLastPathComponent()
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                try content.write(to: fileURL)
            }

            repo.gitState = GitState(
                commitSHA: result.commitSHA,
                treeSHA: result.treeSHA,
                branch: repo.branch,
                blobSHAs: result.blobSHAs,
                lastSyncDate: Date()
            )

            repos[idx] = repo
            saveRepos()
            detectChanges(repoID: repoID)
            syncProgress = "Clone complete!"

        } catch {
            showError(message: error.localizedDescription)
        }

        try? await Task.sleep(for: .seconds(1))
        isSyncing = false
        syncingRepoID = nil
    }

    func pull(repoID: UUID) async {
        guard let service = makeService(for: repoID),
              let idx = repoIndex(id: repoID) else {
            showError(message: "Invalid repository URL or missing PAT")
            return
        }

        isSyncing = true
        syncingRepoID = repoID
        syncProgress = "Checking for updates..."

        do {
            var repo = repos[idx]

            guard let result = try await service.pull(
                branch: repo.gitState.branch,
                currentCommitSHA: repo.gitState.commitSHA
            ) else {
                syncProgress = "Already up to date!"
                try await Task.sleep(for: .seconds(1))
                isSyncing = false
                syncingRepoID = nil
                return
            }

            let vaultDir = vaultURL(for: repoID)
            let fm = FileManager.default

            syncProgress = "Applying \(result.modifiedFiles.count) changes..."
            for (path, content) in result.modifiedFiles {
                let fileURL = vaultDir.appendingPathComponent(path)
                let dir = fileURL.deletingLastPathComponent()
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                try content.write(to: fileURL)
            }

            for path in result.deletedFiles {
                let fileURL = vaultDir.appendingPathComponent(path)
                try? fm.removeItem(at: fileURL)
            }

            repo.gitState.commitSHA = result.newCommitSHA
            repo.gitState.treeSHA = result.newTreeSHA
            repo.gitState.lastSyncDate = Date()
            for (path, sha) in result.newBlobSHAs {
                repo.gitState.blobSHAs[path] = sha
            }
            for path in result.deletedFiles {
                repo.gitState.blobSHAs.removeValue(forKey: path)
            }

            repos[idx] = repo
            saveRepos()
            detectChanges(repoID: repoID)
            syncProgress = "Pull complete!"

        } catch {
            showError(message: error.localizedDescription)
        }

        try? await Task.sleep(for: .seconds(1))
        isSyncing = false
        syncingRepoID = nil
    }

    func push(repoID: UUID, message: String) async {
        guard let service = makeService(for: repoID),
              let idx = repoIndex(id: repoID) else {
            showError(message: "Invalid repository URL or missing PAT")
            return
        }

        isSyncing = true
        syncingRepoID = repoID
        syncProgress = "Preparing changes..."

        do {
            var repo = repos[idx]
            let changes = computeChanges(repoID: repoID)

            guard !changes.isEmpty else {
                syncProgress = "No changes to push"
                try await Task.sleep(for: .seconds(1))
                isSyncing = false
                syncingRepoID = nil
                return
            }

            let commitMsg = message.isEmpty ? "Update from Sync.md" : message

            syncProgress = "Pushing \(changes.count) changes..."
            let result = try await service.push(
                branch: repo.gitState.branch,
                currentCommitSHA: repo.gitState.commitSHA,
                currentTreeSHA: repo.gitState.treeSHA,
                changes: changes,
                message: commitMsg,
                authorName: repo.authorName,
                authorEmail: repo.authorEmail
            )

            repo.gitState.commitSHA = result.commitSHA
            repo.gitState.treeSHA = result.treeSHA
            repo.gitState.lastSyncDate = Date()
            for (path, sha) in result.newBlobSHAs {
                repo.gitState.blobSHAs[path] = sha
            }
            for change in changes where change.type == .deleted {
                repo.gitState.blobSHAs.removeValue(forKey: change.path)
            }

            repos[idx] = repo
            saveRepos()
            detectChanges(repoID: repoID)
            syncProgress = "Push complete!"

        } catch {
            showError(message: error.localizedDescription)
        }

        try? await Task.sleep(for: .seconds(1))
        isSyncing = false
        syncingRepoID = nil
    }

    // MARK: - Repo Management

    func addRepo(_ config: RepoConfig) {
        repos.append(config)
        saveRepos()
        resolveVaultBookmark(for: config.id)
    }

    func removeRepo(id: UUID) {
        let vaultDir = vaultURL(for: id)
        try? FileManager.default.removeItem(at: vaultDir)
        clearCustomLocation(for: id)
        changeCounts.removeValue(forKey: id)
        repos.removeAll { $0.id == id }
        saveRepos()
    }

    func updateRepo(id: UUID, mutate: (inout RepoConfig) -> Void) {
        guard let idx = repoIndex(id: id) else { return }
        mutate(&repos[idx])
        saveRepos()
    }

    // MARK: - OAuth

    func signInWithGitHub() async {
        do {
            let token = try await OAuthService.shared.signIn()
            pat = token
            isSignedIn = true

            syncProgress = "Fetching profile..."
            let user = try await GitHubService.fetchUser(token: token)
            gitHubUsername = user.login
            gitHubDisplayName = user.name ?? user.login
            gitHubAvatarURL = user.avatar_url ?? ""
            defaultAuthorName = user.name ?? user.login

            if let email = user.email, !email.isEmpty {
                defaultAuthorEmail = email
            } else {
                defaultAuthorEmail = try await GitHubService.fetchPrimaryEmail(token: token) ?? ""
            }

            isLoadingRepos = true
            gitHubRepos = try await GitHubService.fetchRepos(token: token)
            isLoadingRepos = false

            saveGlobalSettings()
        } catch let oauthError as OAuthError where oauthError.isCancelled {
            // User cancelled — do nothing
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func signInWithPAT(token: String) async {
        do {
            let user = try await GitHubService.fetchUser(token: token)
            pat = token
            isSignedIn = true
            gitHubUsername = user.login
            gitHubDisplayName = user.name ?? user.login
            gitHubAvatarURL = user.avatar_url ?? ""
            defaultAuthorName = user.name ?? user.login

            if let email = user.email, !email.isEmpty {
                defaultAuthorEmail = email
            } else {
                defaultAuthorEmail = try await GitHubService.fetchPrimaryEmail(token: token) ?? ""
            }

            isLoadingRepos = true
            gitHubRepos = try await GitHubService.fetchRepos(token: token)
            isLoadingRepos = false

            saveGlobalSettings()
        } catch {
            showError(message: "Invalid token: \(error.localizedDescription)")
        }
    }

    func refreshRepos() async {
        let token = pat
        guard !token.isEmpty else { return }
        isLoadingRepos = true
        do {
            gitHubRepos = try await GitHubService.fetchRepos(token: token)
        } catch {
            showError(message: error.localizedDescription)
        }
        isLoadingRepos = false
    }

    func signOut() {
        pat = ""
        isSignedIn = false
        gitHubUsername = ""
        gitHubDisplayName = ""
        gitHubAvatarURL = ""
        defaultAuthorName = ""
        defaultAuthorEmail = ""
        gitHubRepos = []
        saveGlobalSettings()
    }

    // MARK: - Error Handling

    private func showError(message: String) {
        lastError = message
        showError = true
    }
}
