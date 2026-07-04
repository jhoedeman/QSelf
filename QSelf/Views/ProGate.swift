import SwiftUI

/// Wraps a view in an upgrade-prompt overlay when the user isn't Pro.
/// Existing gates (CatalogView, TrendsView's 1yr window/correlation hint)
/// predate this and use inline isPro checks — this is for new Pro-gated
/// UI going forward, per CLAUDE.md's architecture notes.
struct ProGateModifier: ViewModifier {
    @AppStorage("isPro") private var isPro = false
    @State private var showUpgradeSheet = false
    let feature: String

    func body(content: Content) -> some View {
        if isPro {
            content
        } else {
            content
                .overlay {
                    Button {
                        showUpgradeSheet = true
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.title3)
                                .foregroundStyle(Color.apexArc)
                            Text(feature)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.apexTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.apexCanvas.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                }
                .sheet(isPresented: $showUpgradeSheet) {
                    UpgradeSheet()
                }
        }
    }
}

extension View {
    func proGate(_ feature: String) -> some View {
        modifier(ProGateModifier(feature: feature))
    }
}
