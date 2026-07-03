import SwiftUI
import SwiftData

struct TodayComplianceView: View {
    @Environment(\.modelContext) private var context

    @State private var todaysRecords: [ComplianceRecord] = []
    @State private var notScheduledToday: [RegimenItem] = []
    @State private var editingRecord: ComplianceRecord? = nil
    @State private var injectionPrompt: InjectionPrompt? = nil
    @State private var isLoading = true

    private let complianceService = ComplianceService()
    private let calendar = Calendar.current

    private struct InjectionPrompt: Identifiable {
        let id = UUID()
        let record: ComplianceRecord
        let item: RegimenItem
    }

    private var groupedByTimeOfDay: [(TimeOfDay, [ComplianceRecord])] {
        TimeOfDay.allCases.compactMap { timeOfDay in
            let records = todaysRecords.filter { $0.doseSlot?.timeOfDay == timeOfDay }
            return records.isEmpty ? nil : (timeOfDay, records)
        }
    }

    private var takenCount: Int {
        todaysRecords.filter { $0.status == .taken || $0.status == .partial }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                if !isLoading && todaysRecords.isEmpty && notScheduledToday.isEmpty {
                    emptyState
                }

                ForEach(groupedByTimeOfDay, id: \.0) { timeOfDay, records in
                    CardSection(title: timeOfDay.rawValue) {
                        VStack(spacing: 4) {
                            ForEach(records) { record in
                                recordRow(record)
                                if record.id != records.last?.id {
                                    Divider().overlay(Color.apexBorder)
                                }
                            }
                        }
                    }
                }

                if !notScheduledToday.isEmpty {
                    CardSection(title: "Not today") {
                        VStack(spacing: 4) {
                            ForEach(notScheduledToday) { item in
                                notScheduledRow(item)
                                if item.id != notScheduledToday.last?.id {
                                    Divider().overlay(Color.apexBorder)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.apexCanvas)
        // .onAppear, not .task: this view's identity persists across
        // Regimen-tab hide/show (TabView keeps tabs alive), so .task would
        // only ever fire once and go stale — e.g. across a day boundary,
        // or after edits made elsewhere in the same session.
        .onAppear { Task { await load() } }
        .sheet(item: $editingRecord) { record in
            ComplianceRecordEditView(record: record)
        }
        .sheet(item: $injectionPrompt) { prompt in
            InjectionSiteSheet(item: prompt.item) { site in
                markTaken(prompt.record, site: site)
            }
        }
    }

    private var header: some View {
        HStack {
            Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.apexTextPrimary)
            Spacer()
            if !todaysRecords.isEmpty {
                Text("\(takenCount) of \(todaysRecords.count) taken")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.apexPulse)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "pills")
                .font(.system(size: 40))
                .foregroundStyle(Color.apexTextTertiary)
            Text("No regimen items yet")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.apexTextSecondary)
            Text("Tap + to add supplements, peptides, or medications.")
                .font(.caption)
                .foregroundStyle(Color.apexTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Rows

    @ViewBuilder
    private func recordRow(_ record: ComplianceRecord) -> some View {
        if let slot = record.doseSlot, let item = slot.regimenItem {
            HStack(spacing: 12) {
                Image(systemName: categoryIcon(item.category))
                    .foregroundStyle(Color.apexTextSecondary)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.apexTextPrimary)
                    Text(doseLabel(record: record, slot: slot))
                        .font(.caption)
                        .foregroundStyle(Color.apexTextTertiary)
                }
                Spacer()
                Button {
                    handleTap(record: record, item: item, slot: slot)
                } label: {
                    Image(systemName: statusIcon(record.status))
                        .font(.title2)
                        .foregroundStyle(statusColor(record.status))
                }
                .buttonStyle(.plain)
                .contextMenu {
                    if record.status == .taken || record.status == .partial {
                        Button("Edit…") { editingRecord = record }
                        Button("Mark as skipped", role: .destructive) {
                            updateStatus(record, to: .skipped)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func notScheduledRow(_ item: RegimenItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: categoryIcon(item.category))
                .foregroundStyle(Color.apexTextTertiary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .foregroundStyle(Color.apexTextSecondary)
                if let nextDate = nextScheduledDate(for: item) {
                    Text("Next: \(nextDate.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.caption)
                        .foregroundStyle(Color.apexTextTertiary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(0.6)
    }

    // MARK: - Actions

    private func handleTap(record: ComplianceRecord, item: RegimenItem, slot: DoseSlot) {
        switch record.status {
        case .pending, .missed, .skipped:
            if item.isInjectable {
                injectionPrompt = InjectionPrompt(record: record, item: item)
            } else {
                markTaken(record)
            }
        case .taken, .partial:
            break // long-press / context menu only, per spec — never one-tap back off "taken"
        }
    }

    private func markTaken(_ record: ComplianceRecord, site: String? = nil) {
        record.status = .taken
        record.editedByUser = true
        if let site, let item = record.doseSlot?.regimenItem {
            item.lastInjectionSite = site
        }
        try? context.save()
    }

    private func updateStatus(_ record: ComplianceRecord, to status: ComplianceStatus) {
        record.status = status
        record.editedByUser = true
        try? context.save()
    }

    // MARK: - Data

    private func load() async {
        await complianceService.runFillJob(context: context)

        let today = calendar.startOfDay(for: Date())
        let records = await complianceService.todaysRecords(context: context)
        todaysRecords = records.sorted { lhs, rhs in
            (lhs.doseSlot?.regimenItem?.name ?? "") < (rhs.doseSlot?.regimenItem?.name ?? "")
        }

        let scheduledItemIDs = Set(records.compactMap { $0.doseSlot?.regimenItem?.persistentModelID })
        let activeItems = (try? DataService.activeRegimenItems(context: context)) ?? []
        notScheduledToday = activeItems.filter {
            !scheduledItemIDs.contains($0.persistentModelID) && !$0.isScheduled(on: today)
        }

        isLoading = false
    }

    private func nextScheduledDate(for item: RegimenItem, withinDays: Int = 60) -> Date? {
        let today = calendar.startOfDay(for: Date())
        for offset in 1...withinDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            if item.isScheduled(on: date) { return date }
        }
        return nil
    }

    private func doseLabel(record: ComplianceRecord, slot: DoseSlot) -> String {
        if record.status == .partial, let actual = record.actualAmountValue {
            return "\(formattedAmount(actual)) \(record.scheduledUnit) (planned \(formattedAmount(record.scheduledAmountValue)))"
        }
        return "\(formattedAmount(slot.amountValue)) \(slot.unit)"
    }

    private func formattedAmount(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(value)
    }

    private func statusIcon(_ status: ComplianceStatus) -> String {
        switch status {
        case .pending: return "circle"
        case .taken: return "checkmark.circle.fill"
        case .partial: return "checkmark.circle.trianglebadge.exclamationmark"
        case .missed: return "xmark.circle"
        case .skipped: return "minus.circle"
        }
    }

    private func statusColor(_ status: ComplianceStatus) -> Color {
        switch status {
        case .pending: return .apexTextTertiary
        case .taken: return .apexStatusGood
        case .partial: return .apexStatusModerate
        case .missed: return .apexStatusPoor
        case .skipped: return .apexTextTertiary
        }
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
