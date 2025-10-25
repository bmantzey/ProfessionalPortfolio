//
//  AuthenticationViewModel.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/23/25.
//

import Foundation

@Observable
final class AuthenticationViewModel {
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var isSigningIn: Bool = false
    var isAuthenticated: Bool = false
    var errorMessage: String? = nil
    var isSignUpMode: Bool = false
    
    private let auth: AuthenticationService
    
    var canSignIn: Bool {
        return isEmailValid &&
               isPasswordValid &&
               !isSigningIn
    }
    
    var canSignUp: Bool {
        return isEmailValid &&
               isPasswordValid &&
               !confirmPassword.isEmpty &&
               password == confirmPassword &&
               !isSigningIn
    }
    
    var isEmailValid: Bool {
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Basic validation checks
        guard !emailTrimmed.isEmpty else { return false }
        guard !emailTrimmed.contains(" ") else { return false } // No spaces
        guard emailTrimmed.contains("@") else { return false } // Must have @
        
        let parts = emailTrimmed.components(separatedBy: "@")
        guard parts.count == 2 else { return false } // Exactly one @
        
        let localPart = parts[0]
        let domainPart = parts[1]
        
        // Local part validation
        guard !localPart.isEmpty else { return false }
        guard !localPart.hasPrefix(".") && !localPart.hasSuffix(".") else { return false }
        
        // Domain part validation
        guard !domainPart.isEmpty else { return false }
        guard domainPart.contains(".") else { return false } // Must have at least one dot
        guard !domainPart.hasPrefix(".") && !domainPart.hasSuffix(".") else { return false }
        guard !domainPart.hasPrefix("-") && !domainPart.hasSuffix("-") else { return false }
        
        let domainComponents = domainPart.components(separatedBy: ".")
        guard domainComponents.count >= 2 else { return false }
        guard domainComponents.last?.count ?? 0 >= 2 else { return false } // TLD at least 2 chars
        
        // All domain components should be non-empty
        for component in domainComponents {
            guard !component.isEmpty else { return false }
        }
        
        return true
    }
    
    var isPasswordValid: Bool {
        return isSignUpMode ? isPasswordStrong(password) : !password.isEmpty
    }
    
    var passwordValidationMessage: String? {
        guard isSignUpMode && !password.isEmpty else { return nil }
        return passwordStrengthMessage(for: password)
    }
    
    init(auth: AuthenticationService) {
        self.auth = auth
    }
    
    @MainActor
    func validateEmailAndClearPasswordIfNeeded() {
        if !isEmailValid {
            password = ""
            confirmPassword = ""
        }
        // Clear any previous error when user starts typing
        if errorMessage != nil {
            errorMessage = nil
        }
    }
    
    @MainActor
    func signIn() async {
        // Clear previous error
        errorMessage = nil

        // Validate early and return without toggling isSigningIn
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !emailTrimmed.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            isAuthenticated = false
            return
        }
        
        guard isEmailValid else {
            errorMessage = "Please enter a valid email address."
            isAuthenticated = false
            password = "" // Clear password when email is invalid
            return
        }

        isSigningIn = true
        defer { isSigningIn = false }

        do {
            let success = try await auth.signIn(email: emailTrimmed, password: password)
            isAuthenticated = success
            
            if !success {
                errorMessage = "Invalid email or password."
            }
        } catch {
            isAuthenticated = false
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func toggleMode() {
        isSignUpMode.toggle()
        confirmPassword = ""
        errorMessage = nil
    }
    
    @MainActor
    func signUp() async {
        // Clear previous error
        errorMessage = nil

        // Validate early and return without toggling isSigningIn
        guard isEmailValid, isPasswordValid, !confirmPassword.isEmpty else {
            if !isEmailValid {
                errorMessage = "Please enter a valid email address."
            } else if !isPasswordValid {
                errorMessage = "Please create a stronger password."
            } else {
                errorMessage = "Please fill in all fields."
            }
            isAuthenticated = false
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match."
            isAuthenticated = false
            confirmPassword = ""
            return
        }

        isSigningIn = true
        defer { isSigningIn = false }

        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let success = try await auth.signUp(email: emailTrimmed, password: password)
            
            if success {
                // Successfully created account, switch to sign-in mode
                isSignUpMode = false
                password = ""  // Clear password for security - user must re-enter
                confirmPassword = ""
                errorMessage = nil
                // Note: Keep email populated for convenience
                // Note: User is NOT authenticated - they must sign in with their new account
            } else {
                errorMessage = "Failed to create account. Please try again."
            }
        } catch {
            isAuthenticated = false
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Password Validation
    
    private func isPasswordStrong(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }
        
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChar = password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
        
        return hasUppercase && hasLowercase && hasNumber && hasSpecialChar
    }
    
    private func passwordStrengthMessage(for password: String) -> String? {
        guard !password.isEmpty else { return nil }
        
        var missingRequirements: [String] = []
        
        if password.count < 8 {
            missingRequirements.append("8 characters")
        }
        
        if password.range(of: "[A-Z]", options: .regularExpression) == nil {
            missingRequirements.append("uppercase letter")
        }
        
        if password.range(of: "[a-z]", options: .regularExpression) == nil {
            missingRequirements.append("lowercase letter")
        }
        
        if password.range(of: "[0-9]", options: .regularExpression) == nil {
            missingRequirements.append("number")
        }
        
        if password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) == nil {
            missingRequirements.append("special character")
        }
        
        if missingRequirements.isEmpty {
            return nil // Password is strong
        }
        
        let requirementText = missingRequirements.joined(separator: ", ")
        return "Password needs: \(requirementText)"
    }
}
