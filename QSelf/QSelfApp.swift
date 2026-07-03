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
    }

    /// Set to true to force onboarding on every launch (for testing).
    private static let forceOnboarding = false

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var onboardingDismissed = false

    private var showOnboarding: Bool {
        Self.forceOnboarding || !hasCompletedOnboarding
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
        }
        .modelContainer(container)
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
