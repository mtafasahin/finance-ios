import SwiftUI
import SwiftData

struct AssetTypePortfolioView: View {
    let assetType: AssetType

    @Query(sort: \AssetEntity.symbol) private var assets: [AssetEntity]
    @Query(sort: \TransactionEntity.date, order: .reverse) private var transactions: [TransactionEntity]
    @Query private var settings: [AppSettingsEntity]
    @Query(filter: #Predicate<FXRateEntity> { $0.pair == "USDTRY" }) private var usdTryRates: [FXRateEntity]

    var body: some View {
        let displayCurrency = settings.first?.displayCurrency ?? .try
        let usdTry = usdTryRates.first?.rate

        let holdings = PortfolioCalculator.holdings(assets: assets, transactions: transactions)
            .filter { $0.type == assetType && $0.quantity > 0 }

        List {
            Section {
                ForEach(holdings) { h in
                    HoldingRow(holding: h, displayCurrency: displayCurrency, usdTry: usdTry)
                }

                if holdings.isEmpty {
                    Text("No holdings in \(assetType.title) yet.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(assetType.title)
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
