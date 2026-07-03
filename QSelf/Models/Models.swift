import SwiftData
import Foundation

// MARK: - Enumerations

enum RegimenCategory: String, Codable, CaseIterable {
    case supplement    = "Supplement"
    case peptide       = "Peptide"
    case nootropic     = "Nootropic"
    case injectable    = "Injectable"
    case protein       = "Protein"
    case other         = "Other"
}

/// How a regimen item's active days are determined.
enum ScheduleType: String, Codable {
    case daily          // taken every day
    case daysOfWeek     // taken on specific weekdays only
    case cyclic         // N days on, M days off (short cycle, e.g. 5/2)
}

/// Named time-of-day slots. The UI groups dose slots under these headings.
enum TimeOfDay: String, Codable, CaseIterable {
    case morning     = "Morning"
    case preWorkout  = "Pre-workout"
    case postWorkout = "Post-workout"
    case afternoon   = "Afternoon"
    case evening     = "Evening"
    case beforeBed   = "Before bed"
    case custom      = "Custom"
}

/// Whether a compliance slot was honoured.
enum ComplianceStatus: String, Codable {
    case pending  // future slot, not yet actionable
    case taken    // confirmed taken
    case missed   // not taken (retroactively or by end of day)
    case skipped  // intentionally skipped (user choice, not a failure)
    case partial  // taken, but at a different dose (see actualAmountValue)
}

/// The fixed set of wellbeing metrics the user can log.
/// Visibility and display order are stored in UserDefaults as [String] (rawValues),
/// NOT in SwiftData — preferences are device-local and don't need history.
enum WellbeingMetric: String, Codable, CaseIterable, Identifiable {
    // Mental
    case mood, focus, motivation, anxiety, stress
    // Physical
    case energy, recovery, physicalPerformance, sleepQuality, sleepHours, jointPain, libido

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mood:               return "Mood"
        case .focus:              return "Focus"
        case .motivation:         return "Motivation"
        case .anxiety:            return "Anxiety"
        case .stress:             return "Stress"
        case .energy:             return "Energy"
        case .recovery:           return "Recovery"
        case .physicalPerformance: return "Performance"
        case .sleepQuality:       return "Sleep quality"
        case .sleepHours:         return "Sleep hours"
        case .jointPain:          return "Joint pain"
        case .libido:             return "Libido"
        }
    }

    var group: String {
        switch self {
        case .mood, .focus, .motivation, .anxiety, .stress: return "Mental"
        default: return "Physical"
        }
    }

    /// true = higher score is better (used for chart colour coding)
    var higherIsBetter: Bool {
        switch self {
        case .anxiety, .stress, .jointPain: return false
        default: return true
        }
    }

    /// Scale maximum (sleep hours uses 12, all others use 10)
    var scaleMax: Double { self == .sleepHours ? 12 : 10 }

    /// Default visibility — shown unless the user hides it.
    static var defaultVisible: [WellbeingMetric] {
        [.energy, .mood, .focus, .recovery, .sleepQuality, .sleepHours, .jointPain]
    }
}

// MARK: - DailyLog

/// One record per calendar day (normalised to midnight).
/// If the user opens the log tab for a day that already has a record, the form
/// pre-populates from the existing record (edit, not create).
@Model
final class DailyLog {

    var date: Date = Date()
    var note: String = ""

    // CloudKit requires to-many relationships to be optional, even with a default,
    // and to declare an explicit inverse.
    @Relationship(deleteRule: .cascade, inverse: \MetricValue.dailyLog)
    var metricValues: [MetricValue]? = []

    @Relationship(deleteRule: .nullify, inverse: \MoodTag.logs)
    var moodTags: [MoodTag]? = []

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
    }

    /// Convenience: fetch the stored value for a given metric key.
    func value(for metric: WellbeingMetric) -> Double? {
        metricValues?.first(where: { $0.metricKey == metric.rawValue })?.value
    }
}

// MARK: - MetricValue

/// One stored value per WellbeingMetric per DailyLog.
/// Kept as a child model (rather than individual columns on DailyLog)
/// so new metrics can be added without a schema migration.
@Model
final class MetricValue {

    var metricKey: String = ""  // WellbeingMetric.rawValue
    var value: Double = 0
    var dailyLog: DailyLog? = nil

    init(metric: WellbeingMetric, value: Double) {
        self.metricKey = metric.rawValue
        self.value = value
    }
}

// MARK: - MoodTag

/// Pre-seeded tag that can be applied to many DailyLog entries.
/// Seed once on first launch; do not let users create custom tags in v1.
@Model
final class MoodTag {

    var name: String = ""
    var logs: [DailyLog]? = []

    init(name: String) { self.name = name }
}

// MARK: - RegimenItem

/// Represents one supplement, peptide, injectable, etc. in the user's active protocol.
/// The source of truth for what the user *should* be taking and when.
/// Actual compliance is stored in ComplianceRecord.
@Model
final class RegimenItem {

    // Identity
    var name: String = ""
    var category: RegimenCategory = RegimenCategory.supplement

    /// References a CatalogItem.id from the static catalog.
    /// nil means this is a custom item (Pro only).
    var catalogId: String? = nil

    var isActive: Bool = true
    var startDate: Date = Date()
    var endDate: Date? = nil     // set when user removes item from regimen
    var notes: String = ""

    // MARK: Dose slots

    /// Each slot represents one dose event per active day (e.g. morning + evening = 2 slots).
    /// CloudKit requires to-many relationships to be optional, even with a default,
    /// and to declare an explicit inverse.
    @Relationship(deleteRule: .cascade, inverse: \DoseSlot.regimenItem)
    var doseSlots: [DoseSlot]? = []

    // MARK: Short-cycle schedule

    var scheduleType: ScheduleType = ScheduleType.daily

    /// For .daysOfWeek: weekday integers where 1 = Sunday, 7 = Saturday.
    var scheduledWeekdays: [Int] = []

    /// For .cyclic: consecutive days taken.
    var cycleDaysOn: Int = 5

    /// For .cyclic: consecutive days off after the on-period.
    var cycleDaysOff: Int = 2

    /// For .cyclic: the anchor date from which on/off counting begins.
    var cycleAnchorDate: Date = Date()

    // MARK: Long-cycle protocol (optional)
    // Used for items like peptides that run in multi-week cycles with rest periods.
    // The short-cycle schedule applies within an active long-cycle window.

    var hasLongCycle: Bool = false
    var longCycleActiveWeeks: Int = 8
    var longCycleRestWeeks: Int = 4
    var longCycleStartDate: Date = Date()

    // MARK: Injectable-specific

    var isInjectable: Bool = false
    var lastInjectionSite: String = ""  // persisted so the next-site hint works

    init(name: String, category: RegimenCategory, catalogId: String? = nil) {
        self.name = name
        self.category = category
        self.catalogId = catalogId
    }

    /// Returns true if this item should be taken on the given calendar day,
    /// considering the short-cycle schedule and the long-cycle protocol.
    func isScheduled(on date: Date) -> Bool {
        // Long-cycle check: is this date within an active long-cycle window?
        if hasLongCycle {
            let calendar = Calendar.current
            let totalDays = (longCycleActiveWeeks + longCycleRestWeeks) * 7
            let daysSinceStart = calendar.dateComponents([.day],
                from: calendar.startOfDay(for: longCycleStartDate),
                to: calendar.startOfDay(for: date)).day ?? 0
            guard daysSinceStart >= 0 else { return false }
            let positionInCycle = daysSinceStart % totalDays
            let activeDays = longCycleActiveWeeks * 7
            guard positionInCycle < activeDays else { return false }
        }

        // Short-cycle / weekly pattern check
        switch scheduleType {
        case .daily:
            return true
        case .daysOfWeek:
            let weekday = Calendar.current.component(.weekday, from: date)
            return scheduledWeekdays.contains(weekday)
        case .cyclic:
            let calendar = Calendar.current
            let daysSinceAnchor = calendar.dateComponents([.day],
                from: calendar.startOfDay(for: cycleAnchorDate),
                to: calendar.startOfDay(for: date)).day ?? 0
            guard daysSinceAnchor >= 0 else { return false }
            let positionInCycle = daysSinceAnchor % (cycleDaysOn + cycleDaysOff)
            return positionInCycle < cycleDaysOn
        }
    }
}

// MARK: - DoseSlot

/// One dose event within a day for a parent RegimenItem.
/// A single RegimenItem can have multiple DoseSlots (e.g. morning + evening).
@Model
final class DoseSlot {

    var timeOfDay: TimeOfDay = TimeOfDay.morning

    /// Only set when timeOfDay == .custom. Store as a Date; only the time component is used.
    var customTime: Date? = nil

    var amountValue: Double = 0
    var unit: String = "mg"         // mg, g, mcg, IU, mL, caps, scoops, etc.
    var instructions: String = ""   // "with food", "on empty stomach", etc.
    var sortOrder: Int = 0

    var regimenItem: RegimenItem? = nil
    var complianceRecords: [ComplianceRecord]? = []

    init(timeOfDay: TimeOfDay, amount: Double, unit: String) {
        self.timeOfDay = timeOfDay
        self.amountValue = amount
        self.unit = unit
    }
}

// MARK: - ComplianceRecord

/// One record per DoseSlot per calendar day.
///
/// Creation rules:
/// - Future slots: created with .pending when the regimen item is saved, up to 7 days ahead.
/// - Past slots: created retroactively (isRetroactive = true) as .missed on app launch,
///   for any day since the item's startDate where a record is absent.
/// - Users may edit any record's status and actualAmountValue at any time.
///   Once editedByUser = true, the retroactive fill job never overwrites it.
@Model
final class ComplianceRecord {

    var date: Date = Date()            // normalised to midnight
    var status: ComplianceStatus = ComplianceStatus.pending
    var actualAmountValue: Double? = nil  // non-nil when status == .partial
    var notes: String = ""
    var isRetroactive: Bool = false    // created by the fill job, not by the user
    var editedByUser: Bool = false     // fill job will never overwrite if true

    // Denormalised references (the relationship is owned by DoseSlot for easy querying)
    var scheduledAmountValue: Double = 0
    var scheduledUnit: String = ""

    @Relationship(deleteRule: .nullify, inverse: \DoseSlot.complianceRecords)
    var doseSlot: DoseSlot? = nil

    init(date: Date, doseSlot: DoseSlot, status: ComplianceStatus = .pending, retroactive: Bool = false) {
        self.date = Calendar.current.startOfDay(for: date)
        self.doseSlot = doseSlot
        self.scheduledAmountValue = doseSlot.amountValue
        self.scheduledUnit = doseSlot.unit
        self.status = status
        self.isRetroactive = retroactive
    }
}

// MARK: - LabResult

/// One record per individual lab value. Multiple results from the same draw
/// share the same date and are grouped by date in the UI.
@Model
final class LabResult {

    var date: Date = Date()
    var testName: String = ""
    var value: Double = 0
    var unit: String = ""
    var refRangeLow: Double? = nil
    var refRangeHigh: Double? = nil
    var isInRange: Bool? = nil    // computed and stored on save
    var labName: String = ""      // e.g. "Quest Diagnostics"
    var notes: String = ""

    init(date: Date, testName: String, value: Double, unit: String) {
        self.date = date
        self.testName = testName
        self.value = value
        self.unit = unit
    }
}

// MARK: - ModelContainer

extension ModelContainer {

    /// Pass cloudKit: false for SwiftUI previews and unit tests.
    static func makeContainer(cloudKit: Bool = true) throws -> ModelContainer {
        let schema = Schema([
            DailyLog.self,
            MetricValue.self,
            MoodTag.self,
            RegimenItem.self,
            DoseSlot.self,
            ComplianceRecord.self,
            LabResult.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: cloudKit ? .automatic : .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}

// MARK: - First-launch seed data

extension MoodTag {

    /// Call once on first launch after checking that MoodTag count == 0.
    /// Must be idempotent — safe to call on a device receiving a CloudKit sync of existing data.
    static let seedNames: [String] = [
        "Good", "Calm", "Motivated", "Focused", "Confident", "Optimistic",
        "Sharp", "Content", "Grateful",
        "Irritable", "Anxious", "Restless", "Overwhelmed", "Stressed",
        "Flat", "Tired", "Brain fog", "Low mood", "Burnt out",
        "Sore", "Inflamed", "Wired", "Crashed"
    ]
}

// MARK: - Metric display preferences (UserDefaults, not SwiftData)

/// Stored in UserDefaults as JSON because these are purely device-local display preferences.
/// Not synced via CloudKit — each device can have its own metric layout.
struct MetricPreferences: Codable {

    /// Ordered array of rawValues for visible metrics. Order = display order.
    var visibleMetricKeys: [String]

    init() {
        visibleMetricKeys = WellbeingMetric.defaultVisible.map(\.rawValue)
    }

    static let userDefaultsKey = "metricPreferences"

    static func load() -> MetricPreferences {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let prefs = try? JSONDecoder().decode(MetricPreferences.self, from: data)
        else { return MetricPreferences() }
        return prefs
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }

    var visibleMetrics: [WellbeingMetric] {
        visibleMetricKeys.compactMap { WellbeingMetric(rawValue: $0) }
    }

    var hiddenMetrics: [WellbeingMetric] {
        WellbeingMetric.allCases.filter { !visibleMetricKeys.contains($0.rawValue) }
    }
}
