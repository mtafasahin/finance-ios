import SwiftUI
import SwiftData

struct AddAssetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var type: AssetType = .stock
    @State private var symbol: String = ""
    @State private var name: String = ""
    @State private var currency: CurrencyCode = .try

    @State private var providerSymbol: String = ""
    @State private var providerHint: String = ""

    var body: some View {
        Form {
            Section("Asset") {
                Picker("Type", selection: $type) {
                    ForEach(AssetType.allCases) { t in
                        Text(t.title).tag(t)
                    }
                }

                TextField("Symbol", text: $symbol)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                TextField("Name", text: $name)

                Picker("Currency", selection: $currency) {
                    ForEach(CurrencyCode.allCases) { c in
                        Text(c.rawValue).tag(c)
                    }
                }
            }

            Section("Provider (optional)") {
                TextField("Provider Symbol", text: $providerSymbol)
                    .autocorrectionDisabled()
                TextField("Provider Hint", text: $providerHint)
                    .autocorrectionDisabled()
            }
        }
        .navigationTitle("Add Asset")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onChange(of: type) {
            // default currency per type (user can override)
            currency = type.defaultCurrency
        }
    }

    private func save() {
        let cleanSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        let ps = providerSymbol.trimmingCharacters(in: .whitespacesAndNewlines)
        let ph = providerHint.trimmingCharacters(in: .whitespacesAndNewlines)

        let asset = AssetEntity(
            symbol: cleanSymbol,
            name: cleanName,
            type: type,
            currency: currency,
            providerSymbol: ps.isEmpty ? nil : ps,
            providerHint: ph.isEmpty ? nil : ph
        )
        modelContext.insert(asset)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            // ignore
        }
    }
}
