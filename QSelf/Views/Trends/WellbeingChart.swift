import SwiftUI
import Charts

/// Chart-only color coding, distinct from Apex's semantic status tokens:
/// Mental metrics get a violet/purple family, Physical metrics get a
/// green/teal family, per CLAUDE.md's Trends spec. Individual hues within
/// each family exist only to keep simultaneously-plotted lines distinguishable.
extension WellbeingMetric {
    var chartColor: Color {
        switch self {
        case .mood:                return Color(hex: 0xA78BFA)
        case .focus:                return Color(hex: 0x818CF8)
        case .motivation:           return Color(hex: 0xC084FC)
        case .anxiety:              return Color(hex: 0x8B5CF6)
        case .stress:               return Color(hex: 0x6D28D9)
        case .energy:               return Color(hex: 0x34D399)
        case .recovery:             return Color(hex: 0x10B981)
        case .physicalPerformance:  return Color(hex: 0x14B8A6)
        case .sleepQuality:         return Color(hex: 0x2DD4BF)
        case .sleepHours:           return Color(hex: 0x0D9488)
        case .jointPain:            return Color(hex: 0x5EEAD4)
        case .libido:               return Color(hex: 0x06B6D4)
        }
    }
}

struct WellbeingChart: View {
    let logs: [DailyLog]
    let metrics: [WellbeingMetric]
    let regimenEvents: [RegimenEvent]
    let dateRange: ClosedRange<Date>

    @ChartContentBuilder
    private var eventMarks: some ChartContent {
        ForEach(regimenEvents) { event in
            RuleMark(x: .value("Event", event.date))
                .foregroundStyle(Color.apexTextTertiary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .annotation(position: .top, alignment: .leading) {
                    Text("\(event.itemName) \(eventVerb(event.kind))")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.apexTextTertiary)
                }
        }
    }

    @ChartContentBuilder
    private func metricLines(for metric: WellbeingMetric) -> some ChartContent {
        ForEach(logs) { log in
            if let value = log.value(for: metric) {
                LineMark(
                    x: .value("Date", log.date),
                    y: .value(metric.displayName, value)
                )
                .foregroundStyle(metric.chartColor)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .symbol {
                    if logs.count < 30 {
                        Circle().fill(metric.chartColor).frame(width: 5)
                    }
                }
            }
        }
    }

    var body: some View {
        Chart {
            eventMarks
            ForEach(metrics) { metric in
                metricLines(for: metric)
            }
        }
        .chartXScale(domain: dateRange)
        .chartYScale(domain: 0...12)
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                AxisGridLine().foregroundStyle(Color.apexBorder)
                AxisTick().foregroundStyle(Color.apexBorder)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(Color.apexTextTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 6, 12]) { _ in
                AxisGridLine().foregroundStyle(Color.apexBorder)
                AxisValueLabel().foregroundStyle(Color.apexTextTertiary)
            }
        }
    }

    private func eventVerb(_ kind: RegimenEvent.Kind) -> String {
        switch kind {
        case .started: return "started"
        case .stopped: return "stopped"
        case .cycleTransition: return "cycle"
        }
    }
}
