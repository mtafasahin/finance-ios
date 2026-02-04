import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var refreshEngine = PriceRefreshEngine()

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Dashboard", systemImage: "chart.pie") }

            NavigationStack {
                AssetsView()
            }
            .tabItem { Label("Assets", systemImage: "briefcase") }

            NavigationStack {
                TransactionsView()
            }
            .tabItem { Label("Transactions", systemImage: "list.bullet") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gear") }
        }
        .environmentObject(refreshEngine)
        .task {
            await ensureSettings()
            refreshEngine.start(modelContext: modelContext, intervalSeconds: 15)
        }
        .onDisappear {
            refreshEngine.stop()
        }
    }

    private func ensureSettings() async {
        do {
            let descriptor = FetchDescriptor<AppSettingsEntity>()
            let existing = try modelContext.fetch(descriptor)
            if existing.isEmpty {
                modelContext.insert(AppSettingsEntity(displayCurrency: .try))
                try modelContext.save()
            }
        } catch {
            // ignore
        }
    }
}
