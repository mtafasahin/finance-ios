import SwiftUI
import SwiftData

struct AssetTypePortfolioView: View {
    let assetType: AssetType

    @Query(sort: \AssetEntity.symbol) private var assets: [AssetEntity]
    @Query(sort: \TransactionEntity.date, order: .reverse) private var transactions: [TransactionEntity]
    @Query private var settings: [AppSettingsEntity]
    @Query(filter: #Predicate<FXRateEntity> { $0.pair == "USDTRY" }) private var usdTryRates: [FXRateEntity]

    @State private var sortKey: SortKey = .name
    @State private var sortAscending: Bool = true

    var body: some View {
        let displayCurrency = settings.first?.displayCurrency ?? .try
        let usdTry = usdTryRates.first?.rate

        let holdings = PortfolioCalculator.holdings(assets: assets, transactions: transactions)
            .filter { $0.type == assetType && $0.quantity > 0 }

        let rows = holdings.map { h in
            HoldingComputed(
                holding: h,
                displayCurrency: displayCurrency,
                usdTry: usdTry
            )
        }

        let sortedRows = rows.sorted { a, b in
            let order: Bool
            switch sortKey {
            case .name:
                order = a.holding.name.localizedCaseInsensitiveCompare(b.holding.name) == .orderedAscending
            case .totalValue:
                order = a.valueDisplay < b.valueDisplay
            case .profitLoss:
                order = a.profitLoss < b.profitLoss
            case .profitLossPct:
                order = a.profitLossPct < b.profitLossPct
            }

            return sortAscending ? order : !order
        }

        List {
            Section {
                ForEach(sortedRows) { row in
                    HoldingRow(holding: row.holding, displayCurrency: displayCurrency, usdTry: usdTry)
                }

                if holdings.isEmpty {
                    Text("No holdings in \(assetType.title) yet.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(assetType.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort", selection: $sortKey) {
                        ForEach(SortKey.allCases) { key in
                            Text(key.title).tag(key)
                        }
                    }

                    Divider()

                    Button {
                        sortAscending.toggle()
                    } label: {
                        Label(
                            sortAscending ? "Ascending" : "Descending",
                            systemImage: sortAscending ? "arrow.up" : "arrow.down"
                        )
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
        }
    }
}

private enum SortKey: String, CaseIterable, Identifiable {
    case name
    case totalValue
    case profitLoss
    case profitLossPct

    var id: String { rawValue }

    var title: String {
        switch self {
        case .name: return "Asset Name"
        case .totalValue: return "Total Value"
        case .profitLoss: return "P/L"
        case .profitLossPct: return "P/L %"
        }
    }
}

private struct HoldingComputed: Identifiable {
    var id: UUID { holding.id }
    let holding: HoldingSnapshot
    let valueDisplay: Decimal
    let profitLoss: Decimal
    let profitLossPct: Decimal

    init(holding: HoldingSnapshot, displayCurrency: CurrencyCode, usdTry: Decimal?) {
        self.holding = holding

        let lastPrice = holding.lastPrice ?? 0
        let value = lastPrice * holding.quantity
        let valueCurrency = holding.lastPriceCurrency ?? holding.currency
        let valueDisplay = CurrencyConverter.convert(value, from: valueCurrency, to: displayCurrency, usdTry: usdTry)

        let cost = holding.quantity * holding.averagePrice
        let costDisplay = CurrencyConverter.convert(cost, from: holding.currency, to: displayCurrency, usdTry: usdTry)

        self.valueDisplay = valueDisplay
        self.profitLoss = valueDisplay - costDisplay
        self.profitLossPct = costDisplay == 0 ? 0 : (self.profitLoss / costDisplay)
    }
}

private struct HoldingRow: View {
    let holding: HoldingSnapshot
    let displayCurrency: CurrencyCode
    let usdTry: Decimal?

    var body: some View {
        let lastPrice = holding.lastPrice ?? Decimal(0)
        let value = lastPrice * holding.quantity
        let valueCurrency = holding.lastPriceCurrency ?? holding.currency
        let valueDisplay = CurrencyConverter.convert(value, from: valueCurrency, to: displayCurrency, usdTry: usdTry)

        let cost = holding.quantity * holding.averagePrice
        let costDisplay = CurrencyConverter.convert(cost, from: holding.currency, to: displayCurrency, usdTry: usdTry)

        let pl = valueDisplay - costDisplay
        let plPct = costDisplay == 0 ? Decimal(0) : (pl / costDisplay)

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(holding.symbol).font(.headline)
                    Text(holding.name).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Formatters.currency(valueDisplay, currency: displayCurrency))
                        .font(.headline)
                        .monospacedDigit()
                    Text(Formatters.percent(plPct))
                        .font(.subheadline)
                        .foregroundStyle(pl >= 0 ? .green : .red)
                        .monospacedDigit()
                }
            }

            HStack {
                Text("Qty: \(NSDecimalNumber(decimal: holding.quantity))")
                Spacer()
                Text("Avg: \(Formatters.currency(holding.averagePrice, currency: holding.currency))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {
                Text("Last: \(Formatters.currency(lastPrice, currency: valueCurrency))")
                Spacer()
                Text("P/L: \(Formatters.currency(pl, currency: displayCurrency))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let t = holding.lastUpdatedAt {
                Text("Updated: \(Formatters.dateTime(t))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
