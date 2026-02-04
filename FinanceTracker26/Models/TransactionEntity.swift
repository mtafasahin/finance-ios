import Foundation
import SwiftData

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case buy = "BUY"
    case sell = "SELL"
    case depositAdd = "DEPOSIT_ADD"
    case depositWithdraw = "DEPOSIT_WITHDRAW"
    case depositIncome = "DEPOSIT_INCOME"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        case .depositAdd: return "Deposit +"
        case .depositWithdraw: return "Deposit -"
        case .depositIncome: return "Deposit Income"
        }
    }
}

@Model
final class TransactionEntity {
    @Attribute(.unique) var id: UUID
    var typeRaw: String
    var quantity: Decimal
    var price: Decimal
    var fees: Decimal
    var date: Date
    var notes: String?

    @Relationship var asset: AssetEntity?

    init(
        id: UUID = UUID(),
        asset: AssetEntity,
        type: TransactionType,
        quantity: Decimal,
        price: Decimal,
        fees: Decimal = 0,
        date: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.asset = asset
        self.typeRaw = type.rawValue
        self.quantity = quantity
        self.price = price
        self.fees = fees
        self.date = date
        self.notes = notes
    }

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .buy }
        set { typeRaw = newValue.rawValue }
    }
}
