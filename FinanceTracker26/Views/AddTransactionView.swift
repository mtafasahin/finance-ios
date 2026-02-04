import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \AssetEntity.name) private var assets: [AssetEntity]

    @State private var selectedAssetId: UUID?
    @State private var type: TransactionType = .buy

    @State private var quantityText: String = ""
    @State private var priceText: String = ""
    @State private var feesText: String = ""

    @State private var date: Date = Date()
    @State private var notes: String = ""

    var body: some View {
        Form {
            Section("Transaction") {
                Picker("Asset", selection: $selectedAssetId) {
                    Text("Select...").tag(UUID?.none)
                    ForEach(assets) { a in
                        Text("\(a.symbol) — \(a.name)").tag(UUID?.some(a.id))
                    }
                }

                Picker("Type", selection: $type) {
                    ForEach(TransactionType.allCases) { t in
                        Text(t.title).tag(t)
                    }
                }

                TextField("Quantity", text: $quantityText)
                    .keyboardType(.decimalPad)

                TextField("Price", text: $priceText)
                    .keyboardType(.decimalPad)

                TextField("Fees", text: $feesText)
                    .keyboardType(.decimalPad)

                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])

                TextField("Notes (optional)", text: $notes, axis: .vertical)
            }

            if assets.isEmpty {
                Section {
                    Text("Add an asset first.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Add Transaction")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!canSave)
            }
        }
        .onAppear {
            if selectedAssetId == nil {
                selectedAssetId = assets.first?.id
            }
        }
    }

    private var canSave: Bool {
        guard selectedAssetId != nil else { return false }
        guard DecimalParsing.parseFlexible(quantityText) != nil else { return false }
        guard DecimalParsing.parseFlexible(priceText) != nil else { return false }
        if !feesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            guard DecimalParsing.parseFlexible(feesText) != nil else { return false }
        }
        return true
    }

    private func save() {
        guard let assetId = selectedAssetId else { return }
        guard let asset = assets.first(where: { $0.id == assetId }) else { return }

        let qty = DecimalParsing.parseFlexible(quantityText) ?? 0
        let price = DecimalParsing.parseFlexible(priceText) ?? 0
        let fees = DecimalParsing.parseFlexible(feesText) ?? 0

        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let tx = TransactionEntity(
            asset: asset,
            type: type,
            quantity: qty,
            price: price,
            fees: fees,
            date: date,
            notes: cleanNotes.isEmpty ? nil : cleanNotes
        )

        modelContext.insert(tx)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // ignore
        }
    }
}
