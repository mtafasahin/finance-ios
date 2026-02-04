import Foundation
import SwiftData

enum PortfolioCalculator {
    static func holdings(assets: [AssetEntity], transactions: [TransactionEntity]) -> [HoldingSnapshot] {
        var txByAsset: [UUID: [TransactionEntity]] = [:]
        for tx in transactions {
            guard let asset = tx.asset else { continue }
            txByAsset[asset.id, default: []].append(tx)
        }

        return assets.map { asset in
            let txs = (txByAsset[asset.id] ?? []).sorted(by: { $0.date < $1.date })
            let computed = computePosition(transactions: txs)

            return HoldingSnapshot(
                assetId: asset.id,
                symbol: asset.symbol,
                name: asset.name,
                type: asset.type,
                currency: asset.currency,
                quantity: computed.quantity,
                averagePrice: computed.avgPrice,
                lastPrice: asset.lastPrice,
                lastPriceCurrency: asset.lastPriceCurrency,
                lastUpdatedAt: asset.lastPriceUpdatedAt
            )
        }
    }

    static func dashboard(holdings: [HoldingSnapshot], displayCurrency: CurrencyCode, usdTry: Decimal?) -> DashboardSnapshot {
        var totalValue: Decimal = 0
        var totalCost: Decimal = 0
        var lastUpdatedAt: Date? = nil

        for h in holdings {
            let cost = h.quantity * h.averagePrice
            let value = (h.lastPrice ?? 0) * h.quantity

            totalCost += convert(cost, from: h.currency, to: displayCurrency, usdTry: usdTry)

            let valueCurrency = h.lastPriceCurrency ?? h.currency
            totalValue += convert(value, from: valueCurrency, to: displayCurrency, usdTry: usdTry)

            if let t = h.lastUpdatedAt {
                if lastUpdatedAt == nil || t > lastUpdatedAt! {
                    lastUpdatedAt = t
                }
            }
        }

        let pl = totalValue - totalCost
        let plPct = totalCost == 0 ? 0 : (pl / totalCost)

        return DashboardSnapshot(
            totalValue: totalValue,
            totalCost: totalCost,
            totalProfitLoss: pl,
            totalProfitLossPct: plPct,
            lastUpdatedAt: lastUpdatedAt
        )
    }

    private static func computePosition(transactions: [TransactionEntity]) -> (quantity: Decimal, avgPrice: Decimal) {
        var quantity: Decimal = 0
        var totalCost: Decimal = 0

        for tx in transactions {
            switch tx.type {
            case .buy:
                quantity += tx.quantity
                totalCost += tx.quantity * tx.price + tx.fees
            case .sell:
                // Reduce quantity; keep avg cost simple.
                let sellQty = min(tx.quantity, quantity)
                if quantity > 0 {
                    let avg = (totalCost / quantity)
                    quantity -= sellQty
                    totalCost -= avg * sellQty
                }
            case .depositAdd:
                quantity += tx.quantity
                totalCost += tx.quantity * tx.price
            case .depositWithdraw:
                let wQty = min(tx.quantity, quantity)
                quantity -= wQty
                if quantity == 0 { totalCost = 0 }
            case .depositIncome:
                // Treat income as reducing cost basis.
                totalCost -= tx.quantity * tx.price
            }
        }

        let avg = quantity == 0 ? 0 : (totalCost / quantity)
        return (quantity, avg)
    }

    private static func convert(_ value: Decimal, from: CurrencyCode, to: CurrencyCode, usdTry: Decimal?) -> Decimal {
        if from == to { return value }
        guard let rate = usdTry, rate > 0 else { return value }

        // usdTry = 1 USD -> TRY
        switch (from, to) {
        case (.usd, .try):
            return value * rate
        case (.try, .usd):
            return value / rate
        default:
            return value
        }
    }
}
