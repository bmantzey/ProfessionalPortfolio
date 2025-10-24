//
//  AuthenticationViewTests.swift
//  ProfessionalPortfolioTests
//
//  Created by Brandon Mantzey on 10/23/25.
//

import Testing

// MARK: - Mock Authentication Service

/// A mock authentication service for testing purposes
class MockAuthenticationService: AuthenticationService {
    var shouldSucceed: Bool = true
    var shouldThrowError: Bool = false
    var simulatedError: Error = AuthenticationError.invalidCredentials
    var shouldSignUpSucceed: Bool = true
    var shouldSignUpThrowError: Bool = false
    
    func signIn(email: String, password: String) async throws -> Bool {
        if shouldThrowError {
            throw simulatedError
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Mock logic: succeed if password isn't "wrong"
        return shouldSucceed && password != "wrong"
    }
    
    func signUp(email: String, password: String) async throws -> Bool {
        if shouldSignUpThrowError {
            throw simulatedError
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Mock logic: succeed unless password is "exists" (simulating existing account)
        return shouldSignUpSucceed && password != "exists"
    }
}

/// Mock authentication errors for testing
enum AuthenticationError: Error {
    case invalidCredentials
    case networkError
    case serverError
}

@Suite("Authentication View Tests")
struct AuthenticationViewTests {
    
    @Test("View model initializes with empty credentials")
    @MainActor
    func viewModelInitializesWithEmptyCredentials() async throws {
        // Given
        let mockAuth = MockAuthenticationService()
        
        // When
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        
        // Then
        #expect(viewModel.email.isEmpty, "Email should be empty on initialization")
        #expect(viewModel.password.isEmpty, "Password should be empty on initialization")
        #expect(viewModel.confirmPassword.isEmpty, "Confirm password should be empty on initialization")
        #expect(viewModel.isSigningIn == false, "Should not be signing in initially")
        #expect(viewModel.isAuthenticated == false, "Should not be authenticated initially")
        #expect(viewModel.errorMessage == nil, "Should have no error message initially")
        #expect(viewModel.isSignUpMode == false, "Should start in sign-in mode")
    }
    
    @Test("Validation: Empty credentials prevent sign-in")
    @MainActor
    func validationEmptyCredentialsPreventSignIn() async throws {
        // Given
        let mockAuth = MockAuthenticationService()
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        #expect(viewModel.email.isEmpty)
        #expect(viewModel.password.isEmpty)
        
        // When
        await viewModel.signIn()
        
        // Then
        #expect(viewModel.isSigningIn == false, "Should not toggle signing in with empty credentials")
        #expect(viewModel.errorMessage != nil, "Should surface a helpful validation error")
        #expect(viewModel.isAuthenticated == false, "Should not be authenticated with empty credentials")
    }
    
    @Test("Malformed email prevents sign-in")
    @MainActor
    func malformedEmailPreventsSignIn() async throws {
        // Given
        let mockAuth = MockAuthenticationService()
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.email = "not-an-email"
        viewModel.password = "password123"
        
        // When
        await viewModel.signIn()
        
        // Then
        #expect(viewModel.isAuthenticated == false, "Should not be authenticated with invalid email")
        #expect(viewModel.errorMessage != nil, "Should show an error message")
        #expect(viewModel.errorMessage?.contains("email") == true, "Error should mention email")
        #expect(viewModel.password.isEmpty, "Password should be cleared when email is invalid")
    }
    
    @Test("Various invalid email formats are rejected")
    @MainActor
    func variousInvalidEmailFormatsAreRejected() async throws {
        let invalidEmails = [
            "",                    // Empty
            "   ",                // Whitespace only
            "plaintext",          // No @ symbol
            "@domain.com",        // No local part
            "user@",              // No domain
            "user@domain",        // No TLD
            "user.domain.com",    // No @ symbol
            "user@@domain.com",   // Double @
            "user@.com",          // Domain starts with dot
            "user@domain.",       // TLD missing
            "user@domain.c",      // TLD too short
            "user name@domain.com" // Space in local part
        ]
        
        let mockAuth = MockAuthenticationService()
        
        for invalidEmail in invalidEmails {
            // Given
            let viewModel = AuthenticationViewModel(auth: mockAuth)
            viewModel.email = invalidEmail
            viewModel.password = "password123"
            
            // When
            await viewModel.signIn()
            
            // Then
            #expect(viewModel.isAuthenticated == false, "Should reject invalid email: '\(invalidEmail)'")
            #expect(viewModel.errorMessage != nil, "Should show error for invalid email: '\(invalidEmail)'")
        }
    }
    
    @Test("Valid email formats are accepted")
    @MainActor
    func validEmailFormatsAreAccepted() async throws {
        let validEmails = [
            "user@domain.com",
            "test.email@example.org",
            "user+tag@domain.co.uk",
            "user_name@domain-name.com",
            "123@domain.com",
            "user@123domain.com",
            "a@b.co"
        ]
        
        let mockAuth = MockAuthenticationService()
        mockAuth.shouldSucceed = true
        
        for validEmail in validEmails {
            // Given
            let viewModel = AuthenticationViewModel(auth: mockAuth)
            viewModel.email = validEmail
            viewModel.password = "password123"
            
            // When
            await viewModel.signIn()
            
            // Then
            #expect(viewModel.isAuthenticated == true, "Should accept valid email: '\(validEmail)'")
            #expect(viewModel.errorMessage == nil, "Should not show error for valid email: '\(validEmail)'")
        }
    }
    
    @Test("isEmailValid property works correctly")
    @MainActor
    func isEmailValidPropertyWorksCorrectly() async throws {
        // Given
        let mockAuth = MockAuthenticationService()
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        
        // When/Then - Invalid emails
        viewModel.email = ""
        #expect(viewModel.isEmailValid == false, "Empty email should be invalid")
        
        viewModel.email = "invalid"
        #expect(viewModel.isEmailValid == false, "Malformed email should be invalid")
        
        viewModel.email = "  user@domain.com  "
        #expect(viewModel.isEmailValid == true, "Valid email with whitespace should be valid (trimmed)")
        
        viewModel.email = "user@domain.com"
        #expect(viewModel.isEmailValid == true, "Valid email should be valid")
    }
    
    @Test("canSignIn requires valid email and non-empty password")
    @MainActor
    func canSignInRequiresValidEmailAndNonEmptyPassword() async throws {
        // Given
        let mockAuth = MockAuthenticationService()
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        
        // When/Then - No email or password
        #expect(viewModel.canSignIn == false, "Should not allow sign-in with empty credentials")
        
        // Invalid email, valid password
        viewModel.email = "invalid"
        viewModel.password = "password123"
        #expect(viewModel.canSignIn == false, "Should not allow sign-in with invalid email")
        
        // Valid email, empty password
        viewModel.email = "user@domain.com"
        viewModel.password = ""
        #expect(viewModel.canSignIn == false, "Should not allow sign-in with empty password")
        
        // Valid email and password
        viewModel.password = "password123"
        #expect(viewModel.canSignIn == true, "Should allow sign-in with valid credentials")
        
        // Should not allow sign-in while signing in
        viewModel.isSigningIn = true
        #expect(viewModel.canSignIn == false, "Should not allow sign-in while already signing in")
    }
    
    @Test("validateEmailAndClearPasswordIfNeeded clears password for invalid email")
    @MainActor
    func validateEmailAndClearPasswordIfNeededClearsPasswordForInvalidEmail() async throws {
        // Given
        let mockAuth = MockAuthenticationService()
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.email = "user@domain.com"
        viewModel.password = "password123"
        
        // When - Change to invalid email
        viewModel.email = "invalid"
        viewModel.validateEmailAndClearPasswordIfNeeded()
        
        // Then
        #expect(viewModel.password.isEmpty, "Password should be cleared when email becomes invalid")
    }
    
    @Test("isSigningIn toggles during sign-in with non-empty credentials")
    @MainActor
    func isSigningInTogglesDuringSignIn() async throws {
        // Given
        let mockAuth = MockAuthenticationService()
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        
        // When
        // Start sign-in but observe state transitions
        let signInTask = Task { await viewModel.signIn() }
        
        // Then
        // Immediately after starting, we expect isSigningIn to be true (allow a tiny delay for async hop)
        try await Task.sleep(nanoseconds: 50_000_000) // 50 ms
        #expect(viewModel.isSigningIn == true, "Should start signing in immediately")
        
        // Wait for completion
        await signInTask.value
        #expect(viewModel.isSigningIn == false, "Should stop signing in when done")
    }
    
    @Test("Successful sign-in sets authenticated state")
    @MainActor
    func successfulSignInSetsAuthenticatedState() async throws {
        // Given
        let mockAuth = MockAuthenticationService()
        mockAuth.shouldSucceed = true
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        
        // When
        await viewModel.signIn()
        
        // Then
        #expect(viewModel.isAuthenticated == true, "Should be authenticated after success")
        #expect(viewModel.errorMessage == nil, "No error on success")
    }
    
    @Test("Failed sign-in surfaces an error")
    @MainActor
    func failedSignInSurfacesError() async throws {
        // Given
        let mockAuth = MockAuthenticationService()
        mockAuth.shouldSucceed = false // This will make the mock return false
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.email = "user@example.com"
        viewModel.password = "wrong"
        
        // When
        await viewModel.signIn()
        
        // Then
        #expect(viewModel.isAuthenticated == false, "Should not be authenticated after failure")
        #expect(viewModel.errorMessage != nil, "Should show a meaningful error")
    }
    
    @Test("Authentication service error is handled gracefully")
    @MainActor
    func authenticationServiceErrorIsHandledGracefully() async throws {
        // Given
        let mockAuth = MockAuthenticationService()
        mockAuth.shouldThrowError = true
        mockAuth.simulatedError = AuthenticationError.networkError
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        
        // When
        await viewModel.signIn()
        
        // Then
        #expect(viewModel.isAuthenticated == false, "Should not be authenticated after error")
        #expect(viewModel.errorMessage != nil, "Should show an error message")
        #expect(viewModel.isSigningIn == false, "Should stop signing in after error")
    }
    
    // MARK: - Password Validation Tests
    
    @Test("Password validation works for sign-up mode")
    @MainActor
    func passwordValidationWorksForSignUpMode() async throws {
        // Given
        let mockAuth = MockAuthenticationService()
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.isSignUpMode = true
        viewModel.email = "user@domain.com"
        
        // When/Then - Test weak passwords
        let weakPasswords = [
            "weak",           // Too short, no requirements
            "password",       // No uppercase, number, or special char
            "PASSWORD",       // No lowercase, number, or special char
            "Password",       // No number or special char
            "Password123",    // No special char
            "Password@",      // Too short (7 chars)
        ]
        
        for weakPassword in weakPasswords {
            viewModel.password = weakPassword
            #expect(viewModel.isPasswordValid == false, "Should reject weak password: '\(weakPassword)'")
            #expect(viewModel.passwordValidationMessage != nil, "Should show validation message for: '\(weakPassword)'")
        }
        
        // Test strong password
        viewModel.password = "StrongP@ss123"
        #expect(viewModel.isPasswordValid == true, "Should accept strong password")
        #expect(viewModel.passwordValidationMessage == nil, "Should not show validation message for strong password")
    }
    
    @Test("Password validation shows specific missing requirements")
    @MainActor
    func passwordValidationShowsSpecificMissingRequirements() async throws {
        // Given
        let mockAuth = MockAuthenticationService()
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.isSignUpMode = true
        viewModel.email = "user@domain.com"
        
        // When - Test password missing uppercase
        viewModel.password = "password123!"
        
        // Then
        #expect(viewModel.passwordValidationMessage?.contains("uppercase") == true, 
                "Should mention missing uppercase letter")
        
        // When - Test password missing special character
        viewModel.password = "Password123"
        
        // Then
        #expect(viewModel.passwordValidationMessage?.contains("special") == true, 
                "Should mention missing special character")
        
        // When - Test password too short
        viewModel.password = "Pass1!"
        
        // Then
        #expect(viewModel.passwordValidationMessage?.contains("8 characters") == true, 
                "Should mention minimum length requirement")
    }
    
    @Test("Sign-in mode does not require strong password")
    @MainActor
    func signInModeDoesNotRequireStrongPassword() async throws {
        // Given
        let mockAuth = MockAuthenticationService()
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.isSignUpMode = false // Sign-in mode
        viewModel.email = "user@domain.com"
        
        // When - Set a weak password
        viewModel.password = "weak"
        
        // Then
        #expect(viewModel.isPasswordValid == true, "Sign-in mode should accept any non-empty password")
        #expect(viewModel.canSignIn == true, "Should allow sign-in with weak password in sign-in mode")
    }
    
    @Test("Sign-up requires strong password")
    @MainActor
    func signUpRequiresStrongPassword() async throws {
        // Given
        let mockAuth = MockAuthenticationService()
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.isSignUpMode = true
        viewModel.email = "user@domain.com"
        viewModel.password = "weak"
        viewModel.confirmPassword = "weak"
        
        // When/Then
        #expect(viewModel.canSignUp == false, "Should not allow sign-up with weak password")
        
        // When - Use strong password
        viewModel.password = "StrongP@ss123"
        viewModel.confirmPassword = "StrongP@ss123"
        
        // Then
        #expect(viewModel.canSignUp == true, "Should allow sign-up with strong matching passwords")
    }
    
    @Test("Sign-up with weak password shows validation error")
    @MainActor
    func signUpWithWeakPasswordShowsValidationError() async throws {
        // Given
        let mockAuth = MockAuthenticationService()
        let viewModel = AuthenticationViewModel(auth: mockAuth)
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
}
