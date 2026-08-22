import SwiftUI
import SwiftData
import UserNotifications

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var step = 0

    // Step 1: framing (not a filter — just sets expectations, not persisted)
    @State private var trackingFocus: String? = nil
    private let trackingFocusOptions = ["Supplements", "Peptides & injectables", "Bloodwork", "All of it"]

    // Step 2: regimen
    @State private var selectedCatalogIDs: Set<String> = []
    private let maxOnboardingSelections = 5

    // Step 3: notifications (same AppStorage keys Settings/NotificationService will read)
    @AppStorage("notify.dailyLog.enabled") private var dailyLogEnabled = false
    @AppStorage("notify.dailyLog.windowStartHour") private var windowStartHour = 8
    @AppStorage("notify.dailyLog.windowStartMin") private var windowStartMin = 0
    @AppStorage("notify.dailyLog.windowEndHour") private var windowEndHour = 21
    @AppStorage("notify.dailyLog.windowEndMin") private var windowEndMin = 0
    @AppStorage("notify.dailyLog.count") private var dailyLogCount = 1

    private let totalSteps = 5

    var body: some View {
        VStack(spacing: 0) {
            progressDots
                .padding(.top, 20)
                .padding(.bottom, 8)

            TabView(selection: $step) {
                welcomeStep.tag(0)
                framingStep.tag(1)
                regimenStep.tag(2)
                notificationsStep.tag(3)
                allSetStep.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)

            navigationButtons
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .background(Color.apexCanvas.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: - Progress dots

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i == step ? Color.apexArc : Color.apexBorder)
                    .frame(width: i == step ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.3), value: step)
            }
        }
    }

    // MARK: - Navigation

    private var isLastStep: Bool { step == totalSteps - 1 }
    private var canSkip: Bool { step == 1 || step == 2 || step == 3 }

    private var navigationButtons: some View {
        HStack {
            if step > 0 && step < totalSteps - 1 {
                Button("Back") { step -= 1 }
                    .foregroundStyle(Color.apexTextSecondary)
            }
            Spacer()
            if canSkip {
                Button("Skip") { advance() }
                    .foregroundStyle(Color.apexTextSecondary)
                    .padding(.trailing, 8)
            }
            if isLastStep {
                Button("Log today") { finish() }
                    .primaryPillStyle()
            } else if step == 0 {
                Button("Get started") { step = 1 }
                    .primaryPillStyle()
            } else {
                Button(step == totalSteps - 2 ? "Finish" : "Next") { advance() }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.apexArc)
            }
        }
    }

    private func advance() {
        if step == 3 { Task { await requestNotificationPermission() } }
        step += 1
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 64))
                .foregroundStyle(Color.apexArc)
            VStack(spacing: 12) {
                Text("Welcome to QSelf")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.apexTextPrimary)
                    .multilineTextAlignment(.center)
                VStack(alignment: .leading, spacing: 10) {
                    featureRow(icon: "pencil", text: "Log how you feel in about 30 seconds a day")
                    featureRow(icon: "pills", text: "Track supplements, peptides, and injectables")
                    featureRow(icon: "chart.line.uptrend.xyaxis", text: "See how your regimen correlates with bloodwork")
                }
                .padding(.top, 8)
                Text("Your data stays on your device and in your own iCloud account — never shared.")
                    .font(.footnote)
                    .foregroundStyle(Color.apexTextTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.apexPulse)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.apexTextSecondary)
        }
    }

    // MARK: - Step 1: Framing

    private var framingStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(
                    title: "What are you tracking?",
                    subtitle: "Just to set expectations — everyone gets the full app either way."
                )

                onboardingCard(title: "Focus") {
                    VStack(spacing: 8) {
                        ForEach(trackingFocusOptions, id: \.self) { option in
                            Button { trackingFocus = option } label: {
                                HStack {
                                    Text(option).foregroundStyle(Color.apexTextPrimary)
                                    Spacer()
                                    if trackingFocus == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.apexArc)
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .background(trackingFocus == option ? Color.apexArc.opacity(0.08) : Color.apexCanvas)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(
                                    trackingFocus == option ? Color.apexArc.opacity(0.3) : Color.apexBorder,
                                    lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    // MARK: - Step 2: Build your regimen

    private var regimenStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(
                    title: "Build your regimen",
                    subtitle: "Pick up to \(maxOnboardingSelections) items to start with. You can add more any time."
                )

                Text("\(selectedCatalogIDs.count) of \(maxOnboardingSelections) selected")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.apexTextTertiary)

                onboardingCard(title: "Catalog") {
                    VStack(spacing: 8) {
                        ForEach(RegimenCatalog.freeItems) { catalogItem in
                            catalogRow(catalogItem)
                            if catalogItem.id != RegimenCatalog.freeItems.last?.id {
                                Divider().overlay(Color.apexBorder)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private func catalogRow(_ catalogItem: CatalogItem) -> some View {
        let isSelected = selectedCatalogIDs.contains(catalogItem.id)
        let isDisabled = !isSelected && selectedCatalogIDs.count >= maxOnboardingSelections

        return Button {
            toggle(catalogItem)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: categoryIcon(catalogItem.category))
                    .foregroundStyle(isSelected ? Color.apexArc : Color.apexTextSecondary)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(catalogItem.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.apexTextPrimary)
                    Text(catalogItem.description)
                        .font(.caption)
                        .foregroundStyle(Color.apexTextTertiary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.apexArc : Color.apexTextTertiary)
            }
            .padding(.vertical, 6)
            .opacity(isDisabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private func toggle(_ catalogItem: CatalogItem) {
        if selectedCatalogIDs.contains(catalogItem.id) {
            selectedCatalogIDs.remove(catalogItem.id)
        } else if selectedCatalogIDs.count < maxOnboardingSelections {
            selectedCatalogIDs.insert(catalogItem.id)
        }
    }

    private func categoryIcon(_ category: RegimenCategory) -> String {
        switch category {
        case .supplement: return "pills.fill"
        case .protein: return "scalemass.fill"
        case .peptide, .injectable: return "syringe.fill"
        case .nootropic: return "brain.head.profile"
        case .medication: return "cross.case.fill"
        case .other: return "circle.fill"
        }
    }

    // MARK: - Step 3: Notifications

    private var notificationsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(
                    title: "Daily reminders",
                    subtitle: "Get a nudge to log how you're feeling each day."
                )

                onboardingCard(title: "Daily Log Reminder") {
                    VStack(spacing: 16) {
                        Toggle(isOn: $dailyLogEnabled) {
                            Label("Enable reminders", systemImage: "bell")
                                .foregroundStyle(Color.apexTextPrimary)
                        }
                        .tint(Color.apexArc)

                        if dailyLogEnabled {
                            Divider().overlay(Color.apexBorder)

                            notifTimePicker(label: "Window start", hour: $windowStartHour, minute: $windowStartMin)
                            notifTimePicker(label: "Window end", hour: $windowEndHour, minute: $windowEndMin)

                            Divider().overlay(Color.apexBorder)

                            Stepper(value: $dailyLogCount, in: 1...3) {
                                HStack {
                                    Text("Reminders per day").foregroundStyle(Color.apexTextPrimary)
                                    Spacer()
                                    Text("\(dailyLogCount)").foregroundStyle(Color.apexTextSecondary)
                                }
                            }
                        }
                    }
                }

                if dailyLogEnabled {
                    let startLabel = timeLabel(hour: windowStartHour, minute: windowStartMin)
                    let endLabel = timeLabel(hour: windowEndHour, minute: windowEndMin)
                    let plural = dailyLogCount == 1 ? "reminder" : "reminders"
                    Text("\(dailyLogCount) \(plural) per day at a random time between \(startLabel) and \(endLabel).")
                        .font(.caption)
                        .foregroundStyle(Color.apexTextTertiary)
                        .padding(.horizontal, 4)
                }
            }
            .padding(24)
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

    private func timeLabel(hour: Int, minute: Int) -> String {
        let comps = DateComponents(hour: hour, minute: minute)
        guard let date = Calendar.current.date(from: comps) else {
            return "\(hour):\(String(format: "%02d", minute))"
        }
        return date.formatted(.dateTime.hour().minute())
    }

    // MARK: - Step 4: All set

    private var allSetStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.apexPulse)
            VStack(spacing: 8) {
                Text("You're all set!")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.apexTextPrimary)
                if selectedCatalogIDs.isEmpty {
                    Text("Your first log is ready whenever you are.")
                        .font(.body)
                        .foregroundStyle(Color.apexTextSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    let names = selectedCatalogIDs.compactMap { RegimenCatalog.item(id: $0)?.name }.sorted()
                    Text("Added \(names.count) item\(names.count == 1 ? "" : "s") to your regimen: \(names.joined(separator: ", ")).")
                        .font(.body)
                        .foregroundStyle(Color.apexTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 8)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Finish

    private func finish() {
        for catalogID in selectedCatalogIDs {
            guard let catalogItem = RegimenCatalog.item(id: catalogID) else { continue }
            let item = catalogItem.makeRegimenItem()
            context.insert(item)
            for slot in item.doseSlots ?? [] {
                context.insert(slot)
            }
        }

        try? context.save()
        hasCompletedOnboarding = true
        Task { await NotificationService.reschedule(context: context) }
        dismiss()
    }

    private func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Shared helpers

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.apexTextPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.apexTextSecondary)
        }
    }

    private func onboardingCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.apexTextTertiary)
                .textCase(.uppercase)
            content()
        }
        .padding(16)
        .background(Color.apexCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.apexBorder, lineWidth: 1))
    }
}

private extension View {
    func primaryPillStyle() -> some View {
        self
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(Color.apexArc)
            .clipShape(Capsule())
    }
}

#Preview {
    let container = try! ModelContainer.makeContainer(cloudKit: false, isStoredInMemoryOnly: true)
    return OnboardingView()
        .modelContainer(container)
}
