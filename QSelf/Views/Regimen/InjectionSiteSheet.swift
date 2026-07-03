import SwiftUI

/// Site picker shown when marking an injectable item's dose as taken,
/// per the brief's "Add injection sheet" spec.
struct InjectionSiteSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: RegimenItem
    let onConfirm: (String) -> Void

    private let sites = ["Left thigh", "Right thigh", "Left glute", "Right glute", "Abdomen", "Other"]
    @State private var selectedSite: String

    init(item: RegimenItem, onConfirm: @escaping (String) -> Void) {
        self.item = item
        self.onConfirm = onConfirm
        _selectedSite = State(initialValue: item.lastInjectionSite.isEmpty ? "" : item.lastInjectionSite)
    }

    var body: some View {
        NavigationStack {
            List(sites, id: \.self) { site in
                Button {
                    selectedSite = site
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(site).foregroundStyle(Color.apexTextPrimary)
                            if site == item.lastInjectionSite {
                                Text("Last used").font(.caption).foregroundStyle(Color.apexTextTertiary)
                            }
                        }
                        Spacer()
                        if site == selectedSite {
                            Image(systemName: "checkmark").foregroundStyle(Color.apexArc)
                        }
                    }
                }
            }
            .navigationTitle("Injection Site")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        onConfirm(selectedSite)
                        dismiss()
                    }
                    .disabled(selectedSite.isEmpty)
                }
            }
        }
    }
}
