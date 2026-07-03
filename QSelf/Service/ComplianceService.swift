import Foundation
import SwiftData

/// Keeps `ComplianceRecord` rows in sync with what `RegimenItem.isScheduled(on:)`
/// says should have happened. Runs off the main actor so the fill job never
/// blocks the UI.
actor ComplianceService {

    private static let lastFillDateKey = "complianceService.lastFillDate"
    private static let backfillWindowDays = 30
    private static let lookaheadDays = 7

    private let calendar = Calendar.current
    private let defaults: UserDefaults

    /// `defaults` defaults to `.standard` in production. Tests should inject an
    /// isolated instance (e.g. `UserDefaults(suiteName: UUID().uuidString)!`) so
    /// the "already ran today" guard doesn't leak state across test invocations
    /// sharing the same process.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Backfills missed `ComplianceRecord`s for active `RegimenItem`s over the
    /// past 30 days and pre-creates the next 7 days as `.pending`. Safe to call
    /// unconditionally on every foreground activation. Never overwrites a
    /// record the user has edited.
    ///
    /// The (expensive-ish) 30-day backfill only runs once per calendar day —
    /// tracked via `lastFillDateKey` — but upcoming-pending creation always
    /// runs on every call. It's cheap (a handful of days per item) and
    /// `hasRecord` makes it idempotent, and skipping it after the first call
    /// of the day would mean a regimen item added later that same day never
    /// gets a record for today until the next day's fill job runs.
    func runFillJob(context: ModelContext) async {
        let today = calendar.startOfDay(for: Date())

        let alreadyRanToday: Bool
        if let lastRun = defaults.object(forKey: Self.lastFillDateKey) as? Date {
            alreadyRanToday = calendar.isDate(lastRun, inSameDayAs: today)
        } else {
            alreadyRanToday = false
        }

        let descriptor = FetchDescriptor<RegimenItem>(
            predicate: #Predicate { $0.isActive == true }
        )
        guard let items = try? context.fetch(descriptor) else { return }

        for item in items {
            if !alreadyRanToday {
                backfillMissedRecords(for: item, today: today, context: context)
            }
            createUpcomingPendingRecords(for: item, today: today, context: context)
        }

        try? context.save()
        defaults.set(today, forKey: Self.lastFillDateKey)
    }

    /// Fraction of scheduled dose slots marked `.taken` or `.partial` for this
    /// item within the given date range.
    func complianceRate(for item: RegimenItem, in range: ClosedRange<Date>, context: ModelContext) async -> Double {
        let slotIDs = Set((item.doseSlots ?? []).map(\.persistentModelID))
        guard !slotIDs.isEmpty else { return 0 }

        let lowerBound = range.lowerBound
        let upperBound = range.upperBound
        let descriptor = FetchDescriptor<ComplianceRecord>(
            predicate: #Predicate { $0.date >= lowerBound && $0.date <= upperBound }
        )
        guard let records = try? context.fetch(descriptor) else { return 0 }

        let relevant = records.filter { record in
            guard let slot = record.doseSlot else { return false }
            return slotIDs.contains(slot.persistentModelID)
        }
        guard !relevant.isEmpty else { return 0 }

        let takenCount = relevant.filter { $0.status == .taken || $0.status == .partial }.count
        return Double(takenCount) / Double(relevant.count)
    }

    /// All `ComplianceRecord`s dated today, for the Regimen tab's compliance view.
    func todaysRecords(context: ModelContext) async -> [ComplianceRecord] {
        let today = calendar.startOfDay(for: Date())
        let descriptor = FetchDescriptor<ComplianceRecord>(
            predicate: #Predicate { $0.date == today }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Fill job internals

    private func backfillMissedRecords(for item: RegimenItem, today: Date, context: ModelContext) {
        let earliestFillDate = calendar.date(byAdding: .day, value: -Self.backfillWindowDays, to: today) ?? today
        let startDate = max(calendar.startOfDay(for: item.startDate), earliestFillDate)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today), startDate <= yesterday else { return }

        var date = startDate
        while date <= yesterday {
            defer { date = calendar.date(byAdding: .day, value: 1, to: date) ?? calendar.date(byAdding: .day, value: 1, to: yesterday)! }

            guard item.isScheduled(on: date) else { continue }

            for slot in item.doseSlots ?? [] {
                guard !hasRecord(for: slot, on: date) else { continue }
                let record = ComplianceRecord(date: date, doseSlot: slot, status: .missed, retroactive: true)
                context.insert(record)
            }
        }
    }

    private func createUpcomingPendingRecords(for item: RegimenItem, today: Date, context: ModelContext) {
        for offset in 0..<Self.lookaheadDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today),
                  item.isScheduled(on: date) else { continue }

            for slot in item.doseSlots ?? [] {
                guard !hasRecord(for: slot, on: date) else { continue }
                let record = ComplianceRecord(date: date, doseSlot: slot, status: .pending)
                context.insert(record)
            }
        }
    }

    /// A record already exists for this slot/date that either isn't ours to
    /// overwrite (user-edited) or simply doesn't need to be recreated.
    private func hasRecord(for slot: DoseSlot, on date: Date) -> Bool {
        (slot.complianceRecords ?? []).contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
}
