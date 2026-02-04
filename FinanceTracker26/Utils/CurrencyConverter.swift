import Foundation

enum CurrencyConverter {
    static func convert(_ value: Decimal, from: CurrencyCode, to: CurrencyCode, usdTry: Decimal?) -> Decimal {
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
