import SwiftUI

@main
struct Sync_mdApp: App {
    @State private var appState = AppState()
    @State private var autoSync = AutoSyncService()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AutoSyncService.registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onAppear {
                    autoSync.configure(appState: appState)
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // Re-validate repos when returning to foreground —
                // the user may have deleted files via the Files app.
                appState.validateClonedRepos()

                // Refresh change counts for repos that are still cloned
                for repo in appState.repos where repo.isCloned {
                    appState.detectChanges(repoID: repo.id)
                }

                // Start foreground auto-sync loop
                autoSync.cancelBackgroundSync()
                autoSync.startForegroundLoop()

            case .background:
                // Switch to background task scheduling
                autoSync.stopForegroundLoop()
                autoSync.scheduleBackgroundSync()

            case .inactive:
                break

            @unknown default:
                break
            }
        }
    }
}
