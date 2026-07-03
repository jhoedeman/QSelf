import SwiftUI
import SwiftData

/// Combined "adjust dose / add note" sheet for a taken or partial
/// ComplianceRecord, reached via long-press context menu on the Today view.
struct ComplianceRecordEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var record: ComplianceRecord

    @State private var isPartial: Bool
    @State private var amountText: String
    @State private var notes: String

    init(record: ComplianceRecord) {
        self.record = record
        _isPartial = State(initialValue: record.status == .partial)
        _amountText = State(initialValue: record.actualAmountValue.map { String($0) } ?? String(record.scheduledAmountValue))
        _notes = State(initialValue: record.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Dose") {
                    Toggle("Different from planned", isOn: $isPartial)
                    if isPartial {
                        HStack {
                            Text("Actual amount")
                            Spacer()
                            TextField("Amount", text: $amountText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                            Text(record.scheduledUnit)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            Text("Planned amount")
                            Spacer()
                            Text("\(formattedAmount(record.scheduledAmountValue)) \(record.scheduledUnit)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Note") {
                    TextField("Optional note", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Dose")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        record.notes = notes
        record.editedByUser = true
        if isPartial {
            record.status = .partial
            record.actualAmountValue = Double(amountText) ?? record.scheduledAmountValue
        } else {
            record.status = .taken
            record.actualAmountValue = nil
        }
        try? context.save()
        dismiss()
    }

    private func formattedAmount(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(value)
    }
}
