import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Text("Log")
                .tabItem { Label("Log", systemImage: "pencil") }

            Text("Regimen")
                .tabItem { Label("Regimen", systemImage: "pills") }

            Text("Labs")
                .tabItem { Label("Labs", systemImage: "testtube.2") }

            Text("Trends")
                .tabItem { Label("Trends", systemImage: "chart.line.uptrend.xyaxis") }

            Text("Settings")
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(try! ModelContainer.makeContainer(cloudKit: false, isStoredInMemoryOnly: true))
}
