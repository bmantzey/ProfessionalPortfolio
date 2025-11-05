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
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@",
                                       "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
        let passesEmailValidation = emailPredicate.evaluate(with: emailTrimmed)
        
        return !emailTrimmed.isEmpty && passesEmailValidation
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
    func onEmailChanged() {
        // Clear any previous error when user starts typing
        if errorMessage != nil {
            errorMessage = nil
        }
        
        // Don't automatically clear passwords - let the user decide
        // This provides a better user experience and prevents the race condition
    }
    
    @MainActor
    func signIn() async {
        // Clear previous error
        errorMessage = nil

        // Validate early and return without toggling isSigningIn
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !emailTrimmed.isEmpty, !password.isEmpty else {
            errorMessage = String(localized: "Please enter your email and password.")
            isAuthenticated = false
            return
        }
        
        guard isEmailValid else {
            errorMessage = String(localized: "Please enter a valid email address.")
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
                errorMessage = String(localized: "Invalid email or password.")
            }
        } catch {
            isAuthenticated = false
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func toggleMode() {
        isSignUpMode.toggle()
        if isSignUpMode {
            email = ""
        }
        password = ""
        confirmPassword = ""
        errorMessage = nil
    }
    
    @MainActor
    func clearSensitiveData() {
        password = ""
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
                errorMessage = String(localized: "Please enter a valid email address.")
            } else if !isPasswordValid {
                errorMessage = String(localized: "Please create a stronger password.")
            } else {
                errorMessage = String(localized: "Please fill in all fields.")
            }
            isAuthenticated = false
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = String(localized: "Passwords don't match.")
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
                errorMessage = String(localized: "Failed to create account. Please try again.")
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
        
        let needsLength = password.count < 8
        let needsUppercase = password.range(of: "[A-Z]", options: .regularExpression) == nil
        let needsLowercase = password.range(of: "[a-z]", options: .regularExpression) == nil
        let needsNumber = password.range(of: "[0-9]", options: .regularExpression) == nil
        let needsSpecial = password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) == nil
        
        if !needsLength && !needsUppercase && !needsLowercase && !needsNumber && !needsSpecial {
            return nil // Password is strong
        }
        
        // Show a single, properly localized message that covers all requirements
        return String(localized: "Use at least 8 characters with uppercase, lowercase, numbers, and symbols.")
    }
}
