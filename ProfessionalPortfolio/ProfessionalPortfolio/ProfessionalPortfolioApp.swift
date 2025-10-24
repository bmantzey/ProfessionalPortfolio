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
        // Validate configuration before Firebase setup
        ConfigurationManager.shared.validateConfiguration()
        configureFirebaseProgrammatically()
    }
    
    private func configureFirebaseProgrammatically() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else {
            // Fallback to programmatic configuration if no plist file
            let options = FirebaseOptions(
                googleAppID: ConfigurationManager.shared.value(for: "GOOGLE_APP_ID") ?? "",
                gcmSenderID: ConfigurationManager.shared.value(for: "GOOGLE_GCM_SENDER_ID") ?? ""
            )
            options.apiKey = ConfigurationManager.shared.googleAPIKey
            options.clientID = ConfigurationManager.shared.googleClientID
            options.projectID = ConfigurationManager.shared.firebaseProjectID
            
            FirebaseApp.configure(options: options)
            return
        }
        
        // Use plist file if available
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
