//
//  ConfigurationManager.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/24/25.
//

import Foundation
import Firebase

struct ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private init() {}
    
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
    
    /// Validates that Firebase configuration is properly loaded
    func validateConfiguration() {
        if shouldUseMockConfiguration {
            if isRunningTests {
                print("🧪 Running in test mode - Firebase configuration validation skipped")
            } else {
                print("🔍 Running in preview mode - Firebase configuration validation skipped")
            }
            return
        }
        
        // Validate Firebase configuration exists
        guard let app = FirebaseApp.app() else {
            fatalError("❌ Firebase configuration not found. Make sure GoogleService-Info.plist is added to your project.")
        }
        
        // FirebaseOptions is not optional, so we can access it directly
        let options = app.options
        print("✅ Firebase configuration is valid for project: \(options.projectID ?? "Unknown")")
    }
}