import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var state
    @State private var showContent = false

    var body: some View {
        Group {
            if state.isSignedIn {
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
