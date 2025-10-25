//
//  AuthenticationStateManager.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/25/25.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import SwiftUI

/// Environment key for AuthenticationStateManager
public struct AuthenticationStateManagerKey: EnvironmentKey {
    public static let defaultValue: AuthenticationStateManager? = nil
}

public extension EnvironmentValues {
    var authStateManager: AuthenticationStateManager? {
        get { self[AuthenticationStateManagerKey.self] }
        set { self[AuthenticationStateManagerKey.self] = newValue }
    }
}

/// Manages the global authentication state for the application
/// Listens to Firebase Auth state changes and provides observable authentication status
@Observable
public final class AuthenticationStateManager {
    
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
    
    public init() {
        setupAuthStateListener()
    }
    
    deinit {
        removeAuthStateListener()
    }
    
    // MARK: - Public Methods
    
    /// Signs out the current user
    /// - Throws: An error if sign-out fails
    public func signOut() async throws {
        do {
            try Auth.auth().signOut()
            // Note: The auth state listener will automatically update our properties
            // when Firebase notifies us of the sign-out
        } catch {
            print("⚠️ Sign out failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Manually retry setting up the auth state listener
    /// Call this if Firebase wasn't configured during initialization
    public func retrySetup() {
        guard authStateHandle == nil else {
            print("⚠️ Auth state listener already configured")
            return
        }
        setupAuthStateListener()
    }
    
    // MARK: - Private Methods
    
    /// Sets up the Firebase authentication state listener
    private func setupAuthStateListener() {
        // Ensure Firebase is configured before setting up listener
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase not configured. Unable to set up AuthenticationStateManager.")
            return
        }
        
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            DispatchQueue.main.async {
                self?.handleAuthStateChange(user: user)
            }
        }
    }
    
    /// Handles Firebase authentication state changes
    /// - Parameter user: The Firebase user object, or nil if not authenticated
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