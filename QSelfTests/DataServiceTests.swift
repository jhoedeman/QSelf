import Testing
import Foundation
import SwiftData
@testable import QSelf

struct DataServiceTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer.makeContainer(cloudKit: false, isStoredInMemoryOnly: true)
        return ModelContext(container)
    }

    @Test func todaysLogReturnsNilWhenNoneExists() throws {
        let context = try makeContext()
        #expect(try DataService.todaysLog(context: context) == nil)
    }

    @Test func todaysLogFindsExistingEntryForToday() throws {
        let context = try makeContext()
        let log = DailyLog(date: Date())
        context.insert(log)
        try context.save()

        let found = try DataService.todaysLog(context: context)
        #expect(found?.persistentModelID == log.persistentModelID)
    }

    @Test func logsInRangeFiltersAndSortsByDate() throws {
        let context = try makeContext()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let inRange1 = DailyLog(date: calendar.date(byAdding: .day, value: -1, to: today)!)
        let inRange2 = DailyLog(date: today)
        let outOfRange = DailyLog(date: calendar.date(byAdding: .day, value: -30, to: today)!)
        [inRange1, inRange2, outOfRange].forEach(context.insert)
        try context.save()

        let range = calendar.date(byAdding: .day, value: -5, to: today)!...today
        let results = try DataService.logs(in: range, context: context)

        #expect(results.count == 2)
        #expect(results.first?.persistentModelID == inRange1.persistentModelID)
    }

    @Test func activeRegimenItemsExcludesArchivedItems() throws {
        let context = try makeContext()
        let active = RegimenItem(name: "Vitamin D3", category: .supplement)
        let archived = RegimenItem(name: "Old Item", category: .supplement)
        archived.isActive = false
        [active, archived].forEach(context.insert)
        try context.save()

        let results = try DataService.activeRegimenItems(context: context)
        #expect(results.map(\.name) == ["Vitamin D3"])
    }

    @Test func activeCustomMedicationCountOnlyCountsActiveCustomMedications() throws {
        let context = try makeContext()

        let customMedication = RegimenItem(name: "Sertraline", category: .medication)
        let archivedCustomMedication = RegimenItem(name: "Old Med", category: .medication)
        archivedCustomMedication.isActive = false
        let catalogMedication = RegimenItem(name: "Catalog Med", category: .medication, catalogId: "some-catalog-id")
        let customSupplement = RegimenItem(name: "Custom Supplement", category: .supplement)

        [customMedication, archivedCustomMedication, catalogMedication, customSupplement].forEach(context.insert)
        try context.save()

        let count = try DataService.activeCustomMedicationCount(context: context)
        #expect(count == 1)
    }

    @Test func regimenEventsIncludesStartAndStopWithinRange() throws {
        let context = try makeContext()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -10, to: today)!
        let stop = calendar.date(byAdding: .day, value: -2, to: today)!

        let item = RegimenItem(name: "BPC-157", category: .peptide)
        item.startDate = start
        item.endDate = stop
        context.insert(item)
        try context.save()

        let range = calendar.date(byAdding: .day, value: -15, to: today)!...today
        let events = try DataService.regimenEvents(in: range, context: context)

        #expect(events.count == 2)
        #expect(events.contains { $0.kind == .started && calendar.isDate($0.date, inSameDayAs: start) })
        #expect(events.contains { $0.kind == .stopped && calendar.isDate($0.date, inSameDayAs: stop) })
    }
}
