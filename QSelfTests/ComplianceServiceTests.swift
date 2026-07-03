import Testing
import Foundation
import SwiftData
@testable import QSelf

struct ComplianceServiceTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer.makeContainer(cloudKit: false, isStoredInMemoryOnly: true)
        return ModelContext(container)
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

        let service = ComplianceService()
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

        let service = ComplianceService()
        await service.runFillJob(context: context)

        let records = try context.fetch(FetchDescriptor<ComplianceRecord>())
        let recordForTwoDaysAgo = records.first { calendar.isDate($0.date, inSameDayAs: twoDaysAgo) }

        #expect(recordForTwoDaysAgo?.status == .taken)
        #expect(records.filter { calendar.isDate($0.date, inSameDayAs: twoDaysAgo) }.count == 1)
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

        let service = ComplianceService()
        let range = calendar.date(byAdding: .day, value: -10, to: today)!...today
        let rate = await service.complianceRate(for: item, in: range, context: context)

        #expect(rate == 0.75)
    }
}
