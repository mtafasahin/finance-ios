import SwiftUI
import SwiftData

struct AssetsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \AssetEntity.name) private var assets: [AssetEntity]
    @Query(sort: \TransactionEntity.date, order: .reverse) private var transactions: [TransactionEntity]

    @State private var showAdd = false

    var body: some View {
        List {
            Section {
                ForEach(assets) { asset in
                    NavigationLink {
                        AssetDetailView(asset: asset)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(asset.symbol).font(.headline)
                                Spacer()
                                Text(asset.type.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(asset.name).font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteAssets)

                if assets.isEmpty {
                    Text("No assets yet.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Assets")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Label("Add Asset", systemImage: "plus")
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                AddAssetView()
            }
        }
    }

    private func deleteAssets(at offsets: IndexSet) {
        let toDelete = offsets.map { assets[$0] }

        // Delete dependent transactions first to avoid orphaned references.
        for asset in toDelete {
            let related = transactions.filter { $0.asset?.id == asset.id }
            for tx in related {
                modelContext.delete(tx)
            }
            modelContext.delete(asset)
        }

        do {
            try modelContext.save()
        } catch {
            // ignore
        }
    }
}

private struct AssetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State var asset: AssetEntity

    @State private var symbol: String = ""
    @State private var name: String = ""
    @State private var type: AssetType = .stock
    @State private var currency: CurrencyCode = .try

    @State private var providerSymbol: String = ""
    @State private var providerHint: String = ""

    init(asset: AssetEntity) {
        _asset = State(initialValue: asset)
    }

    var body: some View {
        Form {
            Section("Asset") {
                TextField("Symbol", text: $symbol)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                TextField("Name", text: $name)

                Picker("Type", selection: $type) {
                    ForEach(AssetType.allCases) { t in
                        Text(t.title).tag(t)
                    }
                }

                Picker("Currency", selection: $currency) {
                    ForEach(CurrencyCode.allCases) { c in
                        Text(c.rawValue).tag(c)
                    }
                }
            }

            Section("Provider") {
                TextField("Provider Symbol", text: $providerSymbol)
                    .autocorrectionDisabled()
                TextField("Provider Hint", text: $providerHint)
                    .autocorrectionDisabled()
            }

            Section {
                Button(role: .destructive) {
                    modelContext.delete(asset)
                    do { try modelContext.save() } catch { }
                    dismiss()
                } label: {
                    Text("Delete Asset")
                }
            }
        }
        .navigationTitle("Asset")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
            }
        }
        .onAppear {
            symbol = asset.symbol
            name = asset.name
            type = asset.type
            currency = asset.currency
            providerSymbol = asset.providerSymbol ?? ""
            providerHint = asset.providerHint ?? ""
        }
    }

    private func save() {
        asset.symbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        asset.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        asset.type = type
        asset.currency = currency

        let ps = providerSymbol.trimmingCharacters(in: .whitespacesAndNewlines)
        let ph = providerHint.trimmingCharacters(in: .whitespacesAndNewlines)
        asset.providerSymbol = ps.isEmpty ? nil : ps
        asset.providerHint = ph.isEmpty ? nil : ph

        do {
            try modelContext.save()
        } catch {
            // ignore
        }
    }
}
