//
//  AuthenticationStateManager.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/25/25.
//

import Foundation
import FirebaseAuth
import FirebaseCore

/// Manages the global authentication state for the application
/// Listens to Firebase Auth state changes and provides observable authentication status
@Observable
final class AuthenticationStateManager {
    
    // MARK: - Published Properties
    
    /// Whether the user is currently authenticated
    var isAuthenticated: Bool = false
    
    /// The current Firebase user, if authenticated
    var currentUser: User? = nil
    
    /// Whether the manager is currently checking authentication state (e.g., on app launch)
    var isCheckingAuthState: Bool = true
    
    // MARK: - Private Properties
    
    /// Handle for the Firebase auth state listener
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Initialization
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        removeAuthStateListener()
    }
    
    // MARK: - Private Methods
    
    /// Sets up the Firebase authentication state listener
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            DispatchQueue.main.async {
                self?.handleAuthStateChange(user: user)
            }
        }
    }
    
    /// Handles Firebase authentication state changes
    /// - Parameter user: The Firebase user object, or nil if not authenticated
    @MainActor
    private func handleAuthStateChange(user: User?) {
        // Update authentication state
        isAuthenticated = user != nil
        currentUser = user
        
        // Clear loading state after first check
        if isCheckingAuthState {
            isCheckingAuthState = false
        }
    }
    
    /// Removes the Firebase authentication state listener
    private func removeAuthStateListener() {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            authStateHandle = nil
        }
    }
}