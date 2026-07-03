import SwiftUI
import SwiftData

struct CatalogView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPro") private var isPro = false

    @State private var addedCatalogIDs: Set<String> = []
    @State private var catalogItemCount = 0
    @State private var customMedicationCount = 0
    @State private var showCustomMedication = false
    @State private var showUpgradePrompt = false
    @State private var upgradeMessage = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        tapCustomMedication()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "cross.case.fill")
                                .foregroundStyle(Color.apexArc)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Add custom medication")
                                    .foregroundStyle(Color.apexTextPrimary)
                                Text(isPro ? "Unlimited" : "\(customMedicationCount) of \(RegimenLimits.maxFreeCustomMedications) used")
                                    .font(.caption)
                                    .foregroundStyle(Color.apexTextTertiary)
                            }
                            Spacer()
                        }
                    }
                }

                Section {
                    if !isPro {
                        Text("\(catalogItemCount) of \(RegimenLimits.maxFreeCatalogItems) catalog slots used")
                            .font(.caption)
                            .foregroundStyle(Color.apexTextTertiary)
                    }
                    ForEach(RegimenCatalog.allItems) { catalogItem in
                        catalogRow(catalogItem)
                    }
                } header: {
                    Text("Catalog")
                }
            }
            .navigationTitle("Add to Regimen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showCustomMedication) {
                CustomMedicationView()
                    .onDisappear { Task { await loadCounts() } }
            }
            .alert("Upgrade to Pro", isPresented: $showUpgradePrompt) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(upgradeMessage)
            }
            .task { await loadCounts() }
        }
    }

    private func catalogRow(_ catalogItem: CatalogItem) -> some View {
        let isLocked = catalogItem.tier == .pro && !isPro
        let isAdded = addedCatalogIDs.contains(catalogItem.id)

        return Button {
            tapCatalogItem(catalogItem)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: categoryIcon(catalogItem.category))
                    .foregroundStyle(isAdded ? Color.apexPulse : Color.apexTextSecondary)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(catalogItem.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.apexTextPrimary)
                    Text(catalogItem.description)
                        .font(.caption)
                        .foregroundStyle(Color.apexTextTertiary)
                }
                Spacer()
                if isAdded {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.apexPulse)
                } else if isLocked {
                    Image(systemName: "lock.fill").foregroundStyle(Color.apexTextTertiary)
                } else {
                    Image(systemName: "plus.circle").foregroundStyle(Color.apexArc)
                }
            }
        }
        .disabled(isAdded)
    }

    // MARK: - Actions

    private func tapCatalogItem(_ catalogItem: CatalogItem) {
        if catalogItem.tier == .pro && !isPro {
            upgradeMessage = "\(catalogItem.name) is part of the full Pro catalog — peptides, nootropics, injectables, and more."
            showUpgradePrompt = true
            return
        }
        if !isPro && catalogItemCount >= RegimenLimits.maxFreeCatalogItems {
            upgradeMessage = "You've used all \(RegimenLimits.maxFreeCatalogItems) free catalog slots. Upgrade to Pro for unlimited items."
            showUpgradePrompt = true
            return
        }

        let item = catalogItem.makeRegimenItem()
        context.insert(item)
        for slot in item.doseSlots ?? [] {
            context.insert(slot)
        }
        try? context.save()

        addedCatalogIDs.insert(catalogItem.id)
        catalogItemCount += 1
    }

    private func tapCustomMedication() {
        if !isPro && customMedicationCount >= RegimenLimits.maxFreeCustomMedications {
            upgradeMessage = "You've used all \(RegimenLimits.maxFreeCustomMedications) free custom medication slots. Upgrade to Pro for unlimited custom items."
            showUpgradePrompt = true
            return
        }
        showCustomMedication = true
    }

    private func loadCounts() async {
        addedCatalogIDs = (try? DataService.activeCatalogIDs(context: context)) ?? []
        catalogItemCount = (try? DataService.activeCatalogItemCount(context: context)) ?? 0
        customMedicationCount = (try? DataService.activeCustomMedicationCount(context: context)) ?? 0
    }

    private func categoryIcon(_ category: RegimenCategory) -> String {
        switch category {
        case .supplement: return "pills.fill"
        case .protein: return "scalemass.fill"
        case .peptide, .injectable: return "syringe.fill"
        case .nootropic: return "brain.head.profile"
        case .medication: return "cross.case.fill"
        case .other: return "circle.fill"
        }
    }
}
