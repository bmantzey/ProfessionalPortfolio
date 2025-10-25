//
//  FirebaseAuthenticationService.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/25/25.
//

import Foundation
import FirebaseAuth

/// A concrete implementation of AuthenticationService that uses Firebase Authentication
final class FirebaseAuthenticationService: AuthenticationService {
    
    // MARK: - AuthenticationService Protocol Implementation
    
    func signIn(email: String, password: String) async throws -> Bool {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            return authResult.user.uid.isEmpty == false
        } catch let authError as NSError {
            throw mapFirebaseError(authError)
        }
    }
    
    func signUp(email: String, password: String) async throws -> Bool {
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Firebase automatically signs in after account creation, but we want the user
            // to explicitly sign in, so we sign them out immediately
            try Auth.auth().signOut()
            
            return authResult.user.uid.isEmpty == false
        } catch let authError as NSError {
            throw mapFirebaseError(authError)
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Maps Firebase Auth errors to user-friendly error messages
    private func mapFirebaseError(_ error: NSError) -> NSError {
        let errorCode = AuthErrorCode(rawValue: error.code)
        
        let userFriendlyMessage: String
        
        switch errorCode {
        case .invalidEmail:
            userFriendlyMessage = "Please enter a valid email address."
        case .wrongPassword:
            userFriendlyMessage = "Incorrect password. Please try again."
        case .userNotFound:
            userFriendlyMessage = "No account found with this email address."
        case .userDisabled:
            userFriendlyMessage = "This account has been disabled. Please contact support."
        case .emailAlreadyInUse:
            userFriendlyMessage = "An account with this email already exists."
        case .weakPassword:
            userFriendlyMessage = "Password is too weak. Please choose a stronger password."
        case .networkError:
            userFriendlyMessage = "Network error. Please check your connection and try again."
        case .tooManyRequests:
            userFriendlyMessage = "Too many failed attempts. Please try again later."
        case .operationNotAllowed:
            userFriendlyMessage = "Sign-in method is not enabled. Please contact support."
        default:
            // For any other Firebase errors, provide a generic message
            userFriendlyMessage = "Authentication failed. Please try again."
        }
        
        return NSError(
            domain: "FirebaseAuthenticationService",
            code: error.code,
            userInfo: [NSLocalizedDescriptionKey: userFriendlyMessage]
        )
    }
}