import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TransactionEntity.date, order: .reverse) private var transactions: [TransactionEntity]

    @State private var showAdd = false

    var body: some View {
        List {
            Section {
                ForEach(transactions) { tx in
                    TransactionRow(tx: tx)
                }
                .onDelete(perform: deleteTransactions)

                if transactions.isEmpty {
                    Text("No transactions yet.")
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
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                AddTransactionView()
            }
        }
    }

    private func deleteTransactions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(transactions[index])
        }
        do {
            try modelContext.save()
        } catch {
            // ignore
        }
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
