//
//  ProfessionalPortfolioApp.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/20/25.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth

@main
struct ProfessionalPortfolioApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        
        WindowGroup {
            ContentView()
                .environment(\.theme, DefaultTheme())
            // In any view, access the theme like this:
            // @Environment(\.theme) var theme
        }
        .modelContainer(sharedModelContainer)
    }
}
