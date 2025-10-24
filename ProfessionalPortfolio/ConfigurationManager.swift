//
//  ConfigurationManager.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/24/25.
//

import Foundation

struct ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private init() {}
    
    /// Retrieves configuration values from the app bundle's Info.plist
    func value(for key: String) -> String? {
        return Bundle.main.infoDictionary?[key] as? String
    }
    
    /// Google API Key for Firebase services
    var googleAPIKey: String {
        guard let key = value(for: "GOOGLE_API_KEY"), !key.isEmpty else {
            if shouldUseMockConfiguration {
                return "mock-google-api-key"
            }
            fatalError("Google API Key not found in configuration. Please check your build settings.")
        }
        return key
    }
    
    /// Google Client ID for authentication
    var googleClientID: String {
        guard let clientID = value(for: "GOOGLE_CLIENT_ID"), !clientID.isEmpty else {
            if shouldUseMockConfiguration {
                return "mock-google-client-id"
            }
            fatalError("Google Client ID not found in configuration. Please check your build settings.")
        }
        return clientID
    }
    
    /// Firebase Project ID
    var firebaseProjectID: String {
        guard let projectID = value(for: "FIREBASE_PROJECT_ID"), !projectID.isEmpty else {
            if shouldUseMockConfiguration {
                return "mock-firebase-project-id"
            }
            fatalError("Firebase Project ID not found in configuration. Please check your build settings.")
        }
        return projectID
    }
    
    /// Checks if the code is running in a SwiftUI preview or test environment
    private var isRunningInPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    /// Checks if the code is running in a test environment
    private var isRunningTests: Bool {
        return NSClassFromString("XCTestCase") != nil
    }
    
    /// Checks if we should use mock configuration values
    private var shouldUseMockConfiguration: Bool {
        return isRunningInPreview || isRunningTests
    }
    
    /// Validates that all required configuration values are present
    func validateConfiguration() {
        if shouldUseMockConfiguration {
            if isRunningTests {
                print("🧪 Running in test mode - using mock configuration values")
            } else {
                print("🔍 Running in preview mode - using mock configuration values")
            }
            return
        }
        
        _ = googleAPIKey
        _ = googleClientID
        _ = firebaseProjectID
        print("✅ All configuration values are valid")
    }
}

// MARK: - Bundle Extension for easier access
extension Bundle {
    var googleAPIKey: String {
        return ConfigurationManager.shared.googleAPIKey
    }
    
    var googleClientID: String {
        return ConfigurationManager.shared.googleClientID
    }
    
    var firebaseProjectID: String {
        return ConfigurationManager.shared.firebaseProjectID
    }
}