import Foundation
import SwiftData

@Model
final class AppSettingsEntity {
    @Attribute(.unique) var id: UUID
    var displayCurrencyRaw: String

    init(id: UUID = UUID(), displayCurrency: CurrencyCode = .try) {
        self.id = id
        self.displayCurrencyRaw = displayCurrency.rawValue
    }

    var displayCurrency: CurrencyCode {
        get { CurrencyCode(rawValue: displayCurrencyRaw) ?? .try }
        set { displayCurrencyRaw = newValue.rawValue }
    }
}
