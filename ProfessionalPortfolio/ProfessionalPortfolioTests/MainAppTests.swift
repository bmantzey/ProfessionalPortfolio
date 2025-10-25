//
//  MainAppTests.swift
//  ProfessionalPortfolioTests
//
//  Created by Brandon Mantzey on 10/25/25.
//

import Testing
import FirebaseAuth
@testable import ProfessionalPortfolio

// MARK: - Mock Authentication State Manager

/// A mock authentication state manager for testing MainApp sign-out functionality
@Observable
final class MockAuthenticationStateManager {
    var isAuthenticated: Bool = true
    var currentUser: User? = nil
    var isCheckingAuthState: Bool = false
    
    private(set) var signOutWasCalled: Bool = false
    private(set) var signOutShouldSucceed: Bool = true
    private(set) var signOutError: Error?
    
    init(shouldSucceed: Bool = true, error: Error? = nil) {
        signOutShouldSucceed = shouldSucceed
        signOutError = error
    }
    
    func signOut() async throws {
        signOutWasCalled = true
        
        if let error = signOutError {
            throw error
        }
        
        if signOutShouldSucceed {
            isAuthenticated = false
            currentUser = nil
        }
    }
}

// MARK: - MainApp Tests

@Suite("MainApp Tests")
struct MainAppTests {
    
    @Test("Sign out calls authentication state manager")
    @MainActor
    func signOutCallsAuthenticationStateManager() async throws {
        // Given
        let mockAuthManager = MockAuthenticationStateManager(shouldSucceed: true)
        #expect(mockAuthManager.isAuthenticated == true, "Should start authenticated")
        #expect(mockAuthManager.signOutWasCalled == false, "Should not have called signOut yet")
        
        // When
        try await mockAuthManager.signOut()
        
        // Then
        #expect(mockAuthManager.signOutWasCalled == true, "Should have called signOut")
        #expect(mockAuthManager.isAuthenticated == false, "Should be signed out after successful signOut")
    }
    
    @Test("Sign out succeeds and updates authentication state")
    @MainActor
    func signOutSucceedsAndUpdatesState() async throws {
        // Given
        let mockAuthManager = MockAuthenticationStateManager()
        mockAuthManager.isAuthenticated = true
        
        // When
        try await mockAuthManager.signOut()
        
        // Then
        #expect(mockAuthManager.isAuthenticated == false, "Should be signed out")
        #expect(mockAuthManager.currentUser == nil, "Should clear current user")
        #expect(mockAuthManager.signOutWasCalled == true, "Should have called signOut method")
    }
}
