import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var context

    // Form state
    @State private var values: [WellbeingMetric: Double] = [:]
    @State private var selectedTags: Set<String> = []
    @State private var allTags: [MoodTag] = []
    @State private var note: String = ""

    @State private var existingLog: DailyLog? = nil
    @State private var saveError: String? = nil

    // Layout editing (order + visibility), backed by MetricPreferences in UserDefaults
    @State private var prefs = MetricPreferences.load()
    @State private var isEditingLayout = false

    private var mentalOrder: [WellbeingMetric] { prefs.visibleMetrics.filter { $0.group == "Mental" } }
    private var physicalOrder: [WellbeingMetric] { prefs.visibleMetrics.filter { $0.group == "Physical" } }
    private var hiddenMetrics: [WellbeingMetric] { prefs.hiddenMetrics }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    metricsCard(title: "Mental", metrics: mentalOrder)
                    metricsCard(title: "Physical", metrics: physicalOrder)
                    if isEditingLayout && !hiddenMetrics.isEmpty {
                        hiddenMetricsCard
                    }
                    moodTagsCard
                    noteCard
                }
                .padding()
            }
            .background(Color.apexCanvas)
            .navigationTitle(todayTitle)
            .toolbarBackground(Color.apexCanvas, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditingLayout ? "Done" : "Edit") {
                        if isEditingLayout { prefs.save() }
                        withAnimation { isEditingLayout.toggle() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(isEditingLayout)
                }
            }
            .alert("Save failed", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "")
            }
        }
        .onAppear { Task { await load() } }
    }

    // MARK: - Cards

    private func metricsCard(title: String, metrics: [WellbeingMetric]) -> some View {
        CardSection(title: title) {
            ForEach(metrics) { metric in
                MetricRow(
                    metric: metric,
                    value: binding(for: metric),
                    isEditing: isEditingLayout,
                    canMoveUp: metrics.first != metric,
                    canMoveDown: metrics.last != metric,
                    onMoveUp: { move(metric, up: true, within: metrics) },
                    onMoveDown: { move(metric, up: false, within: metrics) },
                    onToggleVisibility: { hide(metric) }
                )
            }
        }
    }

    private var hiddenMetricsCard: some View {
        CardSection(title: "Hidden") {
            ForEach(hiddenMetrics) { metric in
                MetricRow(
                    metric: metric,
                    value: binding(for: metric),
                    isEditing: true,
                    onToggleVisibility: { show(metric) },
                    isHidden: true
                )
            }
        }
    }

    private var moodTagsCard: some View {
        CardSection(title: "How are you feeling?") {
            FlowLayout(spacing: 8) {
                ForEach(allTags) { tag in
                    let selected = selectedTags.contains(tag.name)
                    let tint = tagColor(for: tag.sentiment)
                    Button {
                        if selected { selectedTags.remove(tag.name) }
                        else { selectedTags.insert(tag.name) }
                    } label: {
                        Text(tag.name)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selected ? tint.opacity(0.15) : Color.clear)
                            .foregroundStyle(selected ? tint : Color.apexTextSecondary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(selected ? tint : Color.apexBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var noteCard: some View {
        CardSection(title: "Note") {
            TextField("Optional note for today…", text: $note, axis: .vertical)
                .lineLimit(4...8)
                .font(.body)
                .foregroundStyle(Color.apexTextPrimary)
        }
    }

    private func tagColor(for sentiment: MoodTagSentiment) -> Color {
        switch sentiment {
        case .positive: return .apexStatusGood
        case .neutral: return .apexArc
        case .negative: return .apexStatusPoor
        }
    }

    // MARK: - Layout editing

    private func binding(for metric: WellbeingMetric) -> Binding<Double> {
        Binding(
            get: { values[metric] ?? defaultValue(for: metric) },
            set: { values[metric] = $0 }
        )
    }

    private func move(_ metric: WellbeingMetric, up: Bool, within group: [WellbeingMetric]) {
        guard let index = group.firstIndex(of: metric) else { return }
        let targetIndex = up ? index - 1 : index + 1
        guard group.indices.contains(targetIndex) else { return }

        var reordered = group
        reordered.swapAt(index, targetIndex)
        applyOrder(reordered, group: metric.group)
    }

    private func hide(_ metric: WellbeingMetric) {
        var visible = prefs.visibleMetricKeys.compactMap(WellbeingMetric.init(rawValue:))
        visible.removeAll { $0 == metric }
        prefs.visibleMetricKeys = visible.map(\.rawValue)
    }

    private func show(_ metric: WellbeingMetric) {
        var visible = prefs.visibleMetricKeys.compactMap(WellbeingMetric.init(rawValue:))
        visible.append(metric)
        prefs.visibleMetricKeys = visible.map(\.rawValue)
    }

    /// Replaces one group's ordering (Mental or Physical) within the flat
    /// `visibleMetricKeys` array while leaving the other group untouched.
    private func applyOrder(_ newOrder: [WellbeingMetric], group: String) {
        let other = prefs.visibleMetrics.filter { $0.group != group }
        let combined = group == "Mental" ? newOrder + other : other + newOrder
        prefs.visibleMetricKeys = combined.map(\.rawValue)
    }

    // MARK: - Data

    private var todayTitle: String {
        Date().formatted(.dateTime.weekday(.wide).month().day())
    }

    private func defaultValue(for metric: WellbeingMetric) -> Double {
        switch metric {
        case .sleepHours: return 7
        case .jointPain, .anxiety, .stress: return metric.scaleMin
        default: return (metric.scaleMin + metric.scaleMax) / 2
        }
    }

    /// Reloads everything that can go stale while this view stays alive in
    /// the background tab: MetricPreferences (edited from Settings) and
    /// today's log (a day boundary crossed while the app stayed open would
    /// otherwise leave `existingLog` pointing at yesterday's DailyLog, so
    /// Save would silently overwrite yesterday's entry instead of creating
    /// today's).
    @MainActor
    private func load() async {
        prefs = MetricPreferences.load()

        do {
            allTags = try DataService.allMoodTags(context: context)
            if let log = try DataService.todaysLog(context: context) {
                existingLog = log
                note = log.note
                selectedTags = Set((log.moodTags ?? []).map(\.name))
                values = [:]
                for metric in WellbeingMetric.allCases {
                    if let value = log.value(for: metric) {
                        values[metric] = value
                    }
                }
            } else {
                existingLog = nil
                note = ""
                selectedTags = []
                values = [:]
            }
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func save() {
        do {
            let log = existingLog ?? {
                let l = DailyLog(date: Date())
                context.insert(l)
                return l
            }()

            log.note = note

            var metricValues = log.metricValues ?? []
            for (metric, value) in values {
                if let existing = metricValues.first(where: { $0.metricKey == metric.rawValue }) {
                    existing.value = value
                } else {
                    let newValue = MetricValue(metric: metric, value: value)
                    newValue.dailyLog = log
                    context.insert(newValue)
                    metricValues.append(newValue)
                }
            }
            log.metricValues = metricValues

            log.moodTags = allTags.filter { selectedTags.contains($0.name) }

            try context.save()
            existingLog = log
        } catch {
            saveError = error.localizedDescription
        }
    }
}

#Preview {
    let container = try! ModelContainer.makeContainer(cloudKit: false, isStoredInMemoryOnly: true)
    let context = ModelContext(container)
    for name in MoodTag.seedNames { context.insert(MoodTag(name: name)) }
    try? context.save()

    return LogView()
        .modelContainer(container)
}
