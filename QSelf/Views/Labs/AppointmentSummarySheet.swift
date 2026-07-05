import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Pre-fetched data bundle

struct AppointmentSummaryData {
    let generatedDate: Date
    let activeRegimenItems: [RegimenItem]
    let recentLabResults: [LabResult]      // most recent per test name
    let outOfRangeTests: [LabResult]
    let metricAverages: [(metric: WellbeingMetric, average: Double)]  // last 4 weeks
}

// MARK: - PDF-transferable wrapper

struct ExportablePDF: Transferable {
    let data: Data
    let filename: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: UTType.pdf) { $0.data }
            .suggestedFileName { $0.filename }
    }
}

// MARK: - Sheet (preview + share)

struct AppointmentSummarySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var summaryData: AppointmentSummaryData? = nil
    @State private var pdf: ExportablePDF? = nil
    @State private var isRendering = false

    var body: some View {
        NavigationStack {
            Group {
                if let data = summaryData {
                    ScrollView {
                        SummaryDocument(data: data)
                            .environment(\.colorScheme, .light)
                            .padding()
                    }
                } else {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Appointment Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if let pdf {
                        ShareLink(item: pdf, preview: SharePreview("Appointment Summary", image: Image(systemName: "doc.text"))) {
                            Label("Export PDF", systemImage: "square.and.arrow.up")
                        }
                        .fontWeight(.semibold)
                    } else {
                        Button {
                            Task { await renderPDF() }
                        } label: {
                            if isRendering {
                                ProgressView()
                            } else {
                                Label("Export PDF", systemImage: "square.and.arrow.up")
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(summaryData == nil || isRendering)
                    }
                }
            }
            .task { await loadData() }
        }
    }

    // MARK: - Data loading

    @MainActor
    private func loadData() async {
        let activeItems = (try? DataService.activeRegimenItems(context: context)) ?? []
        let allLabs = (try? DataService.allLabResults(context: context)) ?? []

        // Keep only the most recent result per test name.
        var seen = Set<String>()
        var recent: [LabResult] = []
        for result in allLabs {
            if !seen.contains(result.testName) {
                seen.insert(result.testName)
                recent.append(result)
            }
        }
        let outOfRange = recent.filter { $0.isInRange == false }

        let fourWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: Date()) ?? Date()
        let recentLogs = (try? DataService.logs(in: fourWeeksAgo...Date(), context: context)) ?? []
        let visibleMetrics = MetricPreferences.load().visibleMetrics
        let averages: [(metric: WellbeingMetric, average: Double)] = visibleMetrics.compactMap { metric in
            let values = recentLogs.compactMap { $0.value(for: metric) }
            guard !values.isEmpty else { return nil }
            return (metric, values.reduce(0, +) / Double(values.count))
        }

        summaryData = AppointmentSummaryData(
            generatedDate: Date(),
            activeRegimenItems: activeItems,
            recentLabResults: recent,
            outOfRangeTests: outOfRange,
            metricAverages: averages
        )
    }

    @MainActor
    private func renderPDF() async {
        guard let data = summaryData else { return }
        isRendering = true
        defer { isRendering = false }

        let document = SummaryDocument(data: data)
            .environment(\.colorScheme, .light)
            .frame(width: 612)

        let renderer = ImageRenderer(content: document)
        renderer.scale = 2.0
        guard let image = renderer.uiImage else { return }

        let pageW: CGFloat = 612
        let pageH: CGFloat = 792
        let scale = min(pageW / image.size.width, pageH / image.size.height, 1.0)
        let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let format = UIGraphicsPDFRendererFormat()
        let bounds = CGRect(origin: .zero, size: CGSize(width: pageW, height: max(pageH, drawSize.height)))
        let pdfData = UIGraphicsPDFRenderer(bounds: bounds, format: format).pdfData { ctx in
            ctx.beginPage()
            image.draw(in: CGRect(origin: .zero, size: drawSize))
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        pdf = ExportablePDF(data: pdfData, filename: "QSelf-Summary-\(formatter.string(from: data.generatedDate)).pdf")
    }
}

// MARK: - Document layout (the renderable view)

struct SummaryDocument: View {
    let data: AppointmentSummaryData

    private let accentIndigo = Color(red: 0.51, green: 0.55, blue: 0.98)  // apexArc, hardcoded for the light-mode PDF

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            if !data.activeRegimenItems.isEmpty { regimenSection }
            if !data.recentLabResults.isEmpty { labsSection }
            if !data.metricAverages.isEmpty { trendsSection }
            if !data.outOfRangeTests.isEmpty { flagsSection }
            footer
        }
        .padding(24)
        .background(Color.white)
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("QSelf")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(accentIndigo)
                    Text("Appointment Summary")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Generated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(data.generatedDate.formatted(.dateTime.month(.wide).day().year()))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.bottom, 8)
            Divider()
        }
    }

    // MARK: Regimen

    private var regimenSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Current Regimen")
            VStack(spacing: 0) {
                regimenTableHeader
                ForEach(data.activeRegimenItems.sorted { $0.name < $1.name }, id: \.persistentModelID) { item in
                    regimenTableRow(item)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.25)))
        }
    }

    private var regimenTableHeader: some View {
        HStack(spacing: 4) {
            Text("Item").frame(minWidth: 100, maxWidth: .infinity, alignment: .leading)
            Text("Category").frame(width: 90, alignment: .trailing)
            Text("Schedule").frame(width: 120, alignment: .trailing)
            Text("Since").frame(width: 70, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.gray)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.gray.opacity(0.08))
    }

    private func regimenTableRow(_ item: RegimenItem) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Text(item.name)
                    .frame(minWidth: 100, maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color.black)
                Text(item.category.rawValue)
                    .frame(width: 90, alignment: .trailing)
                    .foregroundStyle(Color.gray)
                Text(scheduleSummary(item))
                    .frame(width: 120, alignment: .trailing)
                    .foregroundStyle(Color.gray)
                Text(item.startDate.formatted(.dateTime.month(.abbreviated).day().year()))
                    .frame(width: 70, alignment: .trailing)
                    .foregroundStyle(Color.gray)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .fixedSize(horizontal: false, vertical: true)
            .background(Color.white)
            Divider().padding(.horizontal, 10)
        }
    }

    private func scheduleSummary(_ item: RegimenItem) -> String {
        switch item.scheduleType {
        case .daily: return "Daily"
        case .daysOfWeek: return "\(item.scheduledWeekdays.count) day(s)/week"
        case .cyclic: return "\(item.cycleDaysOn) on / \(item.cycleDaysOff) off"
        }
    }

    // MARK: Labs

    private var labsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Recent Lab Results")
            VStack(spacing: 0) {
                labTableHeader
                ForEach(data.recentLabResults.sorted { $0.testName < $1.testName },
                        id: \.persistentModelID) { result in
                    labTableRow(result)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.25)))
        }
    }

    private var labTableHeader: some View {
        HStack(spacing: 4) {
            Text("Test")   .frame(minWidth: 80, maxWidth: .infinity, alignment: .leading)
            Text("Date")   .frame(width: 66, alignment: .trailing)
            Text("Result") .frame(width: 80, alignment: .trailing)
            Text("Range")  .frame(width: 88, alignment: .trailing)
            Text("Status") .frame(width: 44, alignment: .center)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.gray)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.gray.opacity(0.08))
    }

    private func labTableRow(_ result: LabResult) -> some View {
        let inRange = result.isInRange ?? true
        return VStack(spacing: 0) {
            HStack(spacing: 4) {
                Text(result.testName)
                    .frame(minWidth: 80, maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color.black)
                Text(result.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .frame(width: 66, alignment: .trailing)
                    .foregroundStyle(Color.gray)
                Text("\(result.value, specifier: "%g") \(result.unit)")
                    .frame(width: 80, alignment: .trailing)
                    .foregroundStyle(Color.black)
                Group {
                    if let lo = result.refRangeLow, let hi = result.refRangeHigh {
                        Text("\(lo, specifier: "%g")–\(hi, specifier: "%g")")
                    } else {
                        Text("—")
                    }
                }
                .frame(width: 88, alignment: .trailing)
                .foregroundStyle(Color.gray)
                Image(systemName: inRange ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(inRange ? Color.green : Color.red)
                    .frame(width: 44, alignment: .center)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .fixedSize(horizontal: false, vertical: true)
            .background(Color.white)
            Divider().padding(.horizontal, 10)
        }
    }

    // MARK: Trends

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("4-Week Wellbeing Averages")
            HStack(spacing: 0) {
                ForEach(Array(data.metricAverages.enumerated()), id: \.offset) { index, entry in
                    avgCell(entry.metric.displayName, entry.average)
                        .frame(maxWidth: .infinity)
                    if index != data.metricAverages.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(10)
            .background(Color.gray.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.25)))
        }
    }

    private func avgCell(_ label: String, _ value: Double) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(String(format: "%.1f", value)).font(.caption.weight(.semibold))
        }
    }

    // MARK: Flags

    private var flagsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle("Items to Discuss")
            ForEach(data.outOfRangeTests, id: \.persistentModelID) { result in
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(Color.red)
                        .font(.caption)
                    Text("\(result.testName): \(result.value, specifier: "%g") \(result.unit) — outside reference range")
                        .font(.caption)
                }
            }
        }
    }

    // MARK: Footer

    private var footer: some View {
        VStack {
            Divider()
            Text("Generated by QSelf · For informational purposes only · Not a substitute for medical advice")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 4)
    }

    // MARK: Helpers

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(accentIndigo)
    }
}

#Preview {
    AppointmentSummarySheet()
        .modelContainer(try! ModelContainer.makeContainer(cloudKit: false, isStoredInMemoryOnly: true))
}
