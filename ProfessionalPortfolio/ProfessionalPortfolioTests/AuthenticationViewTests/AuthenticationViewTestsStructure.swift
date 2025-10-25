//
//  AuthenticationViewTestsStructure.swift
//  ProfessionalPortfolioTests
//
//  Created by Brandon Mantzey on 10/25/25.
//

import Testing
import Foundation

// MARK: - Enhanced Mock Authentication Service

/// An advanced mock authentication service with realistic behaviors and comprehensive error simulation
class AdvancedMockAuthenticationService: AuthenticationService {
    
    // MARK: - Configuration Properties
    var shouldSucceedSignIn: Bool = true
    var shouldSucceedSignUp: Bool = true
    var shouldThrowError: Bool = false
    var simulatedError: Error = TestAuthenticationError.invalidCredentials
    var simulatedNetworkDelay: TimeInterval = 0.1
    var callHistory: [AuthCall] = []
    
    // MARK: - State Tracking
    enum AuthCall {
        case signIn(email: String, password: String)
        case signUp(email: String, password: String)
    }
    
    // MARK: - Special Behaviors
    private let failingPasswords = ["wrong", "fail"]
    private let existingEmails = ["existing@example.com", "taken@test.com"]
    private let weakPasswords = ["weak", "123", "password"]
    
    // MARK: - AuthenticationService Implementation
    
    func signIn(email: String, password: String) async throws -> Bool {
        callHistory.append(.signIn(email: email, password: password))
        
        // Simulate network delay
        if simulatedNetworkDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(simulatedNetworkDelay * 1_000_000_000))
        }
        
        // Handle configured errors
        if shouldThrowError {
            throw simulatedError
        }
        
        // Handle specific failure scenarios
        if failingPasswords.contains(password) {
            return false
        }
        
        return shouldSucceedSignIn
    }
    
    func signUp(email: String, password: String) async throws -> Bool {
        callHistory.append(.signUp(email: email, password: password))
        
        // Simulate network delay
        if simulatedNetworkDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(simulatedNetworkDelay * 1_000_000_000))
        }
        
        // Handle configured errors
        if shouldThrowError {
            throw simulatedError
        }
        
        // Handle specific failure scenarios
        if existingEmails.contains(email) {
            return false
        }
        
        if weakPasswords.contains(password) {
            throw TestAuthenticationError.weakPassword
        }
        
        return shouldSucceedSignUp
    }
    
    // MARK: - Test Utilities
    
    func reset() {
        shouldSucceedSignIn = true
        shouldSucceedSignUp = true
        shouldThrowError = false
        simulatedError = TestAuthenticationError.invalidCredentials
        simulatedNetworkDelay = 0.1
        callHistory.removeAll()
    }
    
    func lastCall() -> AuthCall? {
        return callHistory.last
    }
    
    func callCount() -> Int {
        return callHistory.count
    }
}

// MARK: - Test Authentication Errors

/// Test-specific authentication errors that won't conflict with production code
enum TestAuthenticationError: LocalizedError, Error {
    case invalidCredentials
    case networkError
    case serverError
    case weakPassword
    case emailAlreadyInUse
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials. Please try again."
        case .networkError:
            return "Network error occurred."
        case .serverError:
            return "Server error occurred."
        case .weakPassword:
            return "Password is too weak."
        case .emailAlreadyInUse:
            return "Email is already in use."
        }
    }
}

// MARK: - Test Utilities and Factories

struct AuthenticationTestFactory {
    
    static func createViewModel(mockService: AdvancedMockAuthenticationService? = nil) -> AuthenticationViewModel {
        let service = mockService ?? AdvancedMockAuthenticationService()
        return AuthenticationViewModel(auth: service)
    }
    
    static func createMockService(
        shouldSucceedSignIn: Bool = true,
        shouldSucceedSignUp: Bool = true,
        networkDelay: TimeInterval = 0.05
    ) -> AdvancedMockAuthenticationService {
        let mock = AdvancedMockAuthenticationService()
        mock.shouldSucceedSignIn = shouldSucceedSignIn
        mock.shouldSucceedSignUp = shouldSucceedSignUp
        mock.simulatedNetworkDelay = networkDelay
        return mock
    }
}

// MARK: - Test Data Providers

struct TestEmailData {
    static let validEmails = [
        "user@domain.com",
        "test.email@example.org",
        "user+tag@domain.co.uk",
        "user_name@domain-name.com",
        "123@domain.com",
        "user@123domain.com",
        "a@b.co"
    ]
    
    static let invalidEmails = [
        ("", "empty email"),
        ("   ", "whitespace only"),
        ("plaintext", "no @ symbol"),
        ("@domain.com", "no local part"),
        ("user@", "no domain"),
        ("user@domain", "no TLD"),
        ("user.domain.com", "no @ symbol"),
        ("user@@domain.com", "double @"),
        ("user@.com", "domain starts with dot"),
        ("user@domain.", "domain ends with dot"),
        ("user@domain.c", "TLD too short"),
        ("user name@domain.com", "space in local part")
    ]
    
    static let weakPasswords = [
        ("weak", "too short, no requirements"),
        ("password", "no uppercase, number, or special char"),
        ("PASSWORD", "no lowercase, number, or special char"),
        ("Password", "no number or special char"),
        ("Password123", "no special char"),
        ("Pass1!", "too short (6 chars)")
    ]
    
    static let strongPasswords = [
        "StrongP@ss123",
        "MySecure123!",
        "Test#Password1",
        "Valid@Pass456"
    ]
}
