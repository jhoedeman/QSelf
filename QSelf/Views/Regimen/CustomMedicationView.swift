import SwiftUI
import SwiftData

/// Free-tier carve-out: unlike other custom regimen items (Pro-only), custom
/// .medication items are available to everyone, capped at
/// RegimenLimits.maxFreeCustomMedications for free users. The caller
/// (CatalogView) is responsible for checking that cap before presenting this.
struct CustomMedicationView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var amountText = ""
    @State private var unit = "mg"
    @State private var timeOfDay: TimeOfDay = .morning
    @State private var scheduleType: ScheduleType = .daily
    @State private var scheduledWeekdays: Set<Int> = []
    @State private var notes = ""

    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && (scheduleType != .daysOfWeek || !scheduledWeekdays.isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    TextField("Name", text: $name)
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        TextField("mg", text: $unit)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    Picker("Time of day", selection: $timeOfDay) {
                        ForEach(TimeOfDay.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                }

                Section("Schedule") {
                    Picker("Frequency", selection: $scheduleType) {
                        Text("Daily").tag(ScheduleType.daily)
                        Text("Specific days").tag(ScheduleType.daysOfWeek)
                    }
                    .pickerStyle(.segmented)

                    if scheduleType == .daysOfWeek {
                        weekdayPicker
                    }
                }

                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Custom Medication")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(!isValid)
                }
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

    private func save() {
        let item = RegimenItem(name: name.trimmingCharacters(in: .whitespaces), category: .medication)
        item.scheduleType = scheduleType
        item.scheduledWeekdays = Array(scheduledWeekdays)
        item.notes = notes
        context.insert(item)

        let amount = Double(amountText) ?? 0
        let slot = DoseSlot(timeOfDay: timeOfDay, amount: amount, unit: unit.isEmpty ? "mg" : unit)
        slot.regimenItem = item
        item.doseSlots = [slot]
        context.insert(slot)

        try? context.save()
        dismiss()
    }
}
