//
//  AuthenticationService.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/24/25.
//

import Foundation

/// A service responsible for authenticating user credentials.
protocol AuthenticationService {
    /// Attempts to authenticate a user with the provided credentials.
    /// - Parameters:
    ///   - email: The user's email address
    ///   - password: The user's password
    /// - Returns: `true` if authentication succeeds, `false` otherwise
    /// - Throws: An error if authentication fails or if there's a network/service issue
    func signIn(email: String, password: String) async throws -> Bool
    
    /// Attempts to create a new user account with the provided credentials.
    /// - Parameters:
    ///   - email: The user's email address
    ///   - password: The user's password
    /// - Returns: `true` if account creation succeeds, `false` otherwise
    /// - Throws: An error if account creation fails or if there's a network/service issue
    func signUp(email: String, password: String) async throws -> Bool
}