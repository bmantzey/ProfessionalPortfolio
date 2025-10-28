//
//  FirebaseAuthenticationService.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/25/25.
//

import Foundation
import FirebaseAuth

// MARK: - Custom Error Types

/// Comprehensive Firebase authentication errors with user-friendly messages and recovery suggestions
enum FirebaseAuthenticationError: LocalizedError {
    case invalidEmail
    case wrongPassword
    case userNotFound
    case userDisabled
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case tooManyRequests(retryAfter: TimeInterval?)
    case operationNotAllowed
    case invalidCredential
    case userTokenExpired
    case accountExistsWithDifferentCredential
    case quotaExceeded
    case appNotAuthorized
    case keychainError
    case internalError
    case unknown(originalError: Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found with this email address."
        case .userDisabled:
            return "This account has been disabled. Please contact support."
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password is too weak. Please choose a stronger password."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .tooManyRequests:
            return "Too many failed attempts. Please try again later."
        case .operationNotAllowed:
            return "Sign-in method is not enabled. Please contact support."
        case .invalidCredential:
            return "Invalid credentials provided. Please check your information."
        case .userTokenExpired:
            return "Your session has expired. Please sign in again."
        case .accountExistsWithDifferentCredential:
            return "An account already exists with this email using a different sign-in method."
        case .quotaExceeded:
            return "Service quota exceeded. Please try again later."
        case .appNotAuthorized:
            return "This app is not authorized. Please contact support."
        case .keychainError:
            return "Unable to access secure storage. Please try again."
        case .internalError:
            return "An internal error occurred. Please try again."
        case .unknown:
            return "Authentication failed. Please try again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidEmail:
            return "Make sure your email address is correctly formatted."
        case .wrongPassword:
            return "Try using 'Forgot Password' if you can't remember it."
        case .userNotFound:
            return "Double-check the email address or create a new account."
        case .userDisabled:
            return "Contact customer support for account reactivation."
        case .emailAlreadyInUse:
            return "Try signing in instead, or use a different email address."
        case .weakPassword:
            return "Use at least 8 characters with uppercase, lowercase, numbers, and symbols."
        case .networkError:
            return "Check your internet connection and try again."
        case .tooManyRequests(let retryAfter):
            if let retryAfter = retryAfter {
                return "Wait \(Int(retryAfter)) seconds before trying again."
            }
            return "Wait a few minutes before trying again."
        case .operationNotAllowed:
            return "Contact support to enable this sign-in method."
        case .invalidCredential:
            return "Verify your email and password are correct."
        case .userTokenExpired:
            return "Please sign out and sign in again."
        case .accountExistsWithDifferentCredential:
            return "Try signing in with a different method (Google, Apple, etc.)."
        case .quotaExceeded, .appNotAuthorized, .internalError:
            return "This is a temporary issue. Please try again in a few minutes."
        case .keychainError:
            return "Restart the app or check your device security settings."
        case .unknown:
            return "If this persists, please contact support."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkError, .tooManyRequests, .quotaExceeded, .internalError, .keychainError:
            return true
        case .invalidEmail, .wrongPassword, .userNotFound, .userDisabled, .emailAlreadyInUse,
             .weakPassword, .operationNotAllowed, .invalidCredential, .userTokenExpired,
             .accountExistsWithDifferentCredential, .appNotAuthorized:
            return false
        case .unknown:
            return true // Default to retryable for unknown errors
        }
    }
}

// MARK: - FirebaseAuthenticationError Equatable Conformance

extension FirebaseAuthenticationError: Equatable {
    static func == (lhs: FirebaseAuthenticationError, rhs: FirebaseAuthenticationError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidEmail, .invalidEmail),
             (.wrongPassword, .wrongPassword),
             (.userNotFound, .userNotFound),
             (.userDisabled, .userDisabled),
             (.emailAlreadyInUse, .emailAlreadyInUse),
             (.weakPassword, .weakPassword),
             (.networkError, .networkError),
             (.operationNotAllowed, .operationNotAllowed),
             (.invalidCredential, .invalidCredential),
             (.userTokenExpired, .userTokenExpired),
             (.accountExistsWithDifferentCredential, .accountExistsWithDifferentCredential),
             (.quotaExceeded, .quotaExceeded),
             (.appNotAuthorized, .appNotAuthorized),
             (.keychainError, .keychainError),
             (.internalError, .internalError):
            return true
            
        case let (.tooManyRequests(lhsRetryAfter), .tooManyRequests(rhsRetryAfter)):
            return lhsRetryAfter == rhsRetryAfter
            
        case let (.unknown(lhsError), .unknown(rhsError)):
            // Compare error descriptions since Error protocol doesn't guarantee Equatable
            return lhsError.localizedDescription == rhsError.localizedDescription
            
        default:
            return false
        }
    }
}

// MARK: - Firebase Authentication Service

/// A robust implementation of AuthenticationService using Firebase Authentication
/// with comprehensive error handling, retry logic, and performance optimizations
final class FirebaseAuthenticationService: AuthenticationService {
    
    // MARK: - Private Properties
    
    private let maxRetryAttempts: Int = 3
    private let retryDelay: TimeInterval = 1.0
    private weak var authStateManager: AuthenticationStateManager?
    
    // MARK: - Initialization
    
    init(authStateManager: AuthenticationStateManager? = nil) {
        self.authStateManager = authStateManager
    }
    
    // MARK: - AuthenticationService Protocol Implementation
    
    func signIn(email: String, password: String) async throws -> Bool {
        let sanitizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        return try await performWithRetry {
            let authResult = try await Auth.auth().signIn(withEmail: sanitizedEmail, password: password)
            
            // Verify the authentication result
            guard !authResult.user.uid.isEmpty else {
                throw FirebaseAuthenticationError.internalError
            }
            
            return true
        }
    }
    
    func signUp(email: String, password: String) async throws -> Bool {
        let sanitizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        return try await performWithRetry {
            // Temporarily ignore auth state changes to prevent UI flash
            self.authStateManager?.setIgnoreAuthChanges(true)
            
            defer {
                // Always re-enable auth state changes when done
                self.authStateManager?.setIgnoreAuthChanges(false)
            }
            
            // Create the account - this will automatically sign in the user
            let authResult = try await Auth.auth().createUser(withEmail: sanitizedEmail, password: password)
            
            // Verify the authentication result
            guard !authResult.user.uid.isEmpty else {
                throw FirebaseAuthenticationError.internalError
            }
            
            // Perform sign-out on main thread and wait for it to complete
            try await MainActor.run {
                try Auth.auth().signOut()
            }
            
            // Add a small delay to ensure everything is processed
            try await Task.sleep(nanoseconds: 50_000_000) // 50 milliseconds
            
            return true
        }
    }
    
    // MARK: - Advanced Features
    
    /// Signs out the current user
    /// - Throws: FirebaseAuthenticationError if sign-out fails
    func signOut() async throws {
        _ = try await performWithRetry { [weak self] in
            guard self != nil else { throw FirebaseAuthenticationError.internalError }
            
            try Auth.auth().signOut()
            return true
        }
    }
    
    /// Gets the current user ID if signed in
    /// - Returns: User ID string or nil if not signed in
    func getCurrentUserID() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    /// Checks if a user is currently signed in
    /// - Returns: True if user is signed in, false otherwise
    func isSignedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    // MARK: - Private Helper Methods
    
    /// Performs an operation with automatic retry logic for transient failures
    private func performWithRetry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        for attempt in 1...maxRetryAttempts {
            do {
                return try await operation()
            } catch let error as FirebaseAuthenticationError {
                #if DEBUG
                logError(error, context: "Retry attempt \(attempt)/\(maxRetryAttempts)")
                #endif
                
                // Only retry if the error is retryable and we haven't exceeded max attempts
                if error.isRetryable && attempt < maxRetryAttempts {
                    let delay = retryDelay * Double(attempt) // Exponential backoff
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                } else {
                    throw error
                }
            } catch let firebaseError as NSError {
                let authError = mapFirebaseError(firebaseError)
                
                #if DEBUG
                logError(authError, context: "Firebase error on attempt \(attempt)/\(maxRetryAttempts)")
                #endif
                
                // Only retry if the error is retryable and we haven't exceeded max attempts
                if authError.isRetryable && attempt < maxRetryAttempts {
                    let delay = retryDelay * Double(attempt) // Exponential backoff
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                } else {
                    throw authError
                }
            } catch {
                // For any other unexpected errors
                let unknownError = FirebaseAuthenticationError.unknown(originalError: error)
                
                #if DEBUG
                logError(unknownError, context: "Unexpected error on attempt \(attempt)/\(maxRetryAttempts)")
                #endif
                
                throw unknownError
            }
        }
        
        // This should never be reached, but defensive programming
        throw FirebaseAuthenticationError.internalError
    }
    
    /// Maps Firebase Auth errors to comprehensive FirebaseAuthenticationError cases
    /// - Parameter error: The Firebase NSError to map
    /// - Returns: A corresponding FirebaseAuthenticationError with user-friendly messaging
    private func mapFirebaseError(_ error: NSError) -> FirebaseAuthenticationError {
        guard let errorCode = AuthErrorCode(rawValue: error.code) else {
            return .unknown(originalError: error)
        }
        
        switch errorCode {
        case .invalidEmail:
            return .invalidEmail
        case .wrongPassword:
            return .wrongPassword
        case .userNotFound:
            return .userNotFound
        case .userDisabled:
            return .userDisabled
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword
        case .networkError:
            return .networkError
        case .tooManyRequests:
            // Try to extract retry-after information if available
            let retryAfter = error.userInfo["retry_after"] as? TimeInterval
            return .tooManyRequests(retryAfter: retryAfter)
        case .operationNotAllowed:
            return .operationNotAllowed
        case .invalidCredential:
            return .invalidCredential
        case .userTokenExpired:
            return .userTokenExpired
        case .accountExistsWithDifferentCredential:
            return .accountExistsWithDifferentCredential
        case .quotaExceeded:
            return .quotaExceeded
        case .appNotAuthorized:
            return .appNotAuthorized
        case .keychainError:
            return .keychainError
        case .internalError:
            return .internalError
        default:
            return .unknown(originalError: error)
        }
    }
    
    // MARK: - Development & Debugging Support
    
    #if DEBUG
    /// Provides detailed error information for debugging
    private func logError(_ error: Error, context: String) {
        let errorDetails = """
        
        🔥 Firebase Authentication Error 🔥
        Context: \(context)
        Error: \(error.localizedDescription)
        
        """
        
        if let authError = error as? FirebaseAuthenticationError {
            print(errorDetails + """
            Type: \(authError)
            Recovery: \(authError.recoverySuggestion ?? "No suggestion available")
            Retryable: \(authError.isRetryable)
            """)
        } else {
            print(errorDetails + "Original Error: \(error)")
        }
    }
    #endif
}
