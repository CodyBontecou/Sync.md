import SwiftUI

@main
struct Sync_mdApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onOpenURL { url in
                    // x-callback-url from external apps (e.g. Obsidian plugin)
                    // Format: syncmd://x-callback-url/<action>?repo=<name>&x-success=<url>
                    let handler = CallbackURLHandler(appState: appState)
                    if handler.canHandle(url) {
                        handler.handle(url)
                    }
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Re-validate repos when returning to foreground —
                // the user may have deleted files via the Files app.
                appState.validateClonedRepos()

                // Refresh change counts for repos that are still cloned
                for repo in appState.repos where repo.isCloned {
                    appState.detectChanges(repoID: repo.id)
                }
            }
        }
    }
}
