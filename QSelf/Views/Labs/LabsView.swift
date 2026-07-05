import SwiftUI
import SwiftData

struct LabsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false

    @State private var results: [LabResult] = []
    @State private var showAddDraw = false
    @State private var showAppointmentSummary = false
    @State private var showUpgradeSheet = false

    private var groupedByDate: [(Date, [LabResult])] {
        let grouped = Dictionary(grouping: results, by: \.date)
        return grouped.keys.sorted(by: >).map { date in
            (date, grouped[date]!.sorted { $0.testName < $1.testName })
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if results.isEmpty {
                        emptyState
                    } else {
                        ForEach(groupedByDate, id: \.0) { date, drawResults in
                            CardSection(title: date.formatted(.dateTime.month(.abbreviated).day().year())) {
                                VStack(spacing: 4) {
                                    ForEach(drawResults) { result in
                                        resultRow(result)
                                        if result.id != drawResults.last?.id {
                                            Divider().overlay(Color.apexBorder)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.apexCanvas)
            .navigationTitle("Labs")
            .toolbarBackground(Color.apexCanvas, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if isPro {
                            showAppointmentSummary = true
                        } else {
                            showUpgradeSheet = true
                        }
                    } label: {
                        Image(systemName: isPro ? "square.and.arrow.up" : "lock.fill")
                    }
                    .disabled(results.isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddDraw = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear(perform: load)
            .sheet(isPresented: $showAddDraw, onDismiss: load) {
                AddLabDrawView()
            }
            .sheet(isPresented: $showAppointmentSummary) {
                AppointmentSummarySheet()
            }
            .sheet(isPresented: $showUpgradeSheet) {
                UpgradeSheet()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "testtube.2")
                .font(.system(size: 40))
                .foregroundStyle(Color.apexTextTertiary)
            Text("No lab results yet")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.apexTextSecondary)
            Text("Tap + to add a draw with one or more test results.")
                .font(.caption)
                .foregroundStyle(Color.apexTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func resultRow(_ result: LabResult) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(rangeColor(result))
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(result.testName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.apexTextPrimary)
                if let low = result.refRangeLow, let high = result.refRangeHigh {
                    Text("Ref: \(formattedValue(low))–\(formattedValue(high)) \(result.unit)")
                        .font(.caption)
                        .foregroundStyle(Color.apexTextTertiary)
                }
            }
            Spacer()
            Text("\(formattedValue(result.value)) \(result.unit)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.apexTextPrimary)
        }
        .padding(.vertical, 4)
    }

    private func rangeColor(_ result: LabResult) -> Color {
        guard let inRange = result.isInRange else { return .apexTextTertiary }
        return inRange ? .apexStatusGood : .apexStatusPoor
    }

    private func formattedValue(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(value)
    }

    private func load() {
        results = (try? DataService.allLabResults(context: context)) ?? []
    }
}

#Preview {
    LabsView()
        .modelContainer(try! ModelContainer.makeContainer(cloudKit: false, isStoredInMemoryOnly: true))
        .preferredColorScheme(.dark)
}
