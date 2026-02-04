import Foundation
import SwiftData

@Model
final class AssetEntity {
    @Attribute(.unique) var id: UUID
    var symbol: String
    var name: String
    var typeRaw: Int
    var currencyRaw: String

    // Cached last price
    var lastPrice: Decimal?
    var lastPriceCurrencyRaw: String?
    var lastPriceUpdatedAt: Date?

    // Optional metadata for providers
    var providerSymbol: String?
    var providerHint: String?

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        type: AssetType,
        currency: CurrencyCode,
        providerSymbol: String? = nil,
        providerHint: String? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.typeRaw = type.rawValue
        self.currencyRaw = currency.rawValue
        self.providerSymbol = providerSymbol
        self.providerHint = providerHint
    }

    var type: AssetType {
        get { AssetType(rawValue: typeRaw) ?? .stock }
        set { typeRaw = newValue.rawValue }
    }

    var currency: CurrencyCode {
        get { CurrencyCode(rawValue: currencyRaw) ?? .try }
        set { currencyRaw = newValue.rawValue }
    }

    var lastPriceCurrency: CurrencyCode? {
        get {
            guard let raw = lastPriceCurrencyRaw else { return nil }
            return CurrencyCode(rawValue: raw)
        }
        set {
            lastPriceCurrencyRaw = newValue?.rawValue
        }
    }
}
