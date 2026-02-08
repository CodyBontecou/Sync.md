import SwiftUI

// MARK: - Sync.md Design System — Apple Liquid

enum SyncTheme {

    // MARK: Gradients

    static let primaryGradient = LinearGradient(
        colors: [Color(hex: 0x2E5CE5), Color(hex: 0x6B8CF7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let meshColors: [Color] = [
        Color(hex: 0x1A1A2E),
        Color(hex: 0x16213E),
        Color(hex: 0x0F3460),
        Color(hex: 0x1A1A2E),
        Color(hex: 0x162447),
        Color(hex: 0x1F4068),
        Color(hex: 0x1A1A2E),
        Color(hex: 0x16213E),
        Color(hex: 0x0F3460),
    ]

    static let successGradient = LinearGradient(
        colors: [Color(hex: 0x34C759), Color(hex: 0x30D158)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let pullGradient = LinearGradient(
        colors: [Color(hex: 0x007AFF), Color(hex: 0x5AC8FA)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let pushGradient = LinearGradient(
        colors: [Color(hex: 0x34C759), Color(hex: 0x30D158)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warningGradient = LinearGradient(
        colors: [Color(hex: 0xFF9500), Color(hex: 0xFFCC02)],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: Colors

    static let accent = Color(hex: 0x3478F6)
    static let surface = Color(.systemBackground)
    static let surfaceSecondary = Color(.secondarySystemBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let subtleText = Color(.tertiaryLabel)
}

// MARK: - Hex Color Initializer

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, padding: CGFloat = 16) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Liquid Button Style

struct LiquidButtonStyle: ButtonStyle {
    let gradient: LinearGradient

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Subtle Button Style

struct SubtleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(.ultraThinMaterial, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Animated Mesh Background

struct AnimatedMeshBackground: View {
    @State private var animate = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                // Create organic gradient blobs
                let colors: [(Color, CGPoint, CGFloat)] = [
                    (Color(hex: 0x3478F6, alpha: 0.3), blobPosition(time: time, offset: 0, size: size), size.width * 0.6),
                    (Color(hex: 0x5856D6, alpha: 0.25), blobPosition(time: time, offset: 2, size: size), size.width * 0.5),
                    (Color(hex: 0x30D158, alpha: 0.15), blobPosition(time: time, offset: 4, size: size), size.width * 0.45),
                    (Color(hex: 0x007AFF, alpha: 0.2), blobPosition(time: time, offset: 6, size: size), size.width * 0.55),
                ]

                for (color, center, radius) in colors {
                    let rect = CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    context.fill(
                        Ellipse().path(in: rect),
                        with: .color(color)
                    )
                    context.addFilter(.blur(radius: radius * 0.6))
                }
            }
        }
        .ignoresSafeArea()
    }

    private func blobPosition(time: Double, offset: Double, size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width * (0.5 + 0.3 * sin(time * 0.3 + offset)),
            y: size.height * (0.4 + 0.25 * cos(time * 0.25 + offset * 1.3))
        )
    }
}

// MARK: - Floating Orbs Background (lighter weight)

struct FloatingOrbs: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base
                Color(.systemGroupedBackground)

                // Orb 1
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: 0x3478F6, alpha: 0.25), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 320)
                    .offset(
                        x: sin(phase * 0.7) * 40 - 60,
                        y: cos(phase * 0.5) * 30 - 120
                    )

                // Orb 2
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: 0x5856D6, alpha: 0.2), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .offset(
                        x: cos(phase * 0.6) * 50 + 80,
                        y: sin(phase * 0.4) * 40 + 100
                    )

                // Orb 3
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: 0x30D158, alpha: 0.12), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .offset(
                        x: sin(phase * 0.8) * 30 + 40,
                        y: cos(phase * 0.6) * 50 - 40
                    )
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Pulse Animation

struct PulseEffect: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulseEffect() -> some View {
        modifier(PulseEffect())
    }
}

// MARK: - Staggered Appear Animation

struct StaggeredAppear: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.08)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppear(index: index))
    }
}
