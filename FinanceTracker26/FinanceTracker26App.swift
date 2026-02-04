//
//  FinanceTracker26App.swift
//  FinanceTracker26
//
//  Created by Mustafa Sahin on 2/4/26.
//

import SwiftUI
import SwiftData

@main
struct FinanceTracker26App: App {
    private var modelContainer: ModelContainer = {
        do {
            let schema = Schema([
                AssetEntity.self,
                TransactionEntity.self,
                AppSettingsEntity.self,
                FXRateEntity.self
            ])

            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
