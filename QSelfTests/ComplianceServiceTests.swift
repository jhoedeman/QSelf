import Testing
import Foundation
import SwiftData
@testable import QSelf

struct ComplianceServiceTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer.makeContainer(cloudKit: false, isStoredInMemoryOnly: true)
        return ModelContext(container)
    }

    /// A fresh, isolated UserDefaults suite per test so the fill job's
    /// "already ran today" guard can't leak state across test invocations
    /// sharing the same test process.
    private func makeService() -> ComplianceService {
        ComplianceService(defaults: UserDefaults(suiteName: UUID().uuidString)!)
    }

    @Test func fillJobBackfillsMissedRecordsAndCreatesUpcomingPending() async throws {
        let context = try makeContext()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: today)!

        let item = RegimenItem(name: "Vitamin D3", category: .supplement)
        item.scheduleType = .daily
        item.startDate = fiveDaysAgo
        context.insert(item)

        let slot = DoseSlot(timeOfDay: .morning, amount: 5000, unit: "IU")
        slot.regimenItem = item
        item.doseSlots = [slot]
        context.insert(slot)

        try context.save()

        let service = makeService()
        await service.runFillJob(context: context)

        let records = try context.fetch(FetchDescriptor<ComplianceRecord>())

        // 5 missed days backfilled (today itself is excluded) + 7 upcoming pending days.
        let missed = records.filter { $0.status == .missed }
        let pending = records.filter { $0.status == .pending }
        #expect(missed.count == 5)
        #expect(pending.count == 7)
        #expect(missed.allSatisfy { $0.isRetroactive })
    }

    @Test func fillJobNeverOverwritesUserEditedRecords() async throws {
        let context = try makeContext()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        let item = RegimenItem(name: "Creatine", category: .supplement)
        item.scheduleType = .daily
        item.startDate = threeDaysAgo
        context.insert(item)

        let slot = DoseSlot(timeOfDay: .morning, amount: 5, unit: "g")
        slot.regimenItem = item
        item.doseSlots = [slot]
        context.insert(slot)

        // User already logged this dose as taken before the fill job ever ran.
        let userRecord = ComplianceRecord(date: twoDaysAgo, doseSlot: slot, status: .taken)
        userRecord.editedByUser = true
        slot.complianceRecords = [userRecord]
        context.insert(userRecord)

        try context.save()

        let service = makeService()
        await service.runFillJob(context: context)

        let records = try context.fetch(FetchDescriptor<ComplianceRecord>())
        let recordForTwoDaysAgo = records.first { calendar.isDate($0.date, inSameDayAs: twoDaysAgo) }

        #expect(recordForTwoDaysAgo?.status == .taken)
        #expect(records.filter { calendar.isDate($0.date, inSameDayAs: twoDaysAgo) }.count == 1)
    }

    @Test func fillJobCreatesPendingRecordsForItemsAddedAfterFirstRunTheSameDay() async throws {
        let context = try makeContext()
        let service = makeService()

        // Simulate the app's first foreground fill job of the day running
        // before the user has added anything.
        await service.runFillJob(context: context)

        // User adds a new item later the same day (e.g. via the catalog).
        let item = RegimenItem(name: "Magnesium", category: .supplement)
        item.scheduleType = .daily
        context.insert(item)
        let slot = DoseSlot(timeOfDay: .evening, amount: 400, unit: "mg")
        slot.regimenItem = item
        item.doseSlots = [slot]
        context.insert(slot)
        try context.save()

        // A second fill job the same day (e.g. opening the Regimen tab)
        // must still create today's pending record for the new item —
        // it must not be skipped just because the job already ran today.
        await service.runFillJob(context: context)

        let records = try context.fetch(FetchDescriptor<ComplianceRecord>())
        let recordForNewItem = records.first { $0.doseSlot?.persistentModelID == slot.persistentModelID }

        #expect(recordForNewItem?.status == .pending)
    }

    @Test func complianceRateCountsTakenAndPartialAsCompliant() async throws {
        let context = try makeContext()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let item = RegimenItem(name: "Omega-3", category: .supplement)
        context.insert(item)

        let slot = DoseSlot(timeOfDay: .morning, amount: 2000, unit: "mg")
        slot.regimenItem = item
        item.doseSlots = [slot]
        context.insert(slot)

        let statuses: [ComplianceStatus] = [.taken, .taken, .partial, .missed]
        var records: [ComplianceRecord] = []
        for (offset, status) in statuses.enumerated() {
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let record = ComplianceRecord(date: date, doseSlot: slot, status: status)
            context.insert(record)
            records.append(record)
        }
        slot.complianceRecords = records
        try context.save()

        let service = makeService()
        let range = calendar.date(byAdding: .day, value: -10, to: today)!...today
        let rate = await service.complianceRate(for: item, in: range, context: context)

        #expect(rate == 0.75)
    }
}
