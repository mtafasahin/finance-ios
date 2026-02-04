import Foundation

struct TefasProvider: PriceProvider {
    private let client = NetworkClient()

    func fetchQuote(for asset: AssetEntity) async throws -> PriceQuote {
        guard asset.type == .fund else { throw PriceProviderError.unsupported }
        let code = (asset.providerSymbol ?? asset.symbol).uppercased()

        // finance-api strategy: https://www.tefas.gov.tr/FonAnaliz.aspx?FonKod=CODE
        let primary = URL(string: "https://www.tefas.gov.tr/FonAnaliz.aspx?FonKod=\(code)")!
        do {
            let html = try await client.getString(url: primary, timeoutSeconds: 30)
            if let price = extractPrice(html: html) {
                return PriceQuote(symbol: code, price: price, currency: .try, updatedAt: Date())
            }
        } catch {
            // fall through
        }

        // finance-api fallback: https://www.tefas.gov.tr/FonKarsilastirma.aspx?FonKod=CODE
        let fallback = URL(string: "https://www.tefas.gov.tr/FonKarsilastirma.aspx?FonKod=\(code)")!
        let html = try await client.getString(url: fallback, timeoutSeconds: 30)
        guard let price = extractPrice(html: html) else { throw PriceProviderError.parseFailed }
        return PriceQuote(symbol: code, price: price, currency: .try, updatedAt: Date())
    }

    private func extractPrice(html: String) -> Decimal? {
        // Approximate finance-api 'main-indicators/top-list/li[1]/span'
        // Try to locate main-indicators block and capture first span numeric.
        if let price = extractFromMainIndicators(html: html) {
            return price
        }

        // Fallback: find tokens near "Son Fiyat" / "Birim Fiyat" / "Güncel"
        let keywords = ["Son Fiyat", "Birim Fiyat", "Güncel"]
        for key in keywords {
            if let price = extractNearKeyword(html: html, keyword: key) {
                return price
            }
        }

        // Last resort: first plausible decimal
        return DecimalParsing.extractFirstDecimal(from: html)
    }

    private func extractFromMainIndicators(html: String) -> Decimal? {
        // Very light regex: find main-indicators then first <span>NUMBER</span>
        let pattern = #"main-indicators[\s\S]*?<ul[^>]*class=\"top-list\"[\s\S]*?<li[\s\S]*?<span[^>]*>([^<]+)</span>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range) else { return nil }
        guard match.numberOfRanges >= 2, let r = Range(match.range(at: 1), in: html) else { return nil }
        return DecimalParsing.extractFirstDecimal(from: String(html[r]))
    }

    private func extractNearKeyword(html: String, keyword: String) -> Decimal? {
        // Capture some characters after keyword and parse first decimal.
        let escaped = NSRegularExpression.escapedPattern(for: keyword)
        let pattern = "\(escaped).{0,120}"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range) else { return nil }
        guard let r = Range(match.range, in: html) else { return nil }
        return DecimalParsing.extractFirstDecimal(from: String(html[r]))
    }
}
