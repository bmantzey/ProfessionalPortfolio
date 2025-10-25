//
//  AuthenticationViewModelInitializationTests.swift
//  ProfessionalPortfolioTests
//
//  Created by Brandon Mantzey on 10/25/25.
//

import Testing

@Suite("Authentication ViewModel Initialization")
struct AuthenticationViewModelInitializationTests {
    
    @Test("ViewModel initializes with correct default state")
    @MainActor
    func viewModelInitializesWithCorrectDefaultState() async throws {
        // Given
        let mockAuth = AuthenticationTestFactory.createMockService()
        
        // When
        let viewModel = AuthenticationViewModel(auth: mockAuth)
        
        // Then - Verify all initial states
        #expect(viewModel.email.isEmpty, "Email should be empty on initialization")
        #expect(viewModel.password.isEmpty, "Password should be empty on initialization")
        #expect(viewModel.confirmPassword.isEmpty, "Confirm password should be empty on initialization")
        #expect(viewModel.isSigningIn == false, "Should not be signing in initially")
        #expect(viewModel.isAuthenticated == false, "Should not be authenticated initially")
        #expect(viewModel.errorMessage == nil, "Should have no error message initially")
        #expect(viewModel.isSignUpMode == false, "Should start in sign-in mode")
        
        // Verify computed properties
        #expect(viewModel.canSignIn == false, "Should not allow sign-in with empty credentials")
        #expect(viewModel.canSignUp == false, "Should not allow sign-up with empty credentials")
        #expect(viewModel.isEmailValid == false, "Empty email should be invalid")
        #expect(viewModel.isPasswordValid == false, "Empty password should be invalid in sign-in mode")
    }
    
    @Test("ViewModel toggles between sign-in and sign-up modes correctly")
    @MainActor
    func viewModelTogglesBetweenModes() async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        #expect(viewModel.isSignUpMode == false, "Should start in sign-in mode")
        
        // When - Toggle to sign-up
        viewModel.toggleMode()
        
        // Then
        #expect(viewModel.isSignUpMode == true, "Should switch to sign-up mode")
        #expect(viewModel.confirmPassword.isEmpty, "Should clear confirm password")
        #expect(viewModel.errorMessage == nil, "Should clear error message")
        
        // When - Toggle back to sign-in
        viewModel.toggleMode()
        
        // Then
        #expect(viewModel.isSignUpMode == false, "Should switch back to sign-in mode")
        #expect(viewModel.confirmPassword.isEmpty, "Should keep confirm password cleared")
        #expect(viewModel.errorMessage == nil, "Should keep error message cleared")
    }
}
