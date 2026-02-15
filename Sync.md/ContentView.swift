import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var state
    @State private var showContent = false

    var body: some View {
        Group {
            // Show main app if: (1) signed in AND completed onboarding, OR (2) has repos already (existing user)
            if (state.isSignedIn && state.hasCompletedOnboarding) || !state.repos.isEmpty {
                RepoListView()
            } else {
                SetupView()
            }
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
