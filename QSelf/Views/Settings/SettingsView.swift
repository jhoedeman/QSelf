import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false

    // Daily log reminders — same keys onboarding writes to.
    @AppStorage("notify.dailyLog.enabled") private var dailyLogEnabled = false
    @AppStorage("notify.dailyLog.windowStartHour") private var windowStartHour = 8
    @AppStorage("notify.dailyLog.windowStartMin") private var windowStartMin = 0
    @AppStorage("notify.dailyLog.windowEndHour") private var windowEndHour = 21
    @AppStorage("notify.dailyLog.windowEndMin") private var windowEndMin = 0
    @AppStorage("notify.dailyLog.count") private var dailyLogCount = 1

    // Injection-day reminder
    @AppStorage("notify.injection.enabled") private var injectionEnabled = false
    @AppStorage("notify.injection.hour") private var injectionHour = 9
    @AppStorage("notify.injection.minute") private var injectionMinute = 0

    // Labs-due nudge (fires ~90 days after the last LabResult, per the brief)
    @AppStorage("notify.labsDue.enabled") private var labsDueEnabled = false

    @State private var showMetricLayout = false
    @State private var showUpgradeSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    notificationsCard
                    metricsCard
                    proCard
                }
                .padding()
            }
            .background(Color.apexCanvas)
            .navigationTitle("Settings")
            .toolbarBackground(Color.apexCanvas, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showMetricLayout) {
                MetricLayoutView()
            }
            .sheet(isPresented: $showUpgradeSheet) {
                UpgradeSheet()
            }
            .onChange(of: dailyLogEnabled) { _, enabled in notificationSettingChanged(requestPermissionIfNeeded: enabled) }
            .onChange(of: windowStartHour) { _, _ in rescheduleNotifications() }
            .onChange(of: windowStartMin) { _, _ in rescheduleNotifications() }
            .onChange(of: windowEndHour) { _, _ in rescheduleNotifications() }
            .onChange(of: windowEndMin) { _, _ in rescheduleNotifications() }
            .onChange(of: dailyLogCount) { _, _ in rescheduleNotifications() }
            .onChange(of: injectionEnabled) { _, enabled in notificationSettingChanged(requestPermissionIfNeeded: enabled) }
            .onChange(of: injectionHour) { _, _ in rescheduleNotifications() }
            .onChange(of: injectionMinute) { _, _ in rescheduleNotifications() }
            .onChange(of: labsDueEnabled) { _, enabled in notificationSettingChanged(requestPermissionIfNeeded: enabled) }
        }
    }

    // MARK: - Notification scheduling

    private func notificationSettingChanged(requestPermissionIfNeeded: Bool) {
        if requestPermissionIfNeeded {
            Task {
                _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                await NotificationService.reschedule(context: context)
            }
        } else {
            rescheduleNotifications()
        }
    }

    private func rescheduleNotifications() {
        Task { await NotificationService.reschedule(context: context) }
    }

    // MARK: - Notifications

    private var notificationsCard: some View {
        CardSection(title: "Notifications") {
            VStack(spacing: 16) {
                Toggle(isOn: $dailyLogEnabled) {
                    Label("Daily log reminder", systemImage: "bell")
                        .foregroundStyle(Color.apexTextPrimary)
                }
                .tint(Color.apexArc)

                if dailyLogEnabled {
                    Divider().overlay(Color.apexBorder)
                    notifTimePicker(label: "Window start", hour: $windowStartHour, minute: $windowStartMin)
                    notifTimePicker(label: "Window end", hour: $windowEndHour, minute: $windowEndMin)
                    Stepper(value: $dailyLogCount, in: 1...3) {
                        HStack {
                            Text("Reminders per day").foregroundStyle(Color.apexTextPrimary)
                            Spacer()
                            Text("\(dailyLogCount)").foregroundStyle(Color.apexTextSecondary)
                        }
                    }
                    NotificationPreview()
                }

                Divider().overlay(Color.apexBorder)

                Toggle(isOn: $injectionEnabled) {
                    Label("Injection day reminder", systemImage: "syringe")
                        .foregroundStyle(Color.apexTextPrimary)
                }
                .tint(Color.apexArc)

                if injectionEnabled {
                    notifTimePicker(label: "Reminder time", hour: $injectionHour, minute: $injectionMinute)
                }

                Divider().overlay(Color.apexBorder)

                Toggle(isOn: $labsDueEnabled) {
                    Label("Labs due nudge", systemImage: "testtube.2")
                        .foregroundStyle(Color.apexTextPrimary)
                }
                .tint(Color.apexArc)
                if labsDueEnabled {
                    Text("Reminds you ~90 days after your last recorded draw.")
                        .font(.caption)
                        .foregroundStyle(Color.apexTextTertiary)
                }
            }
        }
    }

    private func notifTimePicker(label: String, hour: Binding<Int>, minute: Binding<Int>) -> some View {
        let binding = Binding<Date>(
            get: {
                Calendar.current.date(bySettingHour: hour.wrappedValue, minute: minute.wrappedValue, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                hour.wrappedValue = comps.hour ?? hour.wrappedValue
                minute.wrappedValue = comps.minute ?? minute.wrappedValue
            }
        )
        return DatePicker(label, selection: binding, displayedComponents: .hourAndMinute)
            .foregroundStyle(Color.apexTextPrimary)
    }

    // MARK: - Metrics

    private var metricsCard: some View {
        CardSection(title: "Metrics") {
            Button {
                showMetricLayout = true
            } label: {
                HStack {
                    Label("Edit metric layout", systemImage: "slider.horizontal.3")
                        .foregroundStyle(Color.apexTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.apexTextTertiary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Pro / Account

    private var proCard: some View {
        CardSection(title: "Account") {
            if isPro {
                HStack {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.apexPulse)
                    Text("QSelf Pro").foregroundStyle(Color.apexTextPrimary)
                    Spacer()
                }
            } else {
                Button {
                    showUpgradeSheet = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles").foregroundStyle(Color.apexArc)
                        Text("Upgrade to Pro").foregroundStyle(Color.apexTextPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.apexTextTertiary)
                    }
                }
                .buttonStyle(.plain)
            }

            Button("Restore purchases") {
                showUpgradeSheet = true
            }
            .font(.footnote)
            .foregroundStyle(Color.apexTextSecondary)
            .padding(.top, 4)
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
