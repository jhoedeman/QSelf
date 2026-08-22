import Foundation
import UserNotifications
import SwiftData

/// Turns the notification preferences stored in `UserDefaults` (by Settings and
/// Onboarding) into actual scheduled local notifications. Nothing schedules
/// itself just by being toggled on in the UI — call `reschedule(context:)`
/// whenever a setting changes and on every foreground activation, mirroring
/// `ComplianceService`'s fill-job pattern. Idempotent: always clears and
/// rebuilds every notification this service owns, so it's safe to call
/// repeatedly.
enum NotificationService {

    private static let dailyLogIdentifierPrefix = "notify.dailyLog."
    private static let injectionIdentifierPrefix = "notify.injection."
    private static let labsDueIdentifier = "notify.labsDue"
    private static let labsDueLastNudgeKey = "notify.labsDue.lastNudgeDate"

    static func reschedule(context: ModelContext) async {
        let center = UNUserNotificationCenter.current()

        let pending = await center.pendingNotificationRequests()
        let ownedIdentifiers = pending
            .map(\.identifier)
            .filter {
                $0.hasPrefix(dailyLogIdentifierPrefix)
                    || $0.hasPrefix(injectionIdentifierPrefix)
                    || $0 == labsDueIdentifier
            }
        center.removePendingNotificationRequests(withIdentifiers: ownedIdentifiers)

        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        await scheduleDailyLogReminders(center: center)
        await scheduleInjectionReminders(center: center, context: context)
        await scheduleLabsDueNudge(center: center, context: context)
    }

    // MARK: - Daily log reminders

    private static func scheduleDailyLogReminders(center: UNUserNotificationCenter) async {
        guard UserDefaults.standard.bool(forKey: "notify.dailyLog.enabled") else { return }

        let startHour = storedInt("notify.dailyLog.windowStartHour", default: 8)
        let startMin = storedInt("notify.dailyLog.windowStartMin", default: 0)
        let endHour = storedInt("notify.dailyLog.windowEndHour", default: 21)
        let endMin = storedInt("notify.dailyLog.windowEndMin", default: 0)
        let count = max(1, storedInt("notify.dailyLog.count", default: 1))

        let startMinutes = startHour * 60 + startMin
        let endMinutes = endHour * 60 + endMin
        let windowMinutes = max(1, endMinutes - startMinutes)

        for i in 0..<count {
            let offset = windowMinutes * (i + 1) / (count + 1)
            let totalMinutes = startMinutes + offset
            let hour = (totalMinutes / 60) % 24
            let minute = totalMinutes % 60

            let content = UNMutableNotificationContent()
            content.title = "Time for your check-in"
            content.body = "Log how you're feeling — it only takes 30 seconds."
            content.sound = .default

            var comps = DateComponents()
            comps.hour = hour
            comps.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(dailyLogIdentifierPrefix)\(i)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    // MARK: - Injection day reminders

    private static func scheduleInjectionReminders(center: UNUserNotificationCenter, context: ModelContext) async {
        guard UserDefaults.standard.bool(forKey: "notify.injection.enabled") else { return }

        let hour = storedInt("notify.injection.hour", default: 9)
        let minute = storedInt("notify.injection.minute", default: 0)

        guard let items = try? DataService.activeRegimenItems(context: context) else { return }
        let injectables = items.filter(\.isInjectable)
        guard !injectables.isEmpty else { return }

        let calendar = Calendar.current
        let now = Date()

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)) else { continue }
            let dueItems = injectables.filter { $0.isScheduled(on: date) }
            guard !dueItems.isEmpty else { continue }

            var comps = calendar.dateComponents([.year, .month, .day], from: date)
            comps.hour = hour
            comps.minute = minute
            guard let fireDate = calendar.date(from: comps), fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Injection due today"
            content.body = dueItems.count == 1
                ? "\(dueItems[0].name) is scheduled for today."
                : "\(dueItems.map(\.name).joined(separator: ", ")) are scheduled for today."
            content.sound = .default

            let dateKey = DateFormatter.injectionKeyFormatter.string(from: date)
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "\(injectionIdentifierPrefix)\(dateKey)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    // MARK: - Labs due nudge

    private static func scheduleLabsDueNudge(center: UNUserNotificationCenter, context: ModelContext) async {
        guard UserDefaults.standard.bool(forKey: "notify.labsDue.enabled") else { return }
        guard let lastDate = (try? DataService.allLabResults(context: context))?.first?.date else { return }

        let calendar = Calendar.current
        guard let due = calendar.date(byAdding: .day, value: 90, to: lastDate) else { return }
        let now = Date()

        var fireDate = due
        if due <= now {
            // Already overdue — avoid re-nagging more than once a week.
            if let last = UserDefaults.standard.object(forKey: labsDueLastNudgeKey) as? Date,
               now.timeIntervalSince(last) < 7 * 24 * 3600 {
                return
            }
            fireDate = now.addingTimeInterval(5)
            UserDefaults.standard.set(now, forKey: labsDueLastNudgeKey)
        }

        let content = UNMutableNotificationContent()
        content.title = "Labs due"
        content.body = "It's been about 90 days since your last draw — time to schedule bloodwork?"
        content.sound = .default

        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: labsDueIdentifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    // MARK: - Helpers

    /// `UserDefaults.integer(forKey:)` silently returns 0 for a key that was
    /// never written — which happens whenever a user leaves an `@AppStorage`
    /// value at its SwiftUI-declared default without ever touching that
    /// control. Reading raw defaults must fall back to the same default the
    /// UI declares, or an untouched 8am–9pm window reads back as midnight–midnight.
    private static func storedInt(_ key: String, default def: Int) -> Int {
        (UserDefaults.standard.object(forKey: key) as? Int) ?? def
    }
}

private extension DateFormatter {
    static let injectionKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
