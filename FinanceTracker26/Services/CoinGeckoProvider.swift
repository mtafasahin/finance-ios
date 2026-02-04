import Foundation

struct CoinGeckoProvider: PriceProvider {
    private let client = NetworkClient()

    // Minimal built-in mapping (expandable).
    private func coinId(forSymbol symbol: String) -> String? {
        switch symbol.uppercased() {
        case "BTC": return "bitcoin"
        case "ETH": return "ethereum"
        default: return nil
        }
    }

    struct Response: Decodable {
        let usd: Decimal?
        let last_updated_at: Int?
    }

    func fetchQuote(for asset: AssetEntity) async throws -> PriceQuote {
        guard asset.type == .crypto else { throw PriceProviderError.unsupported }
        let symbol = asset.providerSymbol ?? asset.symbol
        guard let id = coinId(forSymbol: symbol) else { throw PriceProviderError.unsupported }

        let url = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=\(id)&vs_currencies=usd&include_last_updated_at=true")!
        let raw = try await client.getJSON(url: url, as: [String: Response].self)
        guard let item = raw[id], let price = item.usd else { throw PriceProviderError.parseFailed }
        let updatedAt: Date
        if let unix = item.last_updated_at {
            updatedAt = Date(timeIntervalSince1970: TimeInterval(unix))
        } else {
            updatedAt = Date()
        }
        return PriceQuote(symbol: symbol, price: price, currency: .usd, updatedAt: updatedAt)
    }
}
