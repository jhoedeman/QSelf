import SwiftUI

/// Feature-list upsell sheet. StoreKit 2 purchase/restore isn't built yet
/// (separate build-order item), so the action buttons here are honest
/// placeholders rather than faking an unlock.
struct UpgradeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showComingSoon = false

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
                        showComingSoon = true
                    } label: {
                        Text("Purchase — Coming soon")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.apexArc)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button("Restore purchases") {
                        showComingSoon = true
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
            .alert("Coming soon", isPresented: $showComingSoon) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("In-app purchases aren't live yet — this is a preview of the upgrade flow.")
            }
        }
    }
}

#Preview {
    UpgradeSheet()
        .preferredColorScheme(.dark)
}
