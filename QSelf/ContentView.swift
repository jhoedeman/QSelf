import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            LogView()
                .tabItem { Label("Log", systemImage: "pencil") }

            RegimenView()
                .tabItem { Label("Regimen", systemImage: "pills") }

            Text("Labs")
                .tabItem { Label("Labs", systemImage: "testtube.2") }

            Text("Trends")
                .tabItem { Label("Trends", systemImage: "chart.line.uptrend.xyaxis") }

            Text("Settings")
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Color.apexArc)
        .toolbarBackground(Color.apexSurfaceElevated, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}

#Preview {
    ContentView()
        .modelContainer(try! ModelContainer.makeContainer(cloudKit: false, isStoredInMemoryOnly: true))
        .preferredColorScheme(.dark)
}
