import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            FloatingOrbs()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    hero
                        .padding(.top, 28)

                    VStack(spacing: 12) {
                        PaywallFeatureRow(icon: "tray.full.fill", text: "Unlimited repositories")
                        PaywallFeatureRow(icon: "arrow.triangle.branch", text: "Sync any number of vaults")
                        PaywallFeatureRow(icon: "sparkles", text: "All future features included")
                        PaywallFeatureRow(icon: "lock.open.fill", text: "One-time payment — no subscription")
                    }

                    ctaSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 18)
            .padding(.trailing, 20)
            .accessibilityLabel("Dismiss")
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

    private var hero: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [SyncTheme.blue.opacity(0.22), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 150, height: 150)

                Image("PaywallLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: SyncTheme.blue.opacity(0.24), radius: 18, x: 0, y: 8)
            }

            VStack(spacing: 8) {
                Text("Unlock Sync.md")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text("You've reached the 1 free repository limit")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var ctaSection: some View {
        VStack(spacing: 16) {
            if let error = purchaseManager.purchaseError {
                Text(error)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(
                        error.contains("cody@isolated.tech")
                            ? SyncTheme.subtleText
                            : Color.red
                    )
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await purchaseManager.purchase() }
            } label: {
                HStack(spacing: 8) {
                    if purchaseManager.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }

                    Text(priceButtonLabel)
                }
            }
            .buttonStyle(LiquidButtonStyle(gradient: SyncTheme.primaryGradient))
            .disabled(purchaseManager.isPurchasing || purchaseManager.isRestoring)

            Button {
                Task { await purchaseManager.restore() }
            } label: {
                HStack(spacing: 8) {
                    if purchaseManager.isRestoring {
                        ProgressView()
                            .controlSize(.small)
                            .tint(SyncTheme.accent)
                    }

                    Text("Restore Purchase")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(SyncTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(SyncTheme.blue.opacity(0.14), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(purchaseManager.isPurchasing || purchaseManager.isRestoring)
            .accessibilityLabel("Restore previous purchase")
        }
        .glassCard(cornerRadius: 24, padding: 20)
    }

    private var priceButtonLabel: String {
        if let product = purchaseManager.product {
            return "Unlock for \(product.displayPrice)"
        }
        return "Unlock Unlimited"
    }
}

private struct PaywallFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(SyncTheme.blue.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SyncTheme.accent)
            }

            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))

            Spacer()
        }
        .glassCard(cornerRadius: 18, padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

#Preview {
    PaywallView()
}
