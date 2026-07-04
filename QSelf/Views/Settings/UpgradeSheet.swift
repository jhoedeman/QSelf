import SwiftUI

/// Feature-list upsell sheet with the live StoreKit 2 purchase/restore flow.
struct UpgradeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPro") private var isPro = false
    @StateObject private var purchaseService = PurchaseService()

    private let features = [
        ("infinity", "Unlimited regimen items", "No 15-item cap, full catalog access"),
        ("syringe.fill", "Peptides & injectables", "Plus nootropics, hormonal support, longevity compounds"),
        ("slider.horizontal.3", "Custom regimen items", "Any category, not just custom medications"),
        ("chart.line.uptrend.xyaxis", "1-year trend charts", "Free tier is capped at 12 weeks"),
        ("doc.richtext", "Appointment PDF export", "Share a clean summary with your provider"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.apexArc)
                        Text("QSelf Pro")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.apexTextPrimary)
                        Text("One-time purchase. No subscription.")
                            .font(.subheadline)
                            .foregroundStyle(Color.apexTextSecondary)
                    }
                    .padding(.top, 12)

                    CardSection(title: "What you get") {
                        VStack(spacing: 14) {
                            ForEach(features, id: \.1) { icon, title, subtitle in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: icon)
                                        .foregroundStyle(Color.apexPulse)
                                        .frame(width: 22)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(title)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Color.apexTextPrimary)
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundStyle(Color.apexTextTertiary)
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        Task { await purchaseService.purchase() }
                    } label: {
                        if purchaseService.isPurchasing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.apexArc.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Text(purchaseButtonTitle)
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.apexArc)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .disabled(purchaseService.isPurchasing)

                    Button("Restore purchases") {
                        Task { await purchaseService.restorePurchases() }
                    }
                    .foregroundStyle(Color.apexTextSecondary)
                }
                .padding()
            }
            .background(Color.apexCanvas)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await purchaseService.loadProduct() }
            .onChange(of: isPro) { _, unlocked in
                if unlocked { dismiss() }
            }
            .alert("Purchase failed", isPresented: Binding(
                get: { purchaseService.errorMessage != nil },
                set: { if !$0 { purchaseService.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(purchaseService.errorMessage ?? "")
            }
        }
    }

    private var purchaseButtonTitle: String {
        if let price = purchaseService.product?.displayPrice {
            return "Purchase — \(price)"
        }
        return "Purchase"
    }
}

#Preview {
    UpgradeSheet()
        .preferredColorScheme(.dark)
}
