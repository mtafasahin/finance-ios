import Foundation

struct FxRateProvider {
    private let client = NetworkClient()

    struct FrankfurterResponse: Decodable {
        let amount: Decimal
        let base: String
        let date: String
        let rates: [String: Decimal]
    }

    func fetchUSDTRY() async throws -> FXRateEntity {
        // https://api.frankfurter.app/latest?from=USD&to=TRY
        let url = URL(string: "https://api.frankfurter.app/latest?from=USD&to=TRY")!
        let resp = try await client.getJSON(url: url, as: FrankfurterResponse.self)
        guard let rate = resp.rates["TRY"] else { throw PriceProviderError.parseFailed }
        return FXRateEntity(pair: "USDTRY", rate: rate, updatedAt: Date())
    }
}
