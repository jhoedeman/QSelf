import SwiftUI
import SwiftData

@main
struct QSelfApp: App {

    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer.makeContainer()
            Self.seedMoodTagsIfNeeded(container: container)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        // TestFlight-only: unlock Pro by default so testers see every feature
        // without buying anything. Only fills in the default — it never
        // overwrites an explicit isPro value, so the Settings > Account
        // toggle below still works normally. Remove before public release.
        UserDefaults.standard.register(defaults: ["isPro": true])
    }

    /// Manual test override for onboarding, independent of persisted completion
    /// state: `true` forces onboarding to show on every launch, `false` forces
    /// it to stay hidden, `nil` uses normal behavior (`hasCompletedOnboarding`).
    private static let forceOnboardingOverride: Bool? = nil

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var onboardingDismissed = false
    @Environment(\.scenePhase) private var scenePhase

    private var showOnboarding: Bool {
        Self.forceOnboardingOverride ?? !hasCompletedOnboarding
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .fullScreenCover(isPresented: Binding(
                    get: { !onboardingDismissed && showOnboarding },
                    set: { if !$0 { onboardingDismissed = true } }
                )) {
                    OnboardingView()
                }
                .onChange(of: scenePhase, initial: true) { _, phase in
                    if phase == .active {
                        runComplianceFillJob()
                        rescheduleNotifications()
                    }
                }
        }
        .modelContainer(container)
    }

    /// Runs on every foreground activation, per the brief's compliance fill
    /// job spec. Idempotent — ComplianceService no-ops if it already ran today.
    private func runComplianceFillJob() {
        let backgroundContext = ModelContext(container)
        Task {
            await ComplianceService().runFillJob(context: backgroundContext)
        }
    }

    /// Re-derives every scheduled local notification from current settings and
    /// data. Idempotent — safe to call on every foreground activation.
    private func rescheduleNotifications() {
        let backgroundContext = ModelContext(container)
        Task {
            await NotificationService.reschedule(context: backgroundContext)
        }
    }

    /// Idempotent: safe to call on a device that syncs in existing tags via CloudKit.
    private static func seedMoodTagsIfNeeded(container: ModelContainer) {
        let context = ModelContext(container)
        let existingCount = (try? context.fetchCount(FetchDescriptor<MoodTag>())) ?? 0
        guard existingCount == 0 else { return }
        for name in MoodTag.seedNames {
            context.insert(MoodTag(name: name))
        }
        try? context.save()
    }
}
