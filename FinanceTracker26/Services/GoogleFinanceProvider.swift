import Foundation

struct GoogleFinanceProvider: PriceProvider {
    private let client = NetworkClient()

    func fetchQuote(for asset: AssetEntity) async throws -> PriceQuote {
        switch asset.type {
        case .stock:
            return try await fetchStock(symbol: asset.providerSymbol ?? asset.symbol, exchange: "IST")
        case .usStock:
            return try await fetchStock(symbol: asset.providerSymbol ?? asset.symbol, exchange: "NASDAQ")
        case .preciousMetals:
            return try await fetchPrecious(symbol: asset.providerSymbol ?? asset.symbol)
        default:
            throw PriceProviderError.unsupported
        }
    }

    private func fetchStock(symbol: String, exchange: String) async throws -> PriceQuote {
        let url = URL(string: "https://www.google.com/finance/quote/\(symbol):\(exchange)")!
        let html = try await client.getString(url: url)
        guard let price = extractGoogleFinancePrice(html: html) else { throw PriceProviderError.parseFailed }
        let currency: CurrencyCode = (exchange == "IST") ? .try : .usd
        return PriceQuote(symbol: symbol, price: price, currency: currency, updatedAt: Date())
    }

    private func fetchPrecious(symbol: String) async throws -> PriceQuote {
        let url: URL
        if symbol.contains(":") {
            url = URL(string: "https://www.google.com/finance/quote/\(symbol)")!
        } else {
            url = URL(string: "https://www.google.com/finance/quote/\(symbol):COMEX")!
        }

        let html = try await client.getString(url: url)
        guard let price = extractGoogleFinancePrice(html: html) else { throw PriceProviderError.parseFailed }
        return PriceQuote(symbol: symbol, price: price, currency: .usd, updatedAt: Date())
    }

    private func extractGoogleFinancePrice(html: String) -> Decimal? {
        // finance-api uses: //div[@class='YMlKec fxKbKc']
        let pattern = #"<div[^>]*class=\"YMlKec fxKbKc\"[^>]*>([^<]+)</div>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range) else { return nil }
        guard match.numberOfRanges >= 2, let r = Range(match.range(at: 1), in: html) else { return nil }
        let text = String(html[r])
        return DecimalParsing.extractFirstDecimal(from: text)
    }
}
