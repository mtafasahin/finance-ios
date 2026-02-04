import Foundation
import Combine
import SwiftUI
import SwiftData

final class PriceRefreshEngine: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var lastGlobalRefreshAt: Date?

    private var task: Task<Void, Never>?

    private let google = GoogleFinanceProvider()
    private let tefas = TefasProvider()
    private let gecko = CoinGeckoProvider()
    private let fx = FxRateProvider()

    @MainActor
    func start(modelContext: ModelContext, intervalSeconds: TimeInterval = 15) {
        stop()
        isRunning = true

        task = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    try await self.refreshAll(modelContext: modelContext)
                } catch {
                    // Silent for now; UI continues showing cached values.
                }
                try? await Task.sleep(for: .seconds(intervalSeconds))
            }
        }
    }

    @MainActor
    func stop() {
        task?.cancel()
        task = nil
        isRunning = false
    }

    @MainActor
    func refreshOnce(modelContext: ModelContext) async {
        do {
            try await refreshAll(modelContext: modelContext)
        } catch {
            // no-op
        }
    }

    @MainActor
    private func refreshAll(modelContext: ModelContext) async throws {
        // Fetch all assets from local store and update their cached price.
        let descriptor = FetchDescriptor<AssetEntity>()
        let assets = try modelContext.fetch(descriptor)

        for asset in assets {
            do {
                let quote = try await fetchQuote(for: asset)
                asset.lastPrice = quote.price
                asset.lastPriceCurrency = quote.currency
                asset.lastPriceUpdatedAt = quote.updatedAt
            } catch {
                // Keep existing cached price.
            }
        }

        // Refresh USDTRY rate
        do {
            let newRate = try await fx.fetchUSDTRY()
            // Upsert by pair
            let rateFetch = FetchDescriptor<FXRateEntity>(predicate: #Predicate { $0.pair == "USDTRY" })
            if let existing = try modelContext.fetch(rateFetch).first {
                existing.rate = newRate.rate
                existing.updatedAt = newRate.updatedAt
            } else {
                modelContext.insert(newRate)
            }
        } catch {
            // ignore
        }

        try modelContext.save()
        lastGlobalRefreshAt = Date()
    }

    private func fetchQuote(for asset: AssetEntity) async throws -> PriceQuote {
        switch asset.type {
        case .stock, .usStock, .preciousMetals:
            return try await google.fetchQuote(for: asset)
        case .fund:
            return try await tefas.fetchQuote(for: asset)
        case .crypto:
            return try await gecko.fetchQuote(for: asset)
        case .fixedDeposit:
            // Fixed deposits can be treated as stable (price 1) in its own currency.
            return PriceQuote(symbol: asset.symbol, price: 1, currency: asset.currency, updatedAt: Date())
        }
    }
}
