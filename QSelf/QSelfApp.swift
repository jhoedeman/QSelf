import SwiftUI
import SwiftData

@main
struct QSelfApp: App {

    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer.makeContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
