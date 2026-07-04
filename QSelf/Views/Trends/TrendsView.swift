import SwiftUI
import SwiftData

struct TrendsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false

    @State private var dailyLogs: [DailyLog] = []
    @State private var labResults: [LabResult] = []
    @State private var regimenEvents: [RegimenEvent] = []

    @State private var windowWeeks = 12
    @State private var visibleMetrics: Set<WellbeingMetric> = Set(WellbeingMetric.defaultVisible)
    @State private var visibleTests: Set<String> = []
    @State private var showUpgradeSheet = false

    private let windowOptions: [(label: String, weeks: Int, isProOnly: Bool)] = [
        ("4 wks", 4, false), ("12 wks", 12, false), ("6 mo", 26, false), ("1 yr", 52, true),
    ]

    private var dateRange: ClosedRange<Date> {
        let end = Date()
        let start = Calendar.current.date(byAdding: .weekOfYear, value: -windowWeeks, to: end) ?? end
        return start...end
    }

    private var logsInWindow: [DailyLog] {
        dailyLogs.filter { dateRange.contains($0.date) }
    }

    private var resultsInWindow: [LabResult] {
        labResults.filter { dateRange.contains($0.date) }
    }

    private var availableTests: [String] {
        Array(Set(labResults.map(\.testName))).sorted()
    }

    private var testsInWindow: Set<String> {
        Set(resultsInWindow.map(\.testName))
    }

    private var hasData: Bool {
        !dailyLogs.isEmpty || !labResults.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if hasData {
                    ScrollView {
                        VStack(spacing: 20) {
                            windowPicker

                            CardSection(title: "Wellbeing") {
                                VStack(alignment: .leading, spacing: 10) {
                                    metricToggleRow
                                    WellbeingChart(
                                        logs: logsInWindow,
                                        metrics: Array(visibleMetrics),
                                        regimenEvents: regimenEvents,
                                        dateRange: dateRange
                                    )
                                    .frame(height: 180)
                                }
                            }

                            CardSection(title: "Lab results") {
                                VStack(alignment: .leading, spacing: 10) {
                                    if !availableTests.isEmpty {
                                        testToggleRow
                                    }
                                    LabsChart(
                                        results: resultsInWindow.filter { visibleTests.contains($0.testName) },
                                        regimenEvents: regimenEvents,
                                        dateRange: dateRange
                                    )
                                    .frame(height: 140)
                                }
                            }

                            correlationHint
                        }
                        .padding()
                    }
                } else {
                    emptyState
                }
            }
            .background(Color.apexCanvas)
            .navigationTitle("Trends")
            .toolbarBackground(Color.apexCanvas, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear(perform: load)
            .onChange(of: availableTests, initial: true) { _, tests in
                visibleTests.formUnion(Set(tests).subtracting(visibleTests))
            }
            .onChange(of: windowWeeks) { _, _ in
                regimenEvents = (try? DataService.regimenEvents(in: dateRange, context: context)) ?? []
            }
            .sheet(isPresented: $showUpgradeSheet) {
                UpgradeSheet()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(Color.apexTextTertiary)
            Text("No data yet")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.apexTextSecondary)
            Text("Log a few days and add lab results to see trends here.")
                .font(.caption)
                .foregroundStyle(Color.apexTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    private var windowPicker: some View {
        HStack(spacing: 8) {
            ForEach(windowOptions, id: \.weeks) { option in
                let locked = option.isProOnly && !isPro
                let selected = windowWeeks == option.weeks
                Button {
                    if locked { showUpgradeSheet = true } else { windowWeeks = option.weeks }
                } label: {
                    HStack(spacing: 4) {
                        if locked {
                            Image(systemName: "lock.fill").font(.system(size: 9))
                        }
                        Text(option.label)
                    }
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selected ? Color.apexArc.opacity(0.15) : Color.clear)
                    .foregroundStyle(selected ? Color.apexArc : (locked ? Color.apexTextTertiary : Color.apexTextSecondary))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(selected ? Color.apexArc : Color.apexBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var metricToggleRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WellbeingMetric.allCases) { metric in
                    let on = visibleMetrics.contains(metric)
                    Button {
                        if on { visibleMetrics.remove(metric) } else { visibleMetrics.insert(metric) }
                    } label: {
                        Text(metric.displayName)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(on ? metric.chartColor.opacity(0.15) : Color.clear)
                            .foregroundStyle(on ? metric.chartColor : Color.apexTextTertiary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(on ? metric.chartColor : Color.apexBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var testToggleRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableTests, id: \.self) { test in
                    let on = visibleTests.contains(test)
                    let hasData = testsInWindow.contains(test)
                    Button {
                        if on { visibleTests.remove(test) } else { visibleTests.insert(test) }
                    } label: {
                        Text(test)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(on && hasData ? Color.apexArc.opacity(0.15) : Color.clear)
                            .foregroundStyle(on && hasData ? Color.apexArc : Color.apexTextTertiary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(on && hasData ? Color.apexArc : Color.apexBorder, lineWidth: 1))
                            .opacity(hasData ? 1 : 0.4)
                    }
                    .buttonStyle(.plain)
                    .disabled(!hasData)
                }
            }
        }
    }

    // MARK: - Correlation hint (Pro)

    private var correlationHint: some View {
        CardSection(title: "Correlation") {
            if isPro {
                if let hint = correlationHintText {
                    Text(hint)
                        .font(.subheadline)
                        .foregroundStyle(Color.apexTextSecondary)
                } else {
                    Text("Add a regimen change and a few days of logs to see a correlation here.")
                        .font(.caption)
                        .foregroundStyle(Color.apexTextTertiary)
                }
            } else {
                Button {
                    showUpgradeSheet = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles").foregroundStyle(Color.apexArc)
                        Text("Unlock correlation insights with Pro")
                            .font(.subheadline)
                            .foregroundStyle(Color.apexTextPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.apexTextTertiary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Compares the 4-week average of the first visible metric before and
    /// after the most recent regimen event in the window. Descriptive only.
    private var correlationHintText: String? {
        guard let metric = visibleMetrics.first,
              let event = regimenEvents.filter({ $0.date <= Date() }).max(by: { $0.date < $1.date }) else {
            return nil
        }

        let calendar = Calendar.current
        guard let fourWeeksBefore = calendar.date(byAdding: .weekOfYear, value: -4, to: event.date),
              let fourWeeksAfter = calendar.date(byAdding: .weekOfYear, value: 4, to: event.date) else {
            return nil
        }

        let before = dailyLogs.filter { $0.date >= fourWeeksBefore && $0.date < event.date }.compactMap { $0.value(for: metric) }
        let after = dailyLogs.filter { $0.date > event.date && $0.date <= fourWeeksAfter }.compactMap { $0.value(for: metric) }

        guard !before.isEmpty, !after.isEmpty else { return nil }

        let beforeAvg = before.reduce(0, +) / Double(before.count)
        let afterAvg = after.reduce(0, +) / Double(after.count)

        return "Average \(metric.displayName.lowercased()) was \(String(format: "%.1f", beforeAvg)) in the 4 weeks before \(event.itemName) \(eventVerb(event.kind)) and \(String(format: "%.1f", afterAvg)) in the 4 weeks after."
    }

    private func eventVerb(_ kind: RegimenEvent.Kind) -> String {
        switch kind {
        case .started: return "started"
        case .stopped: return "stopped"
        case .cycleTransition: return "cycled"
        }
    }

    // MARK: - Data

    private func load() {
        // Date.distantPast breaks SwiftData's #Predicate comparison (silently
        // returns zero results) — use a far-but-ordinary lower bound instead.
        let allTime = Calendar.current.date(byAdding: .year, value: -20, to: Date())!...Date()
        dailyLogs = (try? DataService.logs(in: allTime, context: context)) ?? []
        labResults = (try? DataService.allLabResults(context: context)) ?? []
        regimenEvents = (try? DataService.regimenEvents(in: dateRange, context: context)) ?? []
    }
}

#Preview {
    TrendsView()
        .modelContainer(try! ModelContainer.makeContainer(cloudKit: false, isStoredInMemoryOnly: true))
        .preferredColorScheme(.dark)
}
