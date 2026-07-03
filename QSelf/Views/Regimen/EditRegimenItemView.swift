import SwiftUI
import SwiftData

/// Editor reached from the Manage tab. Covers notes, dose slot time-of-day
/// and amounts, and daily/specific-days scheduling. Long-cycle protocol
/// editing is out of scope here — catalog defaults rarely need changing
/// post-add, and a full cycle editor is a lot of UI for an edge case;
/// revisit if it comes up.
struct EditRegimenItemView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: RegimenItem

    @State private var scheduledWeekdays: Set<Int>
    @State private var showArchiveConfirm = false

    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    init(item: RegimenItem) {
        self.item = item
        _scheduledWeekdays = State(initialValue: Set(item.scheduledWeekdays))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    LabeledContent("Name", value: item.name)
                    LabeledContent("Category", value: item.category.rawValue)
                    TextField("Notes", text: $item.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if item.scheduleType != .cyclic {
                    Section("Schedule") {
                        Picker("Frequency", selection: $item.scheduleType) {
                            Text("Daily").tag(ScheduleType.daily)
                            Text("Specific days").tag(ScheduleType.daysOfWeek)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: item.scheduleType) { _, _ in
                            item.scheduledWeekdays = Array(scheduledWeekdays)
                        }

                        if item.scheduleType == .daysOfWeek {
                            weekdayPicker
                        }
                    }
                } else {
                    Section("Schedule") {
                        LabeledContent("Cycle", value: "\(item.cycleDaysOn) days on / \(item.cycleDaysOff) days off")
                        Text("Cyclic schedules aren't editable yet — archive and re-add to change the pattern.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Dose slots") {
                    ForEach(item.doseSlots ?? []) { slot in
                        doseSlotRow(slot)
                    }
                }

                Section {
                    Button("Archive", role: .destructive) { showArchiveConfirm = true }
                }
            }
            .navigationTitle(item.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { save() }
                }
            }
            .confirmationDialog(
                "Archive \(item.name)?",
                isPresented: $showArchiveConfirm,
                titleVisibility: .visible
            ) {
                Button("Archive", role: .destructive) { archive() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This stops today's and future compliance tracking. Past history is kept.")
            }
        }
    }

    private var weekdayPicker: some View {
        HStack {
            ForEach(1...7, id: \.self) { weekday in
                let isSelected = scheduledWeekdays.contains(weekday)
                Button {
                    if isSelected { scheduledWeekdays.remove(weekday) }
                    else { scheduledWeekdays.insert(weekday) }
                    item.scheduledWeekdays = Array(scheduledWeekdays)
                } label: {
                    Text(weekdaySymbols[weekday - 1])
                        .font(.caption.weight(.semibold))
                        .frame(width: 30, height: 30)
                        .background(isSelected ? Color.apexArc : Color.apexCanvas)
                        .foregroundStyle(isSelected ? .white : Color.apexTextSecondary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func doseSlotRow(_ slot: DoseSlot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Picker("Time of day", selection: timeOfDayBinding(for: slot)) {
                ForEach(TimeOfDay.allCases, id: \.self) { timeOfDay in
                    Text(timeOfDay.rawValue).tag(timeOfDay)
                }
            }
            HStack {
                Text("Amount")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("Amount", value: amountBinding(for: slot), format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                TextField("Unit", text: unitBinding(for: slot))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
            }
        }
        .padding(.vertical, 2)
    }

    private func timeOfDayBinding(for slot: DoseSlot) -> Binding<TimeOfDay> {
        Binding(get: { slot.timeOfDay }, set: { slot.timeOfDay = $0 })
    }

    private func amountBinding(for slot: DoseSlot) -> Binding<Double> {
        Binding(get: { slot.amountValue }, set: { slot.amountValue = $0 })
    }

    private func unitBinding(for slot: DoseSlot) -> Binding<String> {
        Binding(get: { slot.unit }, set: { slot.unit = $0 })
    }

    private func save() {
        try? context.save()
        dismiss()
    }

    private func archive() {
        item.isActive = false
        item.endDate = Date()
        try? context.save()
        dismiss()
    }
}
