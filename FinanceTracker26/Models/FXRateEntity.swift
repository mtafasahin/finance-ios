import Foundation
import SwiftData

@Model
final class FXRateEntity {
    @Attribute(.unique) var id: UUID
    var pair: String // e.g. "USDTRY"
    var rate: Decimal
    var updatedAt: Date

    init(id: UUID = UUID(), pair: String, rate: Decimal, updatedAt: Date = Date()) {
        self.id = id
        self.pair = pair
        self.rate = rate
        self.updatedAt = updatedAt
    }
}
