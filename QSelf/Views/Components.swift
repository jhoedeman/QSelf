import SwiftUI

// MARK: - CardSection
// Reused across Log, Regimen, Labs, Settings — matches the VitalCurve pattern.

struct CardSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.apexTextPrimary)
            content()
        }
        .padding(16)
        .background(Color.apexCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - SliderRow

struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var tint: (Double) -> Color = { _ in .apexPulse }
    var valueFormat: (Double) -> String = { String(format: "%.0f", $0) }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Color.apexTextSecondary)
                Spacer()
                Text(valueFormat(value))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(tint(value))
            }
            Slider(value: $value, in: range, step: step)
                .tint(tint(value))
        }
    }
}

/// Higher-is-better metrics: green at the top, red at the bottom.
func higherIsBetterTint(_ value: Double, scaleMax: Double) -> Color {
    let fraction = scaleMax > 0 ? value / scaleMax : 0
    switch fraction {
    case 0.7...: return .apexStatusGood
    case 0.35..<0.7: return .apexStatusModerate
    default: return .apexStatusPoor
    }
}

/// Lower-is-better metrics (anxiety, stress, joint pain): red at the top, green at the bottom.
func lowerIsBetterTint(_ value: Double, scaleMax: Double) -> Color {
    let fraction = scaleMax > 0 ? value / scaleMax : 0
    switch fraction {
    case ..<0.3: return .apexStatusGood
    case 0.3..<0.65: return .apexStatusModerate
    default: return .apexStatusPoor
    }
}

// MARK: - MetricRow
// Displays a slider in normal mode; shows reorder/hide controls in edit mode.

struct MetricRow: View {
    let metric: WellbeingMetric
    @Binding var value: Double
    var isEditing: Bool
    var canMoveUp: Bool = false
    var canMoveDown: Bool = false
    var onMoveUp: () -> Void = {}
    var onMoveDown: () -> Void = {}
    var onToggleVisibility: () -> Void = {}
    var isHidden: Bool = false

    private var tint: (Double) -> Color {
        metric.higherIsBetter
            ? { higherIsBetterTint($0, scaleMax: metric.scaleMax) }
            : { lowerIsBetterTint($0, scaleMax: metric.scaleMax) }
    }

    private var valueFormat: (Double) -> String {
        metric == .sleepHours ? { String(format: "%.1f h", $0) } : { String(format: "%.0f", $0) }
    }

    var body: some View {
        if isEditing {
            HStack {
                Text(metric.displayName)
                    .font(.subheadline)
                    .foregroundStyle(isHidden ? Color.apexTextTertiary : Color.apexTextPrimary)
                Spacer()
                if !isHidden {
                    Button(action: onMoveUp) { Image(systemName: "chevron.up") }
                        .disabled(!canMoveUp)
                    Button(action: onMoveDown) { Image(systemName: "chevron.down") }
                        .disabled(!canMoveDown)
                }
                Button(action: onToggleVisibility) {
                    Image(systemName: isHidden ? "eye" : "eye.slash")
                }
                .tint(isHidden ? .apexArc : .apexTextSecondary)
            }
            .buttonStyle(.plain)
            .font(.subheadline)
        } else {
            SliderRow(
                label: metric.displayName,
                value: $value,
                range: 0...metric.scaleMax,
                step: metric == .sleepHours ? 0.5 : 1,
                tint: tint,
                valueFormat: valueFormat
            )
        }
    }
}

// MARK: - FlowLayout
// Wraps mood tag pills onto multiple lines.

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var y: CGFloat = 0; var x: CGFloat = 0; var rowH: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            x += size.width + spacing; rowH = max(rowH, size.height)
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowH: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing; rowH = max(rowH, size.height)
        }
    }
}
