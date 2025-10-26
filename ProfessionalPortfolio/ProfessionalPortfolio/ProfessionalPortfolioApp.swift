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
    // Authentication state manager - created after Firebase configuration
    @State private var authStateManager: AuthenticationStateManager?
    // Persistent authentication view model to prevent recreation
    @State private var authViewModel: AuthenticationViewModel?
    
    init() {
        // Configure Firebase using GoogleService-Info.plist
        configureFirebase()
        
        // Validate configuration after Firebase setup
        ConfigurationManager.shared.validateConfiguration()
        
        // Create auth state manager after Firebase is configured
        _authStateManager = State(initialValue: AuthenticationStateManager())
        
        // Create persistent auth view model
        _authViewModel = State(initialValue: AuthenticationViewModel(auth: FirebaseAuthenticationService()))
    }
    
    private func configureFirebase() {
        // Firebase will automatically look for GoogleService-Info.plist in the main bundle
        // This is the standard and recommended approach
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
            Group {
                if let manager = authStateManager, let viewModel = authViewModel {
                    if manager.isCheckingAuthState {
                        // Show loading while checking auth state
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground))
                    } else if manager.isAuthenticated {
                        // User is authenticated - show main app with tab system
                        PortfolioTabView()
                            .environment(\.authStateManager, manager)
                    } else {
                        // User is not authenticated - show authentication view with persistent ViewModel
                        AuthenticationView(viewModel: viewModel)
                            .onAppear {
                                // Clear sensitive data when returning to auth view
                                viewModel.clearSensitiveData()
                            }
                    }
                } else {
                    // Firebase/Manager not ready yet
                    ProgressView("Initializing...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                }
            }
            .environment(\.theme, DefaultTheme())
            // In any view, access the theme like this:
            // @Environment(\.theme) var theme
        }
        .modelContainer(sharedModelContainer)
    }
}
