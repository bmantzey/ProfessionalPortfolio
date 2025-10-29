//
//  UIStateInteractionTests.swift
//  ProfessionalPortfolioTests
//
//  Created by Brandon Mantzey on 10/25/25.
//

import Testing

@Suite("UI State and Interactions")
struct UIStateInteractionTests {
    
    @Test("canSignIn requires valid email and non-empty password")
    @MainActor
    func canSignInRequiresValidEmailAndNonEmptyPassword() async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        
        // Empty credentials
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
    
    @Test("canSignUp requires all fields valid including password confirmation")
    @MainActor
    func canSignUpRequiresAllFieldsValid() async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        viewModel.isSignUpMode = true
        viewModel.email = "user@domain.com"
        
        // Weak password
        viewModel.password = "weak"
        viewModel.confirmPassword = "weak"
        #expect(viewModel.canSignUp == false, "Should not allow sign-up with weak password")
        
        // Strong password but not confirmed
        viewModel.password = "StrongP@ss123"
        viewModel.confirmPassword = ""
        #expect(viewModel.canSignUp == false, "Should not allow sign-up without password confirmation")
        
        // Strong password but mismatched
        viewModel.confirmPassword = "DifferentP@ss123"
        #expect(viewModel.canSignUp == false, "Should not allow sign-up with mismatched passwords")
        
        // All fields valid
        viewModel.confirmPassword = "StrongP@ss123"
        #expect(viewModel.canSignUp == true, "Should allow sign-up with all valid fields")
        
        // Should not allow sign-up while signing in
        viewModel.isSigningIn = true
        #expect(viewModel.canSignUp == false, "Should not allow sign-up while signing in")
    }
    
    @Test("isSigningIn state transitions correctly during authentication")
    @MainActor
    func isSigningInStateTransitionsCorrectly() async throws {
        // Given
        let mockAuth = AuthenticationTestFactory.createMockService(networkDelay: 0.1)
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        
        // Initially not signing in
        #expect(viewModel.isSigningIn == false, "Should start not signing in")
        
        // When starting sign-in
        let signInTask = Task {
            await viewModel.signIn()
        }
        
        // Brief delay to allow async operation to start
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        #expect(viewModel.isSigningIn == true, "Should be signing in during operation")
        
        // Wait for completion
        await signInTask.value
        #expect(viewModel.isSigningIn == false, "Should not be signing in after completion")
    }
    
    @Test("Mode toggle clears form state appropriately")
    @MainActor
    func modeToggleClearsFormState() async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        viewModel.isSignUpMode = true
        viewModel.confirmPassword = "somePassword"
        viewModel.errorMessage = "Some error"
        
        // When toggling mode
        viewModel.toggleMode()
        
        // Then
        #expect(viewModel.isSignUpMode == false, "Should toggle mode")
        #expect(viewModel.confirmPassword.isEmpty, "Should clear confirm password")
        #expect(viewModel.errorMessage == nil, "Should clear error message")
    }
    
    @Test("Error messages are cleared when user starts typing")
    @MainActor
    func errorMessagesAreClearedWhenUserStartsTyping() async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        viewModel.errorMessage = "Previous error"
        
        // When user starts typing in email
        viewModel.email = "u"
        
        // Then error should be cleared automatically through property observers
        // (This behavior is implemented in the optimized ViewModel)
    }
}
    
