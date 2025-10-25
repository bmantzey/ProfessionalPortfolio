//
//  EmailValidationTests.swift
//  ProfessionalPortfolioTests
//
//  Created by Brandon Mantzey on 10/25/25.
//

import Testing

@Suite("Email Validation")
struct EmailValidationTests {
    
    @Test("Email validation correctly identifies valid emails", arguments: TestEmailData.validEmails)
    @MainActor
    func emailValidationIdentifiesValidEmails(validEmail: String) async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        
        // When
        viewModel.email = validEmail
        
        // Then
        #expect(viewModel.isEmailValid == true, "Email '\(validEmail)' should be valid")
    }
    
    @Test("Email validation correctly rejects invalid emails")
    @MainActor
    func emailValidationRejectsInvalidEmails() async throws {
        let viewModel = AuthenticationTestFactory.createViewModel()
        
        for (invalidEmail, reason) in TestEmailData.invalidEmails {
            // When
            viewModel.email = invalidEmail
            
            // Then
            #expect(viewModel.isEmailValid == false, "Email '\(invalidEmail)' should be invalid: \(reason)")
        }
    }
    
    @Test("Email validation handles whitespace correctly")
    @MainActor
    func emailValidationHandlesWhitespace() async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        
        // When - Email with surrounding whitespace
        viewModel.email = "  user@domain.com  "
        
        // Then
        #expect(viewModel.isEmailValid == true, "Valid email with whitespace should be valid (trimmed)")
        
        // When - Only whitespace
        viewModel.email = "   "
        
        // Then
        #expect(viewModel.isEmailValid == false, "Whitespace-only email should be invalid")
    }
    
    @Test("Email validation clears password when email becomes invalid")
    @MainActor
    func emailValidationClearsPasswordWhenInvalid() async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        viewModel.email = "user@domain.com"
        viewModel.password = "password123"
        
        // When - Change to invalid email
        viewModel.email = "invalid"
        viewModel.validateEmailAndClearPasswordIfNeeded()
        
        // Then
        #expect(viewModel.password.isEmpty, "Password should be cleared when email becomes invalid")
        #expect(viewModel.confirmPassword.isEmpty, "Confirm password should also be cleared")
    }
    
    @Test("Email validation clears error messages")
    @MainActor
    func emailValidationClearsErrorMessages() async throws {
        // Given
        let viewModel = AuthenticationTestFactory.createViewModel()
        viewModel.errorMessage = "Previous error"
        
        // When
        viewModel.validateEmailAndClearPasswordIfNeeded()
        
        // Then
        #expect(viewModel.errorMessage == nil, "Error message should be cleared during validation")
    }
}
    
