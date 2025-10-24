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
            fatalError("Google API Key not found in configuration. Please check your build settings.")
        }
        return key
    }
    
    /// Google Client ID for authentication
    var googleClientID: String {
        guard let clientID = value(for: "GOOGLE_CLIENT_ID"), !clientID.isEmpty else {
            fatalError("Google Client ID not found in configuration. Please check your build settings.")
        }
        return clientID
    }
    
    /// Firebase Project ID
    var firebaseProjectID: String {
        guard let projectID = value(for: "FIREBASE_PROJECT_ID"), !projectID.isEmpty else {
            fatalError("Firebase Project ID not found in configuration. Please check your build settings.")
        }
        return projectID
    }
    
    /// Validates that all required configuration values are present
    func validateConfiguration() {
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