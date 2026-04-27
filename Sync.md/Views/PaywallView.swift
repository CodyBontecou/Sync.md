import SwiftUI
import StoreKit

// MARK: - Paywall folder illustration

private struct PaywallIllustration: View {
    @State private var floating = false

    var body: some View {
        ZStack {
            // Dashed orbit
            Ellipse()
                .stroke(Color.obPurple.opacity(0.12),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .frame(width: 300, height: 185)

            // Node graph (top)
            Canvas { ctx, _ in
                let nodes: [(CGFloat, CGFloat, Color)] = [
                    (40,  15, Color.obPurple),
                    (110,  0, Color.obGreen),
                    (175, 22, Color.obOrange),
                    (130, 58, Color.obPurple),
                    (65,  58, Color.obGreen),
                ]
                let pairs = [(0,1),(1,2),(0,3),(3,4),(2,4)]
                for (a, b) in pairs {
                    var p = Path()
                    p.move(to: CGPoint(x: nodes[a].0, y: nodes[a].1))
                    p.addLine(to: CGPoint(x: nodes[b].0, y: nodes[b].1))
                    ctx.stroke(p, with: .color(.gray.opacity(0.2)), lineWidth: 1.5)
                }
                for (x, y, col) in nodes {
                    let big = CGRect(x: x-7, y: y-7, width: 14, height: 14)
                    let sml = CGRect(x: x-3.5, y: y-3.5, width: 7, height: 7)
                    ctx.fill(Circle().path(in: big), with: .color(col.opacity(0.18)))
                    ctx.stroke(Circle().path(in: big), with: .color(col.opacity(0.85)), lineWidth: 1.5)
                    ctx.fill(Circle().path(in: sml), with: .color(col))
                }
            }
            .frame(width: 215, height: 70)
            .offset(y: -88)

            // Code doc (right)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14).fill(.white).frame(width: 82, height: 104)
                    .shadow(color: .black.opacity(0.07), radius: 8, x: 2, y: 4)
                VStack(alignment: .leading, spacing: 7) {
                    Text("</>").font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: 0x4CAF50))
                    ForEach([42, 32, 42, 26] as [CGFloat], id: \.self) { w in
                        RoundedRectangle(cornerRadius: 2).fill(Color.gray.opacity(0.18))
                            .frame(width: w, height: 5)
                    }
                }
                .padding(10)
            }
            .offset(x: 96, y: -6)

            // Main folder
            ZStack {
                RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0x8A7AE0))
                    .frame(width: 58, height: 18).offset(x: -54, y: -74)
                RoundedRectangle(cornerRadius: 20).fill(Color(hex: 0xA899F0))
                    .frame(width: 162, height: 128).offset(y: 4)
                Text("M↓").font(.system(size: 42, weight: .black)).foregroundStyle(.white)
                    .offset(y: 8)
            }

            // GitHub badge (bottom-left)
            Circle().fill(.white).frame(width: 54, height: 54)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
                .overlay(
                    ZStack {
                        Circle().fill(Color(hex: 0x1C1C1E)).frame(width: 40, height: 40)
                        Image(systemName: "person.fill").font(.system(size: 22)).foregroundStyle(.white)
                    }
                )
                .offset(x: -96, y: 70)

            // Sync badge (bottom-right)
            Circle().fill(.white).frame(width: 54, height: 54)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
                .overlay(
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 24, weight: .semibold)).foregroundStyle(Color.obPurple)
                )
                .offset(x: 96, y: 70)

            // Sparkles
            Image(systemName: "sparkle").font(.system(size: 18)).foregroundStyle(Color.obPurpleL.opacity(0.7))
                .offset(x: -128, y: -38)
            Image(systemName: "sparkle").font(.system(size: 12)).foregroundStyle(Color(hex: 0xFF6B6B).opacity(0.7))
                .offset(x: 138, y: -60)
            Image(systemName: "sparkle").font(.system(size: 10)).foregroundStyle(Color(hex: 0xFFD600).opacity(0.7))
                .offset(x: 124, y: 30)
        }
        .frame(width: 340, height: 270)
        .offset(y: floating ? -5 : 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.7).repeatForever(autoreverses: true)) { floating = true }
        }
    }
}

// MARK: - PaywallView

struct PaywallView: View {
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: Plan = .lifetime

    enum Plan { case monthly, lifetime }

    var body: some View {
        ZStack(alignment: .top) {
            // Warm background
            Color.obBg.ignoresSafeArea()

            // Decorative blobs
            ZStack {
                Circle().fill(Color.obPurple.opacity(0.06)).frame(width: 320).blur(radius: 32)
                    .offset(x: 100, y: -100)
                Circle().fill(Color(hex: 0xFF9BD3).opacity(0.07)).frame(width: 220).blur(radius: 24)
                    .offset(x: -70, y: 90)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Close button ──────────────────────────────────
                    HStack {
                        Button { dismiss() } label: {
                            ZStack {
                                Circle().fill(Color.white.opacity(0.9)).frame(width: 34, height: 34)
                                Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.obText)
                            }
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.top, 16)

                    // ── Logo row ──────────────────────────────────────
                    HStack(spacing: 8) {
                        SyncMdLogoIcon(iconSize: 26, cardSize: 48, cardCornerRadius: 14)
                        HStack(spacing: 0) {
                            Text("Sync").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(Color.obText)
                            Text(".md").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(Color.obPurple)
                        }
                        Text("Pro").font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white).padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.obPurple).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.top, 8).padding(.bottom, 16)

                    // ── Hero text ─────────────────────────────────────
                    VStack(spacing: 4) {
                        Text("Unlock unlimited")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(Color.obText)
                        Text("GitHub sync")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(Color.obPurple)
                    }
                    .multilineTextAlignment(.center)

                    Text("Go beyond the free plan with unlimited\nrepositories, unlimited sync sessions,\nand advanced repo tools.")
                        .font(.system(size: 15)).foregroundStyle(Color.obSub)
                        .multilineTextAlignment(.center).lineSpacing(3)
                        .padding(.top, 10).padding(.horizontal, 30)

                    // ── Illustration ──────────────────────────────────
                    PaywallIllustration()
                        .padding(.vertical, 12)

                    // ── Plan selector ─────────────────────────────────
                    VStack(spacing: 10) {
                        planRow(plan: .monthly,
                                title: "Monthly",
                                price: priceForMonthly,
                                isBestValue: false)
                        planRow(plan: .lifetime,
                                title: "Lifetime",
                                price: priceForLifetime,
                                isBestValue: true)
                    }
                    .padding(.horizontal, 20).padding(.bottom, 20)

                    // ── Features ──────────────────────────────────────
                    VStack(spacing: 0) {
                        featureRow(icon: "folder.fill",                  iconBg: .obPurpleDim, iconFg: .obPurple, text: "Unlimited repositories")
                        featureRow(icon: "arrow.triangle.2.circlepath",  iconBg: .obGreenDim,  iconFg: .obGreen,  text: "Unlimited sync sessions")
                        featureRow(icon: "chart.bar.fill",               iconBg: .obOrangeDim, iconFg: .obOrange, text: "Advanced diff insights")
                        featureRow(icon: "bolt.fill",                    iconBg: .obPurpleDim, iconFg: .obPurple, text: "Priority updates", last: true)
                    }
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 3)
                    .padding(.horizontal, 20).padding(.bottom, 20)

                    // ── Error ─────────────────────────────────────────
                    if let err = purchaseManager.purchaseError {
                        Text(err).font(.system(size: 14)).foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24).padding(.bottom, 12)
                    }

                    // ── CTA ───────────────────────────────────────────
                    VStack(spacing: 10) {
                        // Primary: gradient purchase button
                        Button {
                            Task { await purchaseManager.purchase() }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(LinearGradient(colors: [Color(hex: 0x7B68EE), Color(hex: 0x9B8EF0)],
                                                        startPoint: .leading, endPoint: .trailing))
                                    .frame(height: 56)
                                if purchaseManager.isPurchasing {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    HStack(spacing: 8) {
                                        Image(systemName: "sparkles").font(.system(size: 16, weight: .semibold))
                                        Text("Start Free Trial").font(.system(size: 17, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(purchaseManager.isPurchasing || purchaseManager.isRestoring)

                        // Secondary: continue free
                        Button { dismiss() } label: {
                            Text("Continue with Free")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.obPurple)
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)

                    // ── Footer ────────────────────────────────────────
                    VStack(spacing: 6) {
                        Button {
                            Task { await purchaseManager.restore() }
                        } label: {
                            Text(purchaseManager.isRestoring ? "Restoring…" : "Restore Purchases")
                                .font(.system(size: 14)).foregroundStyle(Color.obPurple.opacity(0.8))
                                .underline()
                        }
                        .buttonStyle(.plain)
                        .disabled(purchaseManager.isRestoring)

                        Text("Cancel anytime.")
                            .font(.system(size: 13)).foregroundStyle(Color.obSub)
                    }
                    .padding(.top, 4).padding(.bottom, 44)
                }
            }
        }
        .task {
            await purchaseManager.refreshStatus()
            if purchaseManager.product == nil {
                await purchaseManager.loadProduct()
            }
        }
        .onChange(of: purchaseManager.isUnlocked) { _, unlocked in
            if unlocked { dismiss() }
        }
    }

    // MARK: - Price labels

    private var priceForMonthly: String { "$4.99 / month" }

    private var priceForLifetime: String {
        if let p = purchaseManager.product { return "\(p.displayPrice) one-time" }
        return "$59 one-time"
    }

    // MARK: - Plan row

    private func planRow(plan: Plan, title: String, price: String, isBestValue: Bool) -> some View {
        let selected = selectedPlan == plan
        return Button {
            withAnimation(.easeInOut(duration: 0.14)) { selectedPlan = plan }
        } label: {
            HStack(spacing: 12) {
                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(selected ? Color.obPurple : Color.gray.opacity(0.3),
                                lineWidth: selected ? 4.5 : 1.5)
                        .frame(width: 22, height: 22)
                    if selected {
                        Circle().fill(Color.obPurple).frame(width: 10, height: 10)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.obText)
                    Text(price).font(.system(size: 15)).foregroundStyle(Color.obPurple)
                }
                Spacer()

                if isBestValue {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").font(.system(size: 11)).foregroundStyle(Color.obOrange)
                        Text("Best value").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.obOrange)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.obOrange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Color.obPurple : Color.clear, lineWidth: 2)
            )
            .shadow(color: selected ? Color.obPurple.opacity(0.14) : .black.opacity(0.04),
                    radius: selected ? 8 : 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Feature row

    private func featureRow(icon: String, iconBg: Color, iconFg: Color, text: String, last: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9).fill(iconBg).frame(width: 36, height: 36)
                    Image(systemName: icon).font(.system(size: 16)).foregroundStyle(iconFg)
                }
                Text(text).font(.system(size: 15)).foregroundStyle(Color.obText)
                Spacer()
                Image(systemName: "checkmark.circle.fill").font(.system(size: 20)).foregroundStyle(Color.obGreen)
            }
            .padding(.vertical, 13).padding(.horizontal, 16)
            if !last { Divider().padding(.leading, 66) }
        }
    }
}

#Preview {
    PaywallView()
}
