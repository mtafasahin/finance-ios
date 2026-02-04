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
        let columns: [GridItem] = [GridItem(.adaptive(minimum: 360), spacing: 16, alignment: .top)]

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DashboardHeaderCard(
                    totalValueText: Formatters.currency(dashboard.totalValue, currency: displayCurrency),
                    totalPLText: Formatters.currency(dashboard.totalProfitLoss, currency: displayCurrency),
                    totalPLPctText: Formatters.percent(dashboard.totalProfitLossPct),
                    lastUpdatedText: lastUpdatedText(dashboardLastUpdatedAt: dashboard.lastUpdatedAt),
                    isRefreshing: refreshEngine.isRunning
                )

                LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                    ForEach(AssetType.allCases) { t in
                        let items = (byType[t] ?? []).filter { $0.quantity > 0 }
                        if !items.isEmpty {
                            let summary = typeSummary(
                                assetType: t,
                                holdings: items,
                                displayCurrency: displayCurrency,
                                usdTry: usdTry
                            )
                            AssetTypeCard(
                                title: t.title,
                                holdingsCount: summary.holdingsCount,
                                totalValueText: Formatters.currency(summary.totalValue, currency: displayCurrency),
                                plText: Formatters.currency(summary.totalProfitLoss, currency: displayCurrency),
                                plIsPositive: summary.totalProfitLoss >= 0,
                                destination: AssetTypePortfolioView(assetType: t)
                            )
                        }
                    }
                }

                if holdings.isEmpty {
                    ContentUnavailableView(
                        "No holdings yet",
                        systemImage: "tray",
                        description: Text("Add an asset and a transaction to see portfolio cards here.")
                    )
                    .padding(.top, 12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task { await refreshEngine.refreshOnce(modelContext: modelContext) }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
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

    private func typeSummary(
        assetType: AssetType,
        holdings: [HoldingSnapshot],
        displayCurrency: CurrencyCode,
        usdTry: Decimal?
    ) -> TypeSummary {
        var totalValue: Decimal = 0
        var totalCost: Decimal = 0

        for h in holdings {
            let lastPrice = h.lastPrice ?? 0
            let value = lastPrice * h.quantity
            let valueCurrency = h.lastPriceCurrency ?? h.currency
            let valueDisplay = CurrencyConverter.convert(value, from: valueCurrency, to: displayCurrency, usdTry: usdTry)
            totalValue += valueDisplay

            let cost = h.quantity * h.averagePrice
            let costDisplay = CurrencyConverter.convert(cost, from: h.currency, to: displayCurrency, usdTry: usdTry)
            totalCost += costDisplay
        }

        return TypeSummary(
            holdingsCount: holdings.count,
            totalValue: totalValue,
            totalProfitLoss: totalValue - totalCost
        )
    }
}

private struct TypeSummary {
    let holdingsCount: Int
    let totalValue: Decimal
    let totalProfitLoss: Decimal
}

private struct DashboardHeaderCard: View {
    let totalValueText: String
    let totalPLText: String
    let totalPLPctText: String
    let lastUpdatedText: String
    let isRefreshing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(totalValueText)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }

                Spacer()

                HStack(spacing: 8) {
                    if isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(lastUpdatedText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                StatPill(title: "P/L", value: totalPLText, valueStyle: .primary)
                StatPill(title: "P/L %", value: totalPLPctText, valueStyle: .secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 8)
        )
    }
}

private struct AssetTypeCard<Destination: View>: View {
    let title: String
    let holdingsCount: Int
    let totalValueText: String
    let plText: String
    let plIsPositive: Bool
    let destination: Destination

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                NavigationLink {
                    destination
                } label: {
                    Text("View Details →")
                        .font(.subheadline)
                }
            }

            Divider().opacity(0.4)

            HStack(spacing: 12) {
                StatPill(title: "Holdings", value: "\(holdingsCount)", valueStyle: .primary)
                StatPill(title: "Total Value", value: totalValueText, valueStyle: .primary)
                StatPill(title: "P&L", value: plText, valueStyle: plIsPositive ? .positive : .negative)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 8)
        )
    }
}

private enum StatValueStyle {
    case primary
    case secondary
    case positive
    case negative

    var color: Color {
        switch self {
        case .primary: return .primary
        case .secondary: return .secondary
        case .positive: return .green
        case .negative: return .red
        }
    }
}

private struct StatPill: View {
    let title: String
    let value: String
    let valueStyle: StatValueStyle

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.headline)
                .foregroundStyle(valueStyle.color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}
