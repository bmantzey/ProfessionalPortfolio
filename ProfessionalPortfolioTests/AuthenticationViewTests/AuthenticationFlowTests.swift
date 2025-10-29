//
//  AuthenticationFlowTests.swift
//  ProfessionalPortfolioTests
//
//  Created by Brandon Mantzey on 10/25/25.
//

import Testing

@Suite("Authentication Flow")
struct AuthenticationFlowTests {
    
    @Test("Empty credentials prevent sign-in with appropriate error")
    @MainActor
    func emptyCredentialsPreventSignIn() async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        #expect(viewModel.email.isEmpty)
        #expect(viewModel.password.isEmpty)
        
        // When
        await viewModel.signIn()
        
        // Then
        #expect(viewModel.isSigningIn == false, "Should not be signing in after empty validation")
        #expect(viewModel.errorMessage != nil, "Should show validation error")
        #expect(viewModel.errorMessage?.contains("email and password") == true, "Should mention both fields")
        #expect(viewModel.isAuthenticated == false, "Should not be authenticated")
    }
    
    @Test("Malformed email prevents sign-in with validation error")
    @MainActor
    func malformedEmailPreventsSignIn() async throws {
        // Given
        let mockAuth = AuthenticationTestFactory.createMockService(shouldSucceedSignIn: false)
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.email = "not-an-email"
        viewModel.password = "password123"
        
        // When
        await viewModel.signIn()
        
        // Then
        #expect(viewModel.isAuthenticated == false, "Should not be authenticated with invalid email")
        #expect(viewModel.errorMessage != nil, "Should show error message")
        #expect(viewModel.errorMessage?.contains("valid email") == true, "Should mention email validation")
        #expect(viewModel.password.isEmpty, "Password should be cleared when email is invalid")
    }
    
    @Test("Successful sign-in updates authentication state")
    @MainActor
    func successfulSignInUpdatesAuthenticationState() async throws {
        // Given
        let mockAuth = AuthenticationTestFactory.createMockService(shouldSucceedSignIn: true, networkDelay: 0.05)
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        
        // When
        await viewModel.signIn()
        
        // Then
        #expect(viewModel.isAuthenticated == true, "Should be authenticated after success")
        #expect(viewModel.errorMessage == nil, "Should have no error message")
        #expect(viewModel.isSigningIn == false, "Should not be signing in after completion")
        #expect(mockAuth.callHistory.count == 1, "Should have called auth service once")
        
        if case .signIn(let email, let password) = mockAuth.lastCall() {
            #expect(email == "user@example.com", "Should pass correct email")
            #expect(password == "password123", "Should pass correct password")
        } else {
            Issue.record("Expected signIn call in history")
        }
    }
    
    @Test("Failed sign-in shows appropriate error")
    @MainActor
    func failedSignInShowsError() async throws {
        // Given
        let mockAuth = AuthenticationTestFactory.createMockService(shouldSucceedSignIn: false, networkDelay: 0.05)
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.email = "user@example.com"
        viewModel.password = "wrong"
        
        // When
        await viewModel.signIn()
        
        // Then
        #expect(viewModel.isAuthenticated == false, "Should not be authenticated after failure")
        #expect(viewModel.errorMessage != nil, "Should show error message")
        #expect(viewModel.isSigningIn == false, "Should not be signing in after completion")
    }
    
    @Test("Authentication service errors are handled gracefully")
    @MainActor
    func authenticationServiceErrorsHandledGracefully() async throws {
        // Given
        let mockAuth = AuthenticationTestFactory.createMockService(networkDelay: 0.05)
        mockAuth.shouldThrowError = true
        mockAuth.simulatedError = TestAuthenticationError.networkError
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        
        // When
        await viewModel.signIn()
        
        // Then
        #expect(viewModel.isAuthenticated == false, "Should not be authenticated after error")
        #expect(viewModel.errorMessage != nil, "Should show error message")
        #expect(viewModel.isSigningIn == false, "Should not be signing in after error")
    }
    
    @Test("Sign-up with valid data succeeds and switches mode")
    @MainActor
    func signUpWithValidDataSucceedsAndSwitchesMode() async throws {
        // Given
        let mockAuth = AuthenticationTestFactory.createMockService(shouldSucceedSignUp: true, networkDelay: 0.05)
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.isSignUpMode = true
        viewModel.email = "test@example.com"
        viewModel.password = "StrongPass123!"
        viewModel.confirmPassword = "StrongPass123!"
        
        // When
        await viewModel.signUp()
        
        // Then
        #expect(viewModel.isSignUpMode == false, "Should switch to sign-in mode after successful sign-up")
        #expect(viewModel.email == "test@example.com", "Should preserve email address")
        #expect(viewModel.password.isEmpty, "Should clear password for security")
        #expect(viewModel.confirmPassword.isEmpty, "Should clear confirm password")
        #expect(viewModel.errorMessage == nil, "Should have no error message")
        #expect(viewModel.isAuthenticated == false, "Should NOT be authenticated after sign-up")
    }
    
    @Test("Sign-up with weak password shows validation error")
    @MainActor
    func signUpWithWeakPasswordShowsValidationError() async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        viewModel.isSignUpMode = true
        viewModel.email = "user@domain.com"
        viewModel.password = "weak"
        viewModel.confirmPassword = "weak"
        
        // When
        await viewModel.signUp()
        
        // Then
        #expect(viewModel.isAuthenticated == false, "Should not be authenticated with weak password")
        #expect(viewModel.errorMessage != nil, "Should show error message")
        #expect(viewModel.errorMessage?.contains("stronger") == true, "Error should mention stronger password")
    }
    
    @Test("Sign-up with mismatched passwords shows error")
    @MainActor
    func signUpWithMismatchedPasswordsShowsError() async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        viewModel.isSignUpMode = true
        viewModel.email = "user@domain.com"
        viewModel.password = "StrongPass123!"
        viewModel.confirmPassword = "DifferentPass123!"
        
        // When
        await viewModel.signUp()
        
        // Then
        #expect(viewModel.isAuthenticated == false, "Should not be authenticated with mismatched passwords")
        #expect(viewModel.errorMessage != nil, "Should show error message")
        #expect(viewModel.errorMessage?.contains("match") == true, "Error should mention password mismatch")
        #expect(viewModel.confirmPassword.isEmpty, "Confirm password should be cleared")
    }
}
    
