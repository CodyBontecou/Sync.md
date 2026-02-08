import SwiftUI

struct SetupView: View {
    @Environment(AppState.self) private var state

    // PAT flow
    @State private var showPATFlow = false
    @State private var patToken = ""
    @State private var showPAT = false
    @State private var isSigningIn = false

    // Animation
    @State private var heroAppeared = false
    @State private var contentAppeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                FloatingOrbs()

                ScrollView {
                    VStack(spacing: 0) {
                        hero
                            .padding(.bottom, 32)

                        if showPATFlow {
                            patFlowView
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        } else {
                            signInOptions
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        }
                    }
                    .padding(.bottom, 60)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: Binding(
                get: { state.showError },
                set: { state.showError = $0 }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(state.lastError ?? "Unknown error")
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: 0x3478F6, alpha: 0.3), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 10)

                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 80, height: 80)
                        .shadow(color: Color(hex: 0x3478F6, alpha: 0.2), radius: 20, x: 0, y: 8)

                    Image(systemName: "arrow.triangle.2.circlepath.doc.on.clipboard")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(SyncTheme.primaryGradient)
                }
            }
            .scaleEffect(heroAppeared ? 1 : 0.5)
            .opacity(heroAppeared ? 1 : 0)

            VStack(spacing: 6) {
                Text("Sync.md")
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Text("Markdown notes synced with Git")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .opacity(heroAppeared ? 1 : 0)
            .offset(y: heroAppeared ? 0 : 10)
        }
        .padding(.top, 60)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                heroAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
                contentAppeared = true
            }
        }
    }

    // MARK: - Sign In Options

    private var signInOptions: some View {
        VStack(spacing: 20) {
            // Primary: OAuth
            Button {
                Task { await state.signInWithGitHub() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 20))
                    Text("Sign in with GitHub")
                }
            }
            .buttonStyle(LiquidButtonStyle(gradient: SyncTheme.primaryGradient))
            .padding(.horizontal, 24)
            .staggeredAppear(index: 0)

            // Divider
            HStack(spacing: 12) {
                Capsule()
                    .fill(.quaternary)
                    .frame(height: 1)
                Text("or")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
                Capsule()
                    .fill(.quaternary)
                    .frame(height: 1)
            }
            .padding(.horizontal, 40)
            .staggeredAppear(index: 1)

            // Secondary: PAT
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    showPATFlow = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 14))
                    Text("Use a Personal Access Token")
                }
            }
            .buttonStyle(SubtleButtonStyle())
            .staggeredAppear(index: 2)
        }
        .opacity(contentAppeared ? 1 : 0)
    }

    // MARK: - PAT Flow

    private var patFlowView: some View {
        VStack(spacing: 20) {
            // Back button
            HStack {
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        showPATFlow = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(SyncTheme.accent)
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            // PAT token field
            VStack(alignment: .leading, spacing: 8) {
                Label("Personal Access Token", systemImage: "key.fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                HStack(spacing: 10) {
                    Group {
                        if showPAT {
                            TextField("ghp_...", text: $patToken)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("ghp_...", text: $patToken)
                        }
                    }
                    .font(.system(size: 16, design: .rounded))

                    Button { showPAT.toggle() } label: {
                        Image(systemName: showPAT ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Link(destination: URL(string: "https://github.com/settings/tokens/new?scopes=repo&description=Sync.md")!) {
                    HStack(spacing: 4) {
                        Text("Create a PAT on GitHub")
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(SyncTheme.accent)
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)

            // Sign in button
            Button {
                isSigningIn = true
                Task {
                    await state.signInWithPAT(token: patToken)
                    isSigningIn = false
                }
            } label: {
                HStack(spacing: 10) {
                    if isSigningIn {
                        ProgressView()
                            .tint(.white)
                            .controlSize(.small)
                        Text("Signing in…")
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Sign In")
                    }
                }
            }
            .buttonStyle(LiquidButtonStyle(gradient: SyncTheme.primaryGradient))
            .disabled(patToken.trimmingCharacters(in: .whitespaces).isEmpty || isSigningIn)
            .opacity(patToken.trimmingCharacters(in: .whitespaces).isEmpty || isSigningIn ? 0.6 : 1)
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Liquid Text Field

struct LiquidTextField: View {
    let icon: String
    let label: String
    let placeholder: String
    @Binding var text: String
    var disableAutocorrect: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            TextField(placeholder, text: $text)
                .font(.system(size: 16, design: .rounded))
                .autocorrectionDisabled(disableAutocorrect)
                .textInputAutocapitalization(disableAutocorrect ? .never : .words)
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.horizontal, 20)
    }
}
