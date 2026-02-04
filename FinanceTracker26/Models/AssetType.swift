import Foundation

enum AssetType: Int, Codable, CaseIterable, Identifiable {
    case stock = 0
    case usStock = 1
    case preciousMetals = 2
    case fund = 4
    case fixedDeposit = 5
    case crypto = 6

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .stock: return "BIST 100"
        case .usStock: return "US Stocks"
        case .preciousMetals: return "Precious Metals"
        case .fund: return "Funds"
        case .fixedDeposit: return "Fixed Deposit"
        case .crypto: return "Crypto"
        }
    }

    var defaultCurrency: CurrencyCode {
        switch self {
        case .stock, .fund, .fixedDeposit: return .try
        case .usStock, .preciousMetals, .crypto: return .usd
        }
    }
}

enum CurrencyCode: String, Codable, CaseIterable, Identifiable {
    case `try` = "TRY"
    case usd = "USD"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .try: return "₺"
        case .usd: return "$"
        }
    }
}
