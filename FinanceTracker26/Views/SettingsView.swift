import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var settings: [AppSettingsEntity]
    @Query(filter: #Predicate<FXRateEntity> { $0.pair == "USDTRY" }) private var usdTryRates: [FXRateEntity]

    var body: some View {
        let current = settings.first
        let usdTry = usdTryRates.first?.rate

        Form {
            Section("Display") {
                Picker("Currency", selection: Binding(
                    get: { current?.displayCurrency ?? .try },
                    set: { newValue in
                        upsertDisplayCurrency(newValue)
                    }
                )) {
                    ForEach(CurrencyCode.allCases) { c in
                        Text(c.rawValue).tag(c)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("FX") {
                HStack {
                    Text("USD/TRY")
                    Spacer()
                    Text(usdTry.map { "\(NSDecimalNumber(decimal: $0))" } ?? "-")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                if let updatedAt = usdTryRates.first?.updatedAt {
                    Text("Updated: \(Formatters.dateTime(updatedAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }

    private func upsertDisplayCurrency(_ currency: CurrencyCode) {
        do {
            let descriptor = FetchDescriptor<AppSettingsEntity>()
            let existing = try modelContext.fetch(descriptor)
            if let s = existing.first {
                s.displayCurrency = currency
            } else {
                modelContext.insert(AppSettingsEntity(displayCurrency: currency))
            }
            try modelContext.save()
        } catch {
            // ignore
        }
    }
}
