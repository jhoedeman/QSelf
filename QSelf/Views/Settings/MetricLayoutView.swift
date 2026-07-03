import SwiftUI

/// Standalone metric reorder/hide screen, reached from Settings.
/// Functionally the same editing model as the Log tab's inline Edit mode
/// (move/hide/show against MetricPreferences), duplicated rather than shared
/// because the Log tab toggles between sliders and edit-rows in place, while
/// this screen is always in the "editing" state — sharing state cleanly
/// between the two would mean restructuring LogView's already-verified
/// Edit mode for a two-call-site win that isn't worth the regression risk.
struct MetricLayoutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var prefs = MetricPreferences.load()

    private var mentalOrder: [WellbeingMetric] { prefs.visibleMetrics.filter { $0.group == "Mental" } }
    private var physicalOrder: [WellbeingMetric] { prefs.visibleMetrics.filter { $0.group == "Physical" } }
    private var hiddenMetrics: [WellbeingMetric] { prefs.hiddenMetrics }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    metricsCard(title: "Mental", metrics: mentalOrder)
                    metricsCard(title: "Physical", metrics: physicalOrder)
                    if !hiddenMetrics.isEmpty {
                        hiddenMetricsCard
                    }
                }
                .padding()
            }
            .background(Color.apexCanvas)
            .navigationTitle("Metric Layout")
            .toolbarBackground(Color.apexCanvas, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        prefs.save()
                        dismiss()
                    }
                }
            }
        }
    }

    private func metricsCard(title: String, metrics: [WellbeingMetric]) -> some View {
        CardSection(title: title) {
            if metrics.isEmpty {
                Text("No visible metrics in this group.")
                    .font(.caption)
                    .foregroundStyle(Color.apexTextTertiary)
            }
            ForEach(metrics) { metric in
                MetricRow(
                    metric: metric,
                    value: .constant(0),
                    isEditing: true,
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
                    value: .constant(0),
                    isEditing: true,
                    onToggleVisibility: { show(metric) },
                    isHidden: true
                )
            }
        }
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

    private func applyOrder(_ newOrder: [WellbeingMetric], group: String) {
        let other = prefs.visibleMetrics.filter { $0.group != group }
        let combined = group == "Mental" ? newOrder + other : other + newOrder
        prefs.visibleMetricKeys = combined.map(\.rawValue)
    }
}

#Preview {
    MetricLayoutView()
        .preferredColorScheme(.dark)
}
