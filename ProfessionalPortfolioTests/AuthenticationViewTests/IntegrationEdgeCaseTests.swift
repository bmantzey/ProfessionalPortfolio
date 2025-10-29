//
//  IntegrationEdgeCaseTests.swift
//  ProfessionalPortfolioTests
//
//  Created by Brandon Mantzey on 10/25/25.
//

import Testing

@Suite("Integration and Edge Cases")
struct IntegrationEdgeCaseTests {
    
    @Test("Rapid input changes handle state correctly")
    @MainActor
    func rapidInputChangesHandleStateCorrectly() async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        
        // When making rapid changes
        viewModel.email = "user@domain.com"
        viewModel.password = "password"
        viewModel.email = "invalid"
        viewModel.email = "valid@test.com"
        viewModel.password = "newpassword"
        
        // Then final state should be consistent
        #expect(viewModel.isEmailValid == true, "Should have valid email state")
        #expect(viewModel.password == "newpassword", "Should retain final password")
    }
    
    @Test("Multiple authentication attempts are handled correctly")
    @MainActor
    func multipleAuthenticationAttemptsHandledCorrectly() async throws {
        // Given
        let mockAuth = AuthenticationTestFactory.createMockService(shouldSucceedSignIn: false, networkDelay: 0.05)
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        viewModel.email = "user@example.com"
        viewModel.password = "wrong"
        
        // First attempt (should fail)
        await viewModel.signIn()
        #expect(viewModel.isAuthenticated == false, "First attempt should fail")
        #expect(mockAuth.callCount() == 1, "Should have made one call")
        
        // Second attempt with correct password
        mockAuth.shouldSucceedSignIn = true
        viewModel.password = "correct"
        await viewModel.signIn()
        #expect(viewModel.isAuthenticated == true, "Second attempt should succeed")
        #expect(mockAuth.callCount() == 2, "Should have made two calls")
    }
    
    @Test("Error message specificity matches validation errors")
    @MainActor
    func errorMessageSpecificityMatchesValidationErrors() async throws {
        let mockAuth = AuthenticationTestFactory.createMockService(shouldSucceedSignIn: false, networkDelay: 0.05)
        
        // Empty credentials error
        let viewModel1 = AuthenticationViewModel(auth: mockAuth)
        await viewModel1.signIn()
        #expect(viewModel1.errorMessage == "Please enter your email and password.",
                "Empty credentials should show specific message")
        
        // Invalid email error
        let viewModel2 = AuthenticationViewModel(auth: mockAuth)
        viewModel2.email = "invalid"
        viewModel2.password = "password"
        await viewModel2.signIn()
        #expect(viewModel2.errorMessage == "Please enter a valid email address.",
                "Invalid email should show specific message")
        
        // Weak password in sign-up mode
        let viewModel3 = AuthenticationViewModel(auth: mockAuth)
        viewModel3.isSignUpMode = true
        viewModel3.email = "test@example.com"
        viewModel3.password = "weak"
        viewModel3.confirmPassword = "weak"
        await viewModel3.signUp()
        #expect(viewModel3.errorMessage == "Please create a stronger password.",
                "Weak password should show specific message")
    }
}
