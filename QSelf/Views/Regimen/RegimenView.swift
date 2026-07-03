import SwiftUI
import SwiftData

struct RegimenView: View {
    enum Mode: String, CaseIterable {
        case today = "Today"
        case manage = "Manage"
    }

    @State private var mode: Mode = .today
    @State private var showCatalog = false
    @State private var reloadToken = UUID()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

                switch mode {
                case .today: TodayComplianceView().id(reloadToken)
                case .manage: ManageRegimenView().id(reloadToken)
                }
            }
            .background(Color.apexCanvas)
            .navigationTitle("Regimen")
            .toolbarBackground(Color.apexCanvas, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { showCatalog = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCatalog, onDismiss: { reloadToken = UUID() }) {
                CatalogView()
            }
        }
    }
}

#Preview {
    RegimenView()
        .modelContainer(try! ModelContainer.makeContainer(cloudKit: false, isStoredInMemoryOnly: true))
        .preferredColorScheme(.dark)
}
