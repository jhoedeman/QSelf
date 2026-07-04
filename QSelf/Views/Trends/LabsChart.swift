import SwiftUI
import Charts

extension LabResult {
    /// Percentage of the reference range (0 = at low end, 100 = at high end).
    /// Values outside the range produce <0 or >100, which plots visibly
    /// outside the green band rather than clamping.
    var normalizedValue: Double? {
        guard let low = refRangeLow, let high = refRangeHigh, high > low else { return nil }
        return ((value - low) / (high - low)) * 100
    }
}

struct LabsChart: View {
    let results: [LabResult]
    let regimenEvents: [RegimenEvent]
    let dateRange: ClosedRange<Date>

    @State private var selectedResult: LabResult? = nil

    private var byTest: [String: [LabResult]] {
        Dictionary(grouping: results, by: \.testName)
    }

    @ChartContentBuilder
    private var referenceBand: some ChartContent {
        RectangleMark(
            xStart: .value("Start", dateRange.lowerBound),
            xEnd: .value("End", dateRange.upperBound),
            yStart: .value("Low", 0.0),
            yEnd: .value("High", 100.0)
        )
        .foregroundStyle(Color.apexStatusGood.opacity(0.08))
    }

    // Unlabeled here (unlike the wellbeing lane) to avoid clashing with the
    // per-point value annotations already on this chart.
    @ChartContentBuilder
    private var eventMarks: some ChartContent {
        ForEach(regimenEvents) { event in
            RuleMark(x: .value("Event", event.date))
                .foregroundStyle(Color.apexTextTertiary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
    }

    @ChartContentBuilder
    private func seriesMarks(testName: String, series: [LabResult]) -> some ChartContent {
        ForEach(series) { result in
            if let norm = result.normalizedValue {
                LineMark(
                    x: .value("Date", result.date),
                    y: .value("% of range", norm)
                )
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .foregroundStyle(by: .value("Test", testName))
                .interpolationMethod(.linear)

                PointMark(
                    x: .value("Date", result.date),
                    y: .value("% of range", norm)
                )
                .foregroundStyle(by: .value("Test", testName))
                .symbolSize(60)
            }
        }
    }

    var body: some View {
        Chart {
            referenceBand
            eventMarks
            ForEach(Array(byTest.keys.sorted()), id: \.self) { testName in
                let series = byTest[testName]!.sorted { $0.date < $1.date }
                seriesMarks(testName: testName, series: series)
            }
        }
        .chartXScale(domain: dateRange)
        // Y-axis overshoots 0-100 so out-of-range points remain visible.
        .chartYScale(domain: -20...120)
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                AxisGridLine().foregroundStyle(Color.apexBorder)
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 50, 100]) { value in
                AxisGridLine().foregroundStyle(Color.apexBorder)
                AxisValueLabel(value.index == 0 ? "low" : value.index == 1 ? "mid" : "high")
                    .foregroundStyle(Color.apexTextTertiary)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        guard let date: Date = proxy.value(atX: location.x - geo.frame(in: .local).minX) else { return }
                        selectedResult = results.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
                    }
            }
        }
        .popover(item: $selectedResult) { result in
            LabResultPopover(result: result)
        }
    }
}

struct LabResultPopover: View {
    let result: LabResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(result.testName)
                .font(.headline)
                .foregroundStyle(Color.apexTextPrimary)
            Text("\(formattedValue(result.value)) \(result.unit)")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.apexTextPrimary)
            if let low = result.refRangeLow, let high = result.refRangeHigh {
                Text("Range \(formattedValue(low))–\(formattedValue(high)) \(result.unit)")
                    .font(.caption)
                    .foregroundStyle(Color.apexTextTertiary)
            }
            if let inRange = result.isInRange {
                Label(inRange ? "In range" : "Out of range", systemImage: inRange ? "checkmark.circle" : "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(inRange ? Color.apexStatusGood : Color.apexStatusPoor)
            }
            Text(result.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(Color.apexTextTertiary)
        }
        .padding()
        .presentationCompactAdaptation(.popover)
    }

    private func formattedValue(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(value)
    }
}
