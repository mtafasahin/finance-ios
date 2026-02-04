import Foundation

struct PriceQuote {
    let symbol: String
    let price: Decimal
    let currency: CurrencyCode
    let updatedAt: Date
}

enum PriceProviderError: Error {
    case unsupported
    case parseFailed
}

protocol PriceProvider {
    func fetchQuote(for asset: AssetEntity) async throws -> PriceQuote
}
