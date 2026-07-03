import Testing
import Foundation
import SwiftData
@testable import QSelf

struct ModelTests {

    @Test func dailyLogNormalizesDateToStartOfDay() throws {
        let now = Date()
        let log = DailyLog(date: now)
        #expect(log.date == Calendar.current.startOfDay(for: now))
    }

    @Test func regimenItemDailyScheduleIsAlwaysScheduled() throws {
        let item = RegimenItem(name: "Vitamin D3", category: .supplement)
        item.scheduleType = .daily
        #expect(item.isScheduled(on: Date()))
    }
}
