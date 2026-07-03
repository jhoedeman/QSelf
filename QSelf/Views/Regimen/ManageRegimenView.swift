import SwiftUI
import SwiftData

struct ManageRegimenView: View {
    @Environment(\.modelContext) private var context

    @State private var activeItems: [RegimenItem] = []
    @State private var archivedItems: [RegimenItem] = []
    @State private var editingItem: RegimenItem? = nil

    var body: some View {
        List {
            Section("Active") {
                if activeItems.isEmpty {
                    Text("No active regimen items.")
                        .font(.subheadline)
                        .foregroundStyle(Color.apexTextTertiary)
                        .listRowBackground(Color.apexCanvas)
                } else {
                    ForEach(activeItems) { item in
                        Button { editingItem = item } label: {
                            itemRow(item)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.apexCard)
                        .swipeActions {
                            Button("Archive") { archive(item) }
                                .tint(Color.apexTextTertiary)
                        }
                    }
                }
            }

            if !archivedItems.isEmpty {
                Section("History") {
                    ForEach(archivedItems) { item in
                        itemRow(item)
                            .opacity(0.5)
                            .listRowBackground(Color.apexCard)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.apexCanvas)
        // .onAppear, not .task — see TodayComplianceView for why.
        .onAppear { Task { await load() } }
        .sheet(item: $editingItem, onDismiss: { Task { await load() } }) { item in
            EditRegimenItemView(item: item)
        }
    }

    private func itemRow(_ item: RegimenItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: categoryIcon(item.category))
                .foregroundStyle(Color.apexTextSecondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.apexTextPrimary)
                Text(scheduleSummary(item))
                    .font(.caption)
                    .foregroundStyle(Color.apexTextTertiary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.apexTextTertiary)
        }
        .padding(.vertical, 2)
    }

    private func scheduleSummary(_ item: RegimenItem) -> String {
        switch item.scheduleType {
        case .daily: return "Daily"
        case .daysOfWeek: return "\(item.scheduledWeekdays.count) day(s)/week"
        case .cyclic: return "\(item.cycleDaysOn) on / \(item.cycleDaysOff) off"
        }
    }

    private func archive(_ item: RegimenItem) {
        item.isActive = false
        item.endDate = Date()
        try? context.save()
        Task { await load() }
    }

    private func load() async {
        activeItems = (try? DataService.activeRegimenItems(context: context)) ?? []
        archivedItems = (try? DataService.archivedRegimenItems(context: context)) ?? []
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
