import SwiftUI
import SwiftData

struct TransactionEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \AssetEntity.name) private var assets: [AssetEntity]

    let transaction: TransactionEntity

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

            Section {
                Button(role: .destructive) {
                    delete()
                } label: {
                    Text("Delete Transaction")
                }
            }
        }
        .navigationTitle("Edit Transaction")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            selectedAssetId = transaction.asset?.id
            type = transaction.type
            quantityText = string(transaction.quantity)
            priceText = string(transaction.price)
            feesText = transaction.fees == 0 ? "" : string(transaction.fees)
            date = transaction.date
            notes = transaction.notes ?? ""
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
        guard let assetId = selectedAssetId,
              let asset = assets.first(where: { $0.id == assetId })
        else { return }

        transaction.asset = asset
        transaction.type = type
        transaction.quantity = DecimalParsing.parseFlexible(quantityText) ?? transaction.quantity
        transaction.price = DecimalParsing.parseFlexible(priceText) ?? transaction.price
        transaction.fees = DecimalParsing.parseFlexible(feesText) ?? 0
        transaction.date = date

        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        transaction.notes = cleanNotes.isEmpty ? nil : cleanNotes

        do {
            try modelContext.save()
            dismiss()
        } catch {
            // ignore
        }
    }

    private func delete() {
        modelContext.delete(transaction)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // ignore
        }
    }

    private func string(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }
}
