import Foundation

struct HoldingSnapshot: Identifiable {
    var id: UUID { assetId }
    let assetId: UUID
    let symbol: String
    let name: String
    let type: AssetType
    let currency: CurrencyCode

    let quantity: Decimal
    let averagePrice: Decimal

    let lastPrice: Decimal?
    let lastPriceCurrency: CurrencyCode?
    let lastUpdatedAt: Date?
}

struct DashboardSnapshot {
    let totalValue: Decimal
    let totalCost: Decimal
    let totalProfitLoss: Decimal
    let totalProfitLossPct: Decimal
    let lastUpdatedAt: Date?
}
