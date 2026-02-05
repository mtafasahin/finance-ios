import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TransactionEntity.date, order: .reverse) private var transactions: [TransactionEntity]
    @Query(sort: \AssetEntity.name) private var assets: [AssetEntity]

    @State private var showAdd = false
    @State private var showFilters = false

    @State private var selectedAssetId: UUID?
    @State private var dateFilter: DateFilter = .all
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()

    var body: some View {
        let filtered = filteredTransactions()

        List {
            if hasActiveFilters {
                Section {
                    ActiveFiltersRow(
                        assetName: selectedAssetName,
                        dateLabel: dateFilterLabel,
                        onClear: clearFilters
                    )
                }
            }

            Section {
                ForEach(filtered) { tx in
                    NavigationLink {
                        TransactionEditView(transaction: tx)
                    } label: {
                        TransactionRow(tx: tx)
                    }
                }
                .onDelete(perform: deleteTransactions)

                if filtered.isEmpty {
                    Text(hasActiveFilters ? "No transactions match the filters." : "No transactions yet.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Transactions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFilters = true
                } label: {
                    Label("Filter", systemImage: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                AddTransactionView()
            }
        }
        .sheet(isPresented: $showFilters) {
            NavigationStack {
                TransactionFiltersView(
                    assets: assets,
                    selectedAssetId: $selectedAssetId,
                    dateFilter: $dateFilter,
                    customStartDate: $customStartDate,
                    customEndDate: $customEndDate
                )
            }
        }
    }

    private func deleteTransactions(at offsets: IndexSet) {
        let filtered = filteredTransactions()
        for index in offsets {
            modelContext.delete(filtered[index])
        }
        do {
            try modelContext.save()
        } catch {
            // ignore
        }
    }

    private var hasActiveFilters: Bool {
        selectedAssetId != nil || dateFilter != .all
    }

    private var selectedAssetName: String? {
        guard let id = selectedAssetId else { return nil }
        return assets.first(where: { $0.id == id })?.name
    }

    private var dateFilterLabel: String? {
        switch dateFilter {
        case .all:
            return nil
        case .last7:
            return "Last 7 days"
        case .last30:
            return "Last 30 days"
        case .custom:
            return "Custom: \(Formatters.dateTime(customStartDate)) → \(Formatters.dateTime(customEndDate))"
        }
    }

    private func clearFilters() {
        selectedAssetId = nil
        dateFilter = .all
    }

    private func filteredTransactions() -> [TransactionEntity] {
        var result = transactions

        if let assetId = selectedAssetId {
            result = result.filter { $0.asset?.id == assetId }
        }

        let now = Date()
        switch dateFilter {
        case .all:
            break
        case .last7:
            let start = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
            result = result.filter { $0.date >= start && $0.date <= now }
        case .last30:
            let start = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
            result = result.filter { $0.date >= start && $0.date <= now }
        case .custom:
            let start = min(customStartDate, customEndDate)
            let end = max(customStartDate, customEndDate)
            result = result.filter { $0.date >= start && $0.date <= end }
        }

        return result
    }
}

private enum DateFilter: String, CaseIterable, Identifiable {
    case all
    case last7
    case last30
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .last7: return "Last 7 days"
        case .last30: return "Last 30 days"
        case .custom: return "Custom"
        }
    }
}

private struct TransactionFiltersView: View {
    @Environment(\.dismiss) private var dismiss

    let assets: [AssetEntity]
    @Binding var selectedAssetId: UUID?
    @Binding var dateFilter: DateFilter
    @Binding var customStartDate: Date
    @Binding var customEndDate: Date

    var body: some View {
        Form {
            Section("Asset") {
                Picker("Asset", selection: $selectedAssetId) {
                    Text("All").tag(UUID?.none)
                    ForEach(assets) { a in
                        Text("\(a.symbol) — \(a.name)").tag(UUID?.some(a.id))
                    }
                }
            }

            Section("Date") {
                Picker("Range", selection: $dateFilter) {
                    ForEach(DateFilter.allCases) { f in
                        Text(f.title).tag(f)
                    }
                }

                if dateFilter == .custom {
                    DatePicker("Start", selection: $customStartDate, displayedComponents: [.date])
                    DatePicker("End", selection: $customEndDate, displayedComponents: [.date])
                }
            }
        }
        .navigationTitle("Filters")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }
}

private struct ActiveFiltersRow: View {
    let assetName: String?
    let dateLabel: String?
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    .font(.headline)
                Spacer()
                Button("Clear") { onClear() }
            }

            if let assetName {
                Text("Asset: \(assetName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let dateLabel {
                Text("Date: \(dateLabel)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct TransactionRow: View {
    let tx: TransactionEntity

    var body: some View {
        let symbol = tx.asset?.symbol ?? "-"

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(tx.type.title).font(.headline)
                Spacer()
                Text(symbol).font(.subheadline).foregroundStyle(.secondary)
            }

            HStack {
                Text("Qty: \(NSDecimalNumber(decimal: tx.quantity))")
                Spacer()
                Text("Price: \(NSDecimalNumber(decimal: tx.price))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(Formatters.dateTime(tx.date))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
