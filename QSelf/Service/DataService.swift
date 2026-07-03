import Foundation
import SwiftData

/// Thin SwiftData query layer so views stay free of fetch logic.
enum DataService {

    static func todaysLog(context: ModelContext) throws -> DailyLog? {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.date == today }
        )
        return try context.fetch(descriptor).first
    }

    static func logs(in range: ClosedRange<Date>, context: ModelContext) throws -> [DailyLog] {
        let lowerBound = range.lowerBound
        let upperBound = range.upperBound
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.date >= lowerBound && $0.date <= upperBound },
            sortBy: [SortDescriptor(\.date)]
        )
        return try context.fetch(descriptor)
    }

    static func labResults(for testName: String, context: ModelContext) throws -> [LabResult] {
        let descriptor = FetchDescriptor<LabResult>(
            predicate: #Predicate { $0.testName == testName },
            sortBy: [SortDescriptor(\.date)]
        )
        return try context.fetch(descriptor)
    }

    static func activeRegimenItems(context: ModelContext) throws -> [RegimenItem] {
        let descriptor = FetchDescriptor<RegimenItem>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    /// Start, stop, and long-cycle transition events synthesised from every
    /// `RegimenItem` (active or archived) that overlaps the given range, for
    /// the Trends swimlane's regimen markers.
    static func regimenEvents(in range: ClosedRange<Date>, context: ModelContext) throws -> [RegimenEvent] {
        let items = try context.fetch(FetchDescriptor<RegimenItem>())
        var events: [RegimenEvent] = []

        for item in items {
            if range.contains(item.startDate) {
                events.append(RegimenEvent(date: item.startDate, itemName: item.name, category: item.category, kind: .started))
            }
            if let endDate = item.endDate, range.contains(endDate) {
                events.append(RegimenEvent(date: endDate, itemName: item.name, category: item.category, kind: .stopped))
            }
            if item.hasLongCycle {
                events.append(contentsOf: cycleTransitionEvents(for: item, in: range))
            }
        }

        return events.sorted { $0.date < $1.date }
    }

    /// Walks long-cycle active/rest boundary dates forward from
    /// `longCycleStartDate`, collecting any that fall within `range`.
    private static func cycleTransitionEvents(for item: RegimenItem, in range: ClosedRange<Date>) -> [RegimenEvent] {
        let calendar = Calendar.current
        let activeDays = item.longCycleActiveWeeks * 7
        let totalDays = activeDays + item.longCycleRestWeeks * 7
        guard totalDays > 0 else { return [] }

        let cycleStart = calendar.startOfDay(for: item.longCycleStartDate)
        guard cycleStart <= range.upperBound else { return [] }

        var events: [RegimenEvent] = []
        var cycleStartDate = cycleStart

        while cycleStartDate <= range.upperBound {
            if range.contains(cycleStartDate) {
                events.append(RegimenEvent(date: cycleStartDate, itemName: item.name, category: item.category, kind: .cycleTransition))
            }
            if let restStartDate = calendar.date(byAdding: .day, value: activeDays, to: cycleStartDate),
               range.contains(restStartDate) {
                events.append(RegimenEvent(date: restStartDate, itemName: item.name, category: item.category, kind: .cycleTransition))
            }
            guard let nextCycleStart = calendar.date(byAdding: .day, value: totalDays, to: cycleStartDate) else { break }
            cycleStartDate = nextCycleStart
        }

        return events
    }
}
