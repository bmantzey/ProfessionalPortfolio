//
//  PasswordValidationTests.swift
//  ProfessionalPortfolioTests
//
//  Created by Brandon Mantzey on 10/25/25.
//

import Testing

@Suite("Password Validation")
struct PasswordValidationTests {
    
    @Test("Password validation in sign-in mode accepts any non-empty password")
    @MainActor
    func passwordValidationSignInModeAcceptsNonEmpty() async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        viewModel.isSignUpMode = false
        viewModel.email = "user@domain.com"
        
        // When - Set a weak password
        viewModel.password = "weak"
        
        // Then
        #expect(viewModel.isPasswordValid == true, "Sign-in mode should accept any non-empty password")
        #expect(viewModel.canSignIn == true, "Should allow sign-in with weak password in sign-in mode")
    }
    
    @Test("Password validation in sign-up mode requires strong password", arguments: TestEmailData.weakPasswords.map { $0.0 })
    @MainActor
    func passwordValidationSignUpModeRequiresStrong(weakPassword: String) async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        viewModel.isSignUpMode = true
        viewModel.email = "user@domain.com"
        
        // When
        viewModel.password = weakPassword
        
        // Then
        #expect(viewModel.isPasswordValid == false, "Should reject weak password: '\(weakPassword)'")
        #expect(viewModel.passwordValidationMessage != nil, "Should show validation message for: '\(weakPassword)'")
    }
    
    @Test("Password validation accepts strong passwords", arguments: TestEmailData.strongPasswords)
    @MainActor
    func passwordValidationAcceptsStrongPasswords(strongPassword: String) async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        viewModel.isSignUpMode = true
        viewModel.email = "user@domain.com"
        
        // When
        viewModel.password = strongPassword
        
        // Then
        #expect(viewModel.isPasswordValid == true, "Should accept strong password: '\(strongPassword)'")
        #expect(viewModel.passwordValidationMessage == nil, "Should not show validation message for strong password")
    }
    
    @Test("Password validation shows specific missing requirements")
    @MainActor
    func passwordValidationShowsSpecificMissingRequirements() async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        viewModel.isSignUpMode = true
        viewModel.email = "user@domain.com"
        
        // Test password missing uppercase
        viewModel.password = "password123!"
        #expect(viewModel.passwordValidationMessage?.contains("uppercase") == true,
                "Should mention missing uppercase letter")
        
        // Test password missing special character
        viewModel.password = "Password123"
        #expect(viewModel.passwordValidationMessage?.contains("special") == true,
                "Should mention missing special character")
        
        // Test password too short
        viewModel.password = "Pass1!"
        #expect(viewModel.passwordValidationMessage?.contains("8 characters") == true,
                "Should mention minimum length requirement")
    }
    
    @Test("Password validation changes behavior based on mode")
    @MainActor
    func passwordValidationChangesBehaviorBasedOnMode() async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        viewModel.email = "user@domain.com"
        let weakPassword = "weak"
        
        // When in sign-in mode
        viewModel.isSignUpMode = false
        viewModel.password = weakPassword
        let signInValid = viewModel.isPasswordValid
        
        // When in sign-up mode
        viewModel.isSignUpMode = true
        viewModel.password = weakPassword
        let signUpValid = viewModel.isPasswordValid
        
        // Then
        #expect(signInValid == true, "Weak password should be valid in sign-in mode")
        #expect(signUpValid == false, "Weak password should be invalid in sign-up mode")
    }
}
