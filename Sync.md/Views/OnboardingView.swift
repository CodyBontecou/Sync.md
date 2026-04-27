import SwiftUI

// MARK: - Step enum

private enum OBStep {
    case welcome, connectGitHub, localFirst, readyToSync
}

// MARK: - Shared sub-components

// ── Step progress indicator ──────────────────────────────────────────────────

private struct OBStepIndicator: View {
    let currentStep: Int  // 1–4

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...4, id: \.self) { s in
                circle(for: s)
                if s < 4 {
                    DashedHLine()
                        .stroke(
                            s < currentStep ? Color.obPurple.opacity(0.55) : Color.gray.opacity(0.32),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [2.5, 3.5])
                        )
                        .frame(height: 1.5)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 4)
                }
            }
        }
        .padding(.horizontal, 56)
    }

    @ViewBuilder private func circle(for s: Int) -> some View {
        if s < currentStep {
            ZStack {
                Circle().fill(Color.obPurple).frame(width: 30, height: 30)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
            }
        } else if s == currentStep {
            ZStack {
                Circle().fill(Color.obPurple).frame(width: 30, height: 30)
                Text("\(s)").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
            }
        } else {
            ZStack {
                Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1.5).frame(width: 30, height: 30)
                Text("\(s)").font(.system(size: 14, weight: .medium)).foregroundStyle(Color.gray.opacity(0.45))
            }
        }
    }
}

// ── Dashed horizontal line ───────────────────────────────────────────────────

private struct DashedHLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

// ── Sync.md logo (folder + sync arrow badge) ─────────────────────────────────

struct SyncMdLogoIcon: View {
    var iconSize: CGFloat = 36
    var cardSize: CGFloat = 66
    var cardCornerRadius: CGFloat = 18

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(.white)
                .frame(width: cardSize, height: cardSize)
                .shadow(color: Color.obPurple.opacity(0.18), radius: 12, x: 0, y: 4)

            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "folder.fill")
                    .font(.system(size: iconSize))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.obPurple)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: iconSize * 0.42, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: iconSize * 0.62, height: iconSize * 0.62)
                    .background(Circle().fill(Color.obPurple))
                    .overlay(Circle().stroke(.white, lineWidth: iconSize * 0.06))
                    .offset(x: iconSize * 0.18, y: iconSize * 0.18)
            }
            .frame(width: iconSize * 1.1, height: iconSize)
        }
    }
}

// ── Buttons ──────────────────────────────────────────────────────────────────

private struct OBPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var iconTrailing: Bool = false
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isDisabled ? Color.obPurple.opacity(0.4) : Color.obPurple)
                    .frame(height: 56)
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    HStack(spacing: 8) {
                        if let icon, !iconTrailing {
                            Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                        }
                        Text(title).font(.system(size: 17, weight: .semibold, design: .rounded))
                        if let icon, iconTrailing {
                            Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
    }
}

private struct OBOutlineButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .frame(height: 56)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.gray.opacity(0.22), lineWidth: 1.5))
                HStack(spacing: 8) {
                    if let icon { Image(systemName: icon).font(.system(size: 16, weight: .semibold)) }
                    Text(title).font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color.obText)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct OBGhostButton: View {
    let title: String
    var color: Color = .obPurple
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// ── Node graph canvas ────────────────────────────────────────────────────────

private struct NodeGraph: View {
    struct Node { let x, y: CGFloat; let color: Color }
    let nodes: [Node]
    let pairs: [(Int, Int)]

    var body: some View {
        Canvas { ctx, _ in
            for (a, b) in pairs {
                var p = Path()
                p.move(to: CGPoint(x: nodes[a].x, y: nodes[a].y))
                p.addLine(to: CGPoint(x: nodes[b].x, y: nodes[b].y))
                ctx.stroke(p, with: .color(.gray.opacity(0.22)), lineWidth: 1.5)
            }
            for n in nodes {
                let big = CGRect(x: n.x-7, y: n.y-7, width: 14, height: 14)
                let sml = CGRect(x: n.x-3.5, y: n.y-3.5, width: 7, height: 7)
                ctx.fill(Circle().path(in: big), with: .color(n.color.opacity(0.18)))
                ctx.stroke(Circle().path(in: big), with: .color(n.color.opacity(0.85)), lineWidth: 1.5)
                ctx.fill(Circle().path(in: sml), with: .color(n.color))
            }
        }
    }
}

// MARK: - Screen 1: Welcome

// ── Welcome illustration ─────────────────────────────────────────────────────

private struct WelcomeIllustration: View {
    @State private var floating = false

    var body: some View {
        ZStack {
            // Dashed orbit
            Ellipse()
                .stroke(Color.obPurple.opacity(0.13),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .frame(width: 290, height: 180)

            // Node graph (top-center)
            NodeGraph(
                nodes: [
                    .init(x: 22, y: 30, color: .obPurple),
                    .init(x: 82, y: 8, color: .obGreen),
                    .init(x: 142, y: 32, color: .obOrange),
                    .init(x: 100, y: 70, color: .obPurple),
                    .init(x: 50, y: 72, color: .obGreen),
                ],
                pairs: [(0,1),(1,2),(0,3),(3,4),(2,4)]
            )
            .frame(width: 164, height: 85)
            .offset(y: -82)

            // Code doc (right)
            codeDoc.offset(x: 93, y: -8)

            // Folder (center)
            folder

            // GitHub badge (bottom-left)
            badge(bg: Color(hex: 0x1C1C1E), fg: .white, icon: "person.fill", size: 20)
                .offset(x: -92, y: 68)

            // Sync badge (bottom-right)
            badge(bg: .white, fg: .obPurple, icon: "arrow.triangle.2.circlepath", size: 22)
                .offset(x: 90, y: 68)

            // Sparkles
            sparkle(20, .obPurpleL, -122, -42)
            sparkle(12, Color(hex: 0xFF6B6B), 130, -58)
            sparkle(10, Color(hex: 0xFFD600), 118, 36)
            sparkle(8, .obGreen, -102, 72)
        }
        .frame(width: 340, height: 260)
        .offset(y: floating ? -5 : 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { floating = true }
        }
    }

    private var folder: some View {
        ZStack {
            // Folder tab
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(hex: 0x8A7AE0))
                .frame(width: 56, height: 18)
                .offset(x: -48, y: -68)

            // Folder body
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: 0xA899F0))
                .frame(width: 154, height: 120)
                .offset(y: 4)

            // M↓ text
            Text("M↓")
                .font(.system(size: 40, weight: .black))
                .foregroundStyle(.white)
                .offset(y: 8)
        }
    }

    private var codeDoc: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(.white)
                .frame(width: 80, height: 102)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 2, y: 4)

            VStack(alignment: .leading, spacing: 7) {
                Text("</>")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: 0x4CAF50))
                ForEach([40, 30, 40, 24] as [CGFloat], id: \.self) { w in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.18))
                        .frame(width: w, height: 5)
                }
            }
            .padding(10)
        }
    }

    private func badge(bg: Color, fg: Color, icon: String, size: CGFloat) -> some View {
        Circle()
            .fill(.white)
            .frame(width: 52, height: 52)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
            .overlay(
                ZStack {
                    Circle().fill(bg).frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: size, weight: .semibold))
                        .foregroundStyle(fg)
                }
            )
    }

    private func sparkle(_ sz: CGFloat, _ col: Color, _ dx: CGFloat, _ dy: CGFloat) -> some View {
        Image(systemName: "sparkle")
            .font(.system(size: sz))
            .foregroundStyle(col.opacity(0.75))
            .offset(x: dx, y: dy)
    }
}

// ── Welcome screen ───────────────────────────────────────────────────────────

private struct WelcomeScreen: View {
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Logo
                VStack(spacing: 6) {
                    SyncMdLogoIcon(iconSize: 36, cardSize: 66, cardCornerRadius: 18)

                    HStack(spacing: 0) {
                        Text("Sync").font(.system(size: 21, weight: .bold, design: .rounded)).foregroundStyle(Color.obText)
                        Text(".md").font(.system(size: 21, weight: .bold, design: .rounded)).foregroundStyle(Color.obPurple)
                    }
                }
                .padding(.top, 56)
                .padding(.bottom, 20)

                // Hero text
                VStack(spacing: 2) {
                    Text("Markdown notes,")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(Color.obText)
                    HStack(spacing: 7) {
                        Text("synced")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(Color.obPurple)
                        Text("beautifully")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .italic()
                            .foregroundStyle(Color.obPurple)
                    }
                }
                .multilineTextAlignment(.center)

                Text("Write in Markdown, connect GitHub,\nand manage repos from your\niPhone and iPad.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.obSub)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 12)
                    .padding(.horizontal, 40)

                // Illustration
                WelcomeIllustration()
                    .padding(.vertical, 16)

                // Feature card
                VStack(spacing: 0) {
                    featureRow(icon: "square.grid.2x2.fill", iconFg: .obPurple, iconBg: .obPurpleDim,
                               title: "Multi-repo dashboard",
                               sub: "See all your repositories and sync status at a glance.")
                    Divider().padding(.leading, 70)
                    featureRow(icon: "network", iconFg: .obGreen, iconBg: .obGreenDim,
                               title: "Real GitHub sync",
                               sub: "Secure, fast, and reliable real-time syncing.")
                    Divider().padding(.leading, 70)
                    featureRow(icon: "waveform.path.ecg", iconFg: .obOrange, iconBg: .obOrangeDim,
                               title: "Diffs & repo health",
                               sub: "Review changes, spot conflicts, and monitor repo health.")
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
                .padding(.horizontal, 20)

                // Buttons
                VStack(spacing: 4) {
                    OBPrimaryButton(title: "Continue", icon: "arrow.right", iconTrailing: true, action: onContinue)
                    OBGhostButton(title: "Skip", action: onSkip)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.obBg)
    }

    private func featureRow(icon: String, iconFg: Color, iconBg: Color, title: String, sub: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconBg).frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .medium)).foregroundStyle(iconFg)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.obText)
                Text(sub).font(.system(size: 13)).foregroundStyle(Color.obSub)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.obSub)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Screen 2: Connect GitHub

// ── GitHub illustration ──────────────────────────────────────────────────────

private struct GitHubIllustration: View {
    @State private var floating = false

    var body: some View {
        ZStack {
            // Pink blob
            Ellipse()
                .fill(Color(hex: 0xFFD6E8).opacity(0.5))
                .frame(width: 200, height: 110)
                .blur(radius: 22)
                .offset(x: -110, y: 55)

            // Green leaf
            Image(systemName: "leaf.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color(hex: 0x4CAF50).opacity(0.18))
                .rotationEffect(.degrees(18))
                .offset(x: 148, y: -12)

            // Folders (left)
            ZStack {
                // Back folder
                ZStack {
                    RoundedRectangle(cornerRadius: 13).fill(Color(hex: 0xC4B8FF))
                        .frame(width: 86, height: 66)
                    RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0xB0A2FF))
                        .frame(width: 32, height: 13).offset(x: -27, y: -39)
                }
                .rotationEffect(.degrees(-5))
                .offset(x: -6, y: 5)

                // Front folder
                ZStack {
                    RoundedRectangle(cornerRadius: 13).fill(Color(hex: 0x9B8EF0))
                        .frame(width: 86, height: 66)
                    RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0x8A7AE0))
                        .frame(width: 32, height: 13).offset(x: -27, y: -39)
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 25)).foregroundStyle(.white.opacity(0.9))
                }
            }
            .offset(x: -112, y: 22)

            // Node graph
            NodeGraph(
                nodes: [
                    .init(x: 190, y: 28, color: .obPurple),
                    .init(x: 250, y: 8,  color: .obGreen),
                    .init(x: 300, y: 55, color: .obOrange),
                    .init(x: 240, y: 95, color: .obPurple),
                ],
                pairs: [(0,1),(1,2),(2,3),(0,3)]
            )
            .frame(width: 340, height: 130)
            .offset(y: -30)

            // GitHub badge (center)
            ZStack {
                Circle().fill(.white).frame(width: 84, height: 84)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                Circle().fill(Color(hex: 0x1C1C1E)).frame(width: 68, height: 68)
                Image(systemName: "person.fill")
                    .font(.system(size: 36)).foregroundStyle(.white)
            }
            .offset(x: 14, y: 22)

            // Sync badge
            ZStack {
                Circle().fill(.white).frame(width: 58, height: 58)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 26, weight: .semibold)).foregroundStyle(Color.obPurple)
            }
            .offset(x: 108, y: 32)

            // Sparkles
            Image(systemName: "sparkle").font(.system(size: 20))
                .foregroundStyle(Color.obPurple.opacity(0.5)).offset(x: -24, y: -58)
            Image(systemName: "sparkle").font(.system(size: 14))
                .foregroundStyle(Color.obPurpleL.opacity(0.5)).offset(x: 138, y: -48)
        }
        .frame(width: 340, height: 178)
        .offset(y: floating ? -4 : 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.9).repeatForever(autoreverses: true)) { floating = true }
        }
    }
}

// ── Connect GitHub screen ────────────────────────────────────────────────────

private struct ConnectGitHubScreen: View {
    let isSignedIn: Bool
    let isConnecting: Bool
    let connectError: String?
    let onConnect: () -> Void
    let onEnterprise: () -> Void
    let onSkip: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Nav
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.obText).padding(8)
                }
                Spacer()
                Button("Skip") { onSkip() }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.obPurple)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            OBStepIndicator(currentStep: 2)
                .padding(.top, 12)
                .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero text
                    HStack(spacing: 6) {
                        Text("Connect your")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(Color.obText)
                        Text("GitHub")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(Color.obPurple)
                    }

                    Text("Securely browse repositories, clone notes\nlocally, and push changes when you're ready.")
                        .font(.system(size: 15)).foregroundStyle(Color.obSub)
                        .multilineTextAlignment(.center).lineSpacing(3)
                        .padding(.top, 10).padding(.horizontal, 30)

                    // Illustration
                    GitHubIllustration()
                        .padding(.top, 16).padding(.bottom, 12)
                        .clipped()

                    // Status card
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(Color(hex: 0xE8E8E8)).frame(width: 62, height: 62)
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 38)).foregroundStyle(Color(hex: 0x1C1C1E))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isSignedIn ? "Connected" : "Not connected")
                                .font(.system(size: 17, weight: .bold)).foregroundStyle(Color.obText)
                            Text("Your credentials stay secure.")
                                .font(.system(size: 14)).foregroundStyle(Color.obSub)
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 11)).foregroundStyle(Color.obGreen)
                                Text("Read-only access")
                                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Color.obGreen)
                            }
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
                    .padding(.horizontal, 20)

                    // Feature pills
                    HStack(spacing: 8) {
                        pill(icon: "folder.fill",            color: .obPurple, text: "Browse repos")
                        pill(icon: "arrow.down.circle.fill", color: .obGreen,  text: "Clone to device")
                        pill(icon: "arrow.up.circle.fill",   color: .obOrange, text: "Push & sync")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                    if let err = connectError {
                        Text(err).font(.system(size: 14)).foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24).padding(.top, 10)
                    }

                    // Buttons
                    VStack(spacing: 10) {
                        OBPrimaryButton(
                            title: isSignedIn ? "Continue" : "Connect GitHub",
                            icon: isSignedIn ? "arrow.right" : "person.crop.circle.fill",
                            iconTrailing: isSignedIn,
                            isLoading: isConnecting,
                            action: isSignedIn ? onSkip : onConnect
                        )
                        OBOutlineButton(title: "Use GitHub Enterprise", icon: "building.2", action: onEnterprise)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Text("You can connect later in Settings.")
                        .font(.system(size: 13)).foregroundStyle(Color.obSub)
                        .padding(.top, 12).padding(.bottom, 36)
                }
            }
        }
        .background(Color.obBg)
    }

    private func pill(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(color)
            Text(text).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.obText)
                .lineLimit(1).fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Screen 3: Local-First

private struct LocalFirstScreen: View {
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Nav with logo
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.obText).padding(8)
                }
                Spacer()
                HStack(spacing: 6) {
                    SyncMdLogoIcon(iconSize: 16, cardSize: 30, cardCornerRadius: 9)
                    HStack(spacing: 0) {
                        Text("Sync").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Color.obText)
                        Text(".md").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Color.obPurple)
                    }
                }
                Spacer()
                Color.clear.frame(width: 42, height: 42)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            OBStepIndicator(currentStep: 3)
                .padding(.top, 12)
                .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero text
                    VStack(spacing: 2) {
                        Text("Local-first")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(Color.obText)
                        Text("by default")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(Color.obPurple)
                    }
                    .multilineTextAlignment(.center)

                    Text("Your Markdown files live on your device.\nSync.md helps you organize, review,\nand sync changes with GitHub.")
                        .font(.system(size: 15)).foregroundStyle(Color.obSub)
                        .multilineTextAlignment(.center).lineSpacing(3)
                        .padding(.top, 12).padding(.horizontal, 30)
                        .padding(.bottom, 28)

                    // Feature cards
                    VStack(spacing: 14) {
                        featureCard(icon: "iphone", iconBg: .obPurpleDim, iconFg: .obPurple,
                                    title: "Save on My iPhone",
                                    sub: "Keep repos in Files for offline access.",
                                    checkColor: Color.obPurple.opacity(0.6))
                        featureCard(icon: "checklist", iconBg: .obGreenDim, iconFg: .obGreen,
                                    title: "Track changes",
                                    sub: "Review diffs, stage files, and commit clearly.",
                                    checkColor: .obGreen)
                        featureCard(icon: "icloud.and.arrow.up",
                                    iconBg: Color(hex: 0xE8F0FF),
                                    iconFg: Color(hex: 0x4A90E2),
                                    title: "Sync when ready",
                                    sub: "Push updates manually with full control.",
                                    checkColor: Color.obPurple.opacity(0.6))
                    }
                    .padding(.horizontal, 20)

                    // Buttons
                    VStack(spacing: 4) {
                        OBPrimaryButton(title: "Next", icon: "arrow.right", iconTrailing: true, action: onNext)
                        OBGhostButton(title: "Back", action: onBack)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24).padding(.bottom, 40)
                }
            }
        }
        .background(Color.obBg)
    }

    private func featureCard(icon: String, iconBg: Color, iconFg: Color,
                             title: String, sub: String, checkColor: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(iconBg).frame(width: 66, height: 66)
                Image(systemName: icon).font(.system(size: 30)).foregroundStyle(iconFg)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.obText)
                Text(sub).font(.system(size: 14)).foregroundStyle(Color.obSub)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            ZStack {
                Circle().stroke(checkColor.opacity(0.3), lineWidth: 1.5).frame(width: 28, height: 28)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold)).foregroundStyle(checkColor)
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 3)
    }
}

// MARK: - Screen 4: Ready to Sync

private struct ReadyToSyncScreen: View {
    let onGetStarted: () -> Void
    let onBack: () -> Void

    @State private var celebrate = false

    var body: some View {
        VStack(spacing: 0) {
            // Nav
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.obText).padding(8)
                }
                Spacer()
                Text("Onboarding")
                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.obText)
                Spacer()
                Color.clear.frame(width: 42, height: 42)
            }
            .padding(.horizontal, 16).padding(.top, 8)

            OBStepIndicator(currentStep: 4)
                .padding(.top, 12).padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero text
                    VStack(spacing: 2) {
                        Text("You're ready")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(Color.obText)
                        HStack(spacing: 8) {
                            Text("to").font(.system(size: 34, weight: .black, design: .rounded)).foregroundStyle(Color.obText)
                            Text("sync").font(.system(size: 34, weight: .black, design: .rounded)).foregroundStyle(Color.obPurple)
                        }
                    }
                    .multilineTextAlignment(.center)

                    Text("Clone your first repository and\nstart writing in Markdown.")
                        .font(.system(size: 15)).foregroundStyle(Color.obSub)
                        .multilineTextAlignment(.center).lineSpacing(3)
                        .padding(.top, 12).padding(.horizontal, 40)
                        .padding(.bottom, 24)

                    // Success card
                    VStack(spacing: 16) {
                        // Animated checkmark + sparkles
                        ZStack {
                            ForEach(confettiItems, id: \.id) { item in
                                Image(systemName: "sparkle")
                                    .font(.system(size: item.size))
                                    .foregroundStyle(item.color)
                                    .offset(x: item.x, y: item.y)
                                    .scaleEffect(celebrate ? 1 : 0.3)
                                    .opacity(celebrate ? 1 : 0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.6)
                                        .delay(item.delay), value: celebrate)
                            }
                            Circle()
                                .fill(Color.obGreen)
                                .frame(width: 72, height: 72)
                                .scaleEffect(celebrate ? 1 : 0.5)
                                .animation(.spring(response: 0.5, dampingFraction: 0.65), value: celebrate)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 30, weight: .bold))
                                        .foregroundStyle(.white)
                                )
                        }
                        .frame(height: 110)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation { celebrate = true }
                            }
                        }

                        VStack(spacing: 4) {
                            Text("Everything is set!")
                                .font(.system(size: 20, weight: .bold)).foregroundStyle(Color.obText)
                            Text("Your repo is synced and ready to go.")
                                .font(.system(size: 14)).foregroundStyle(Color.obSub)
                        }

                        // Repo preview
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12).fill(Color.obPurpleDim)
                                    .frame(width: 52, height: 52)
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 26)).foregroundStyle(Color.obPurple)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("personal-notes")
                                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.obText)
                                Text("acme-labs/personal-notes")
                                    .font(.system(size: 13)).foregroundStyle(Color.obSub)
                                HStack(spacing: 6) {
                                    repoBadge("main", fg: Color.obText, bg: Color(hex: 0xF0EEF8))
                                    repoBadge("✓ Synced", fg: .obGreen, bg: .obGreenDim)
                                    repoBadge("Ready", fg: .obGreen, bg: .obGreenDim)
                                }
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        // Info row
                        HStack {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 12))
                                Text("Auto-sync enabled").font(.system(size: 13))
                            }
                            Rectangle().fill(Color.gray.opacity(0.25)).frame(width: 1, height: 16).padding(.horizontal, 8)
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.shield").font(.system(size: 12))
                                Text("Private & secure").font(.system(size: 13))
                            }
                        }
                        .foregroundStyle(Color.obSub)
                    }
                    .padding(20)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 4)
                    .padding(.horizontal, 20)

                    // Action cards
                    HStack(spacing: 12) {
                        actionCard(icon: "arrow.down.circle.fill", iconFg: .obPurple, iconBg: .obPurpleDim,
                                   title: "Clone Repository", sub: "Clone your first repo in seconds.")
                        actionCard(icon: "square.grid.2x2.fill", iconFg: .obPurple, iconBg: .obPurpleDim,
                                   title: "Open Dashboard", sub: "View all your repos and sync status.")
                    }
                    .padding(.horizontal, 20).padding(.top, 16)

                    // Buttons
                    VStack(spacing: 4) {
                        OBPrimaryButton(title: "Get Started", icon: "sparkles", action: onGetStarted)
                        OBGhostButton(title: "Back", action: onBack)
                    }
                    .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 40)
                }
            }
        }
        .background(Color.obBg)
    }

    private struct ConfettiItem {
        let id: Int; let size: CGFloat; let color: Color; let x, y: CGFloat; let delay: Double
    }

    private var confettiItems: [ConfettiItem] {
        [
            .init(id: 0, size: 14, color: Color.obPurple.opacity(0.55),   x: -52, y: -10, delay: 0.0),
            .init(id: 1, size: 10, color: Color.obOrange.opacity(0.65),   x: 52,  y: -22, delay: 0.05),
            .init(id: 2, size: 8,  color: Color.obGreen.opacity(0.55),    x: -38, y: 26,  delay: 0.08),
            .init(id: 3, size: 12, color: Color.obPurpleL.opacity(0.6),   x: 48,  y: 26,  delay: 0.1),
            .init(id: 4, size: 8,  color: Color(hex: 0xFF6B9D).opacity(0.55), x: 8, y: -46, delay: 0.12),
            .init(id: 5, size: 6,  color: Color.obGreen.opacity(0.4),     x: -14, y: 42,  delay: 0.15),
        ]
    }

    private func repoBadge(_ text: String, fg: Color, bg: Color) -> some View {
        Text(text).font(.system(size: 12, weight: .medium)).foregroundStyle(fg)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(bg).clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private func actionCard(icon: String, iconFg: Color, iconBg: Color, title: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(iconBg).frame(width: 40, height: 40)
                    Image(systemName: icon).font(.system(size: 20)).foregroundStyle(iconFg)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Color.obSub)
            }
            Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.obText)
            Text(sub).font(.system(size: 12)).foregroundStyle(Color.obSub)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Enterprise PAT Sheet

private struct EnterpriseSheet: View {
    @Binding var token: String
    @Binding var showToken: Bool
    let isLoading: Bool
    let onSignIn: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Use a Personal Access Token for GitHub Enterprise or fine-grained access control.")
                    .font(.system(size: 15)).foregroundStyle(Color.obSub)
                    .padding(.horizontal, 20).padding(.top, 8)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Group {
                            if showToken {
                                TextField("ghp_...", text: $token)
                            } else {
                                SecureField("ghp_...", text: $token)
                            }
                        }
                        .autocorrectionDisabled().textInputAutocapitalization(.never)
                        .font(.system(size: 15, design: .monospaced))

                        Button { showToken.toggle() } label: {
                            Image(systemName: showToken ? "eye.slash" : "eye")
                                .font(.system(size: 14)).foregroundStyle(Color.obSub)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Link("Create a token on GitHub →",
                         destination: URL(string: "https://github.com/settings/tokens/new?scopes=repo,user:email&description=Sync.md")!)
                    .font(.system(size: 13)).foregroundStyle(Color.obPurple)
                }
                .padding(.horizontal, 20)

                OBPrimaryButton(
                    title: "Sign In", icon: "arrow.right", isLoading: isLoading,
                    isDisabled: token.trimmingCharacters(in: .whitespaces).isEmpty,
                    action: onSignIn
                )
                .padding(.horizontal, 20)

                Spacer()
            }
            .background(Color.obBg)
            .navigationTitle("GitHub Enterprise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                }
            }
        }
    }
}

// MARK: - Main OnboardingView

struct OnboardingView: View {
    @Environment(AppState.self) private var state

    @State private var step: OBStep = .welcome
    @State private var isConnecting = false
    @State private var connectError: String? = nil
    @State private var showEnterprise = false
    @State private var patToken = ""
    @State private var showToken = false
    @State private var isPATLoading = false

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal:   .move(edge: .leading).combined(with: .opacity)
        )
    }

    var body: some View {
        ZStack {
            Color.obBg.ignoresSafeArea()

            Group {
                switch step {
                case .welcome:
                    WelcomeScreen(
                        onContinue: { advance() },
                        onSkip: { finishOnboarding() }
                    )
                    .transition(pageTransition)

                case .connectGitHub:
                    ConnectGitHubScreen(
                        isSignedIn: state.isSignedIn,
                        isConnecting: isConnecting,
                        connectError: connectError,
                        onConnect: { connectGitHub() },
                        onEnterprise: { showEnterprise = true },
                        onSkip: { advance() },
                        onBack: { goTo(.welcome) }
                    )
                    .transition(pageTransition)

                case .localFirst:
                    LocalFirstScreen(
                        onNext: { advance() },
                        onBack: { goTo(.connectGitHub) }
                    )
                    .transition(pageTransition)

                case .readyToSync:
                    ReadyToSyncScreen(
                        onGetStarted: { finishOnboarding() },
                        onBack: { goTo(.localFirst) }
                    )
                    .transition(pageTransition)
                }
            }
            .animation(.easeInOut(duration: 0.32), value: step.id)
        }
        .sheet(isPresented: $showEnterprise) {
            EnterpriseSheet(
                token: $patToken,
                showToken: $showToken,
                isLoading: isPATLoading,
                onSignIn: { connectWithPAT() },
                onDismiss: { showEnterprise = false }
            )
        }
    }

    // MARK: Navigation helpers

    private func advance() {
        switch step {
        case .welcome:       goTo(.connectGitHub)
        case .connectGitHub: goTo(.localFirst)
        case .localFirst:    goTo(.readyToSync)
        case .readyToSync:   finishOnboarding()
        }
    }

    private func goTo(_ s: OBStep) {
        withAnimation(.easeInOut(duration: 0.32)) { step = s }
    }

    // MARK: Auth

    private func connectGitHub() {
        isConnecting = true
        connectError = nil
        Task {
            await state.signInWithGitHub()
            isConnecting = false
            if state.isSignedIn {
                goTo(.localFirst)
            } else if let err = state.lastError {
                connectError = err
            }
        }
    }

    private func connectWithPAT() {
        isPATLoading = true
        Task {
            await state.signInWithPAT(token: patToken)
            isPATLoading = false
            if state.isSignedIn {
                showEnterprise = false
                patToken = ""
                goTo(.localFirst)
            }
        }
    }

    // MARK: Finish

    private func finishOnboarding() {
        state.hasSeenOnboarding = true
        if state.isSignedIn {
            state.hasCompletedOnboarding = true
        }
        state.saveGlobalSettings()
    }
}

// MARK: - OBStep hashable for animation value

extension OBStep: Hashable {
    var id: Int {
        switch self {
        case .welcome: return 0
        case .connectGitHub: return 1
        case .localFirst: return 2
        case .readyToSync: return 3
        }
    }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
