import SwiftUI
import SwiftData

/// Manual-entry sheet for one draw (a set of tests sharing a date and lab
/// name). PDF import is intentionally out of scope for v1 — see CLAUDE.md.
struct AddLabDrawView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var labName = ""
    @State private var rows: [TestRow] = [TestRow()]

    private struct TestRow: Identifiable {
        let id = UUID()
        var testName = ""
        var value = ""
        var unit = ""
        var refLow = ""
        var refHigh = ""
    }

    private var canSave: Bool {
        rows.contains { !$0.testName.trimmingCharacters(in: .whitespaces).isEmpty && Double($0.value) != nil }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Draw") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Lab name (optional)", text: $labName)
                }

                Section("Tests") {
                    ForEach($rows) { $row in
                        testRow($row)
                    }
                    .onDelete { rows.remove(atOffsets: $0) }

                    Button {
                        rows.append(TestRow())
                    } label: {
                        Label("Add test", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Add Draw")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func testRow(_ row: Binding<TestRow>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Test name", text: row.testName)
                Spacer()
                Circle()
                    .fill(dotColor(row.wrappedValue))
                    .frame(width: 8, height: 8)
            }
            HStack {
                TextField("Value", text: row.value)
                    .keyboardType(.decimalPad)
                TextField("Unit", text: row.unit)
                    .frame(width: 70)
            }
            HStack {
                TextField("Ref low", text: row.refLow)
                    .keyboardType(.decimalPad)
                Text("–")
                    .foregroundStyle(.secondary)
                TextField("Ref high", text: row.refHigh)
                    .keyboardType(.decimalPad)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }

    private func dotColor(_ row: TestRow) -> Color {
        guard let value = Double(row.value), let low = Double(row.refLow), let high = Double(row.refHigh) else {
            return .apexTextTertiary
        }
        return (value >= low && value <= high) ? .apexStatusGood : .apexStatusPoor
    }

    private func save() {
        for row in rows {
            let name = row.testName.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty, let value = Double(row.value) else { continue }

            let result = LabResult(date: date, testName: name, value: value, unit: row.unit)
            result.labName = labName
            if let low = Double(row.refLow), let high = Double(row.refHigh) {
                result.refRangeLow = low
                result.refRangeHigh = high
                result.isInRange = value >= low && value <= high
            }
            context.insert(result)
        }
        try? context.save()
        dismiss()
    }
}

#Preview {
    AddLabDrawView()
        .modelContainer(try! ModelContainer.makeContainer(cloudKit: false, isStoredInMemoryOnly: true))
        .preferredColorScheme(.dark)
}
