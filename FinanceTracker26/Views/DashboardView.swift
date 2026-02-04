import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var refreshEngine: PriceRefreshEngine

    @Query(sort: \AssetEntity.symbol) private var assets: [AssetEntity]
    @Query(sort: \TransactionEntity.date, order: .reverse) private var transactions: [TransactionEntity]
    @Query private var settings: [AppSettingsEntity]
    @Query(filter: #Predicate<FXRateEntity> { $0.pair == "USDTRY" }) private var usdTryRates: [FXRateEntity]

    @State private var showAddAsset = false
    @State private var showAddTransaction = false

    var body: some View {
        let displayCurrency = settings.first?.displayCurrency ?? .try
        let usdTry = usdTryRates.first?.rate

        let holdings = PortfolioCalculator.holdings(assets: assets, transactions: transactions)
            .filter { $0.quantity > 0 }

        let dashboard = PortfolioCalculator.dashboard(
            holdings: holdings,
            displayCurrency: displayCurrency,
            usdTry: usdTry
        )

        let byType = Dictionary(grouping: holdings, by: { $0.type })

        List {
            Section {
                StatRow(title: "Total Value", value: Formatters.currency(dashboard.totalValue, currency: displayCurrency))
                StatRow(title: "Total P/L", value: Formatters.currency(dashboard.totalProfitLoss, currency: displayCurrency))
                StatRow(title: "P/L %", value: Formatters.percent(dashboard.totalProfitLossPct))
            }

            Section("Portfolios") {
                ForEach(AssetType.allCases) { t in
                    if let items = byType[t], !items.isEmpty {
                        NavigationLink {
                            AssetTypePortfolioView(assetType: t)
                        } label: {
                            HStack {
                                Text(t.title)
                                Spacer()
                                Text("\(items.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if holdings.isEmpty {
                    Text("No holdings yet. Add an asset and a transaction.")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                HStack {
                    Text("Last updated")
                    Spacer()
                    Text(lastUpdatedText(dashboardLastUpdatedAt: dashboard.lastUpdatedAt))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("FinanceTracker")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task { await refreshEngine.refreshOnce(modelContext: modelContext) }
                } label: {
                    if refreshEngine.isRunning {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showAddTransaction = true
                } label: {
                    Label("Add Transaction", systemImage: "plus.circle")
                }

                Button {
                    showAddAsset = true
                } label: {
                    Label("Add Asset", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddAsset) {
            NavigationStack {
                AddAssetView()
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            NavigationStack {
                AddTransactionView()
            }
        }
    }

    private func lastUpdatedText(dashboardLastUpdatedAt: Date?) -> String {
        if let t = dashboardLastUpdatedAt {
            return Formatters.dateTime(t)
        }
        if let t = refreshEngine.lastGlobalRefreshAt {
            return Formatters.dateTime(t)
        }
        return "-"
    }
}

private struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
    }
}
