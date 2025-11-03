//
//  AuthenticationView.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/22/25.
//

import SwiftUI

struct AuthenticationView: View {
    @Environment(\.theme) private var theme
    @State private var viewModel: AuthenticationViewModel
    @FocusState private var focusedField: Field?
    
    init(authService: AuthenticationService) {
        _viewModel = State(initialValue: AuthenticationViewModel(auth: authService))
    }
    
    init(viewModel: AuthenticationViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    enum Field: Hashable {
        case email, password, confirmPassword
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing32) {
                headerSection
                
                VStack(spacing: theme.spacing24) {
                    formFields
                    signInButton
                    accountToggleSection
                }
                .padding(theme.spacing24) // Internal padding INSIDE the card
                .elevatedCard()
                
                if let errorMessage = viewModel.errorMessage {
                    InlineErrorView(message: errorMessage)
                }
                
                Spacer()
            }
            .padding(theme.spacing24) // Reduced from 32 to match card padding
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    theme.backgroundTertiary,
                    Color(.systemGray)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isEmailValid)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isSignUpMode)
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: theme.spacing8) {
            Text(viewModel.isSignUpMode ? "Create Account" : "Welcome")
                .font(theme.largeTitle)
                .foregroundColor(theme.primaryLight)
            
            Text(viewModel.isSignUpMode ? "Sign up to get started" : "Please sign in to continue")
                .font(theme.subheadline)
                .foregroundColor(theme.textSecondary)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isSignUpMode)
    }
    
    private var formFields: some View {
        VStack(spacing: theme.spacing16) {
            ThemedTextField(
                title: "Email Address",
                placeholder: "Enter your email",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                submitLabel: .next,
                autocapitalization: .never,
                errorMessage: emailErrorMessage
            )
            .focused($focusedField, equals: .email)
            .onChange(of: viewModel.email) {
                viewModel.onEmailChanged()
            }
            .onSubmit {
                // Only move to password field if email is valid
                if viewModel.isEmailValid {
                    focusedField = .password
                }
            }
            
            ThemedTextField(
                title: "Password",
                placeholder: viewModel.isEmailValid ? "Enter your password" : "Complete email first",
                text: $viewModel.password,
                isSecure: true,
                submitLabel: viewModel.isSignUpMode ? .next : .return,
                errorMessage: passwordErrorMessage
            )
            .focused($focusedField, equals: .password)
            .disabled(!viewModel.isEmailValid) // Disable if email is not valid
            .animation(.easeInOut(duration: 0.2), value: viewModel.isEmailValid)
            .onSubmit {
                if viewModel.isSignUpMode {
                    // In sign-up mode: only move to confirm password if password is valid
                    if viewModel.passwordValidationMessage == nil && !viewModel.password.isEmpty {
                        focusedField = .confirmPassword
                    }
                } else {
                    // In sign-in mode: submit if both email and password are valid
                    if viewModel.canSignIn {
                        handleFormSubmission()
                    }
                }
            }
            
            if viewModel.isSignUpMode {
                ThemedTextField(
                    title: "Confirm Password",
                    placeholder: "Confirm your password",
                    text: $viewModel.confirmPassword,
                    isSecure: true,
                    errorMessage: confirmPasswordErrorMessage
                )
                .focused($focusedField, equals: .confirmPassword)
                .disabled(viewModel.passwordValidationMessage != nil || viewModel.password.isEmpty) // Disable if password is not valid
                .transition(.opacity.combined(with: .move(edge: .top)))
                .onSubmit {
                    // Only submit if passwords match and form is valid
                    if viewModel.password == viewModel.confirmPassword && viewModel.canSignUp {
                        handleFormSubmission()
                    }
                }
            }
        }
    }
    
    private var signInButton: some View {
        Button {
            Task {
                if viewModel.isSignUpMode {
                    await viewModel.signUp()
                } else {
                    await viewModel.signIn()
                }
            }
        } label: {
            HStack(spacing: theme.spacing8) {
                if viewModel.isSigningIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.textOnPrimary))
                        .scaleEffect(0.8)
                }
                
                Text(buttonText)
            }
        }
        .buttonStyle(EnhancedPrimaryButtonStyle())
        .disabled(!buttonEnabled)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isSigningIn)
    }
    
    private var buttonText: String {
        if viewModel.isSigningIn {
            return viewModel.isSignUpMode ? "Creating Account..." : "Signing In..."
        } else {
            return viewModel.isSignUpMode ? "Sign Up" : "Sign In"
        }
    }
    
    private var buttonEnabled: Bool {
        return viewModel.isSignUpMode ? viewModel.canSignUp : viewModel.canSignIn
    }
    
    private var accountToggleSection: some View {
        HStack(spacing: theme.spacing4) {
            Text(viewModel.isSignUpMode ? "Try signing in again?" : "Don't have an account?")
                .font(theme.callout)
                .foregroundColor(theme.textSecondary)
            
            Button(viewModel.isSignUpMode ? "Sign in" : "Create one") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.toggleMode()
                }
            }
            .buttonStyle(TextButtonStyle())
        }
        .padding(.top, theme.spacing16) // More space from button above
    }
    
    // MARK: - Computed Properties
    
    private var emailErrorMessage: String? {
        guard !viewModel.email.isEmpty && !viewModel.isEmailValid else { return nil }
        return "Please enter a valid email address"
    }
    
    private var passwordErrorMessage: String? {
        // In sign-up mode, show password strength validation
        if viewModel.isSignUpMode && !viewModel.password.isEmpty {
            return viewModel.passwordValidationMessage
        }
        
        // Don't show "complete email first" error unless user is actively trying to use the password field
        // This prevents confusing error messages during normal typing flow
        return nil
    }
    
    private var confirmPasswordErrorMessage: String? {
        guard viewModel.isSignUpMode else { return nil }
        guard !viewModel.confirmPassword.isEmpty else { return nil }
        guard viewModel.password != viewModel.confirmPassword else { return nil }
        return "Passwords don't match"
    }
    
    // MARK: - Actions
    
    private func handleFormSubmission() {
        // Only submit if the form is valid and button would be enabled
        guard buttonEnabled else { return }
        
        Task {
            if viewModel.isSignUpMode {
                await viewModel.signUp()
            } else {
                await viewModel.signIn()
            }
        }
    }
}

// MARK: - Preview

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default state (sign-in)
            AuthenticationView(authService: PreviewMockAuthService())
                .previewDisplayName("Sign In")
            
            // Sign-up mode
            AuthenticationView(authService: PreviewMockAuthService())
                .onAppear {
                    // Note: This won't actually work in preview, but shows intent
                }
                .previewDisplayName("Sign Up Mode")
            
            // Loading state
            AuthenticationView(authService: PreviewMockAuthService(simulateLoading: true))
                .previewDisplayName("Loading")
            
            // Error state
            AuthenticationView(authService: PreviewMockAuthService(shouldFail: true))
                .previewDisplayName("Error State")
        }
    }
}

// MARK: - Preview Mock Service

private class PreviewMockAuthService: AuthenticationService {
    private let shouldFail: Bool
    private let simulateLoading: Bool
    
    init(shouldFail: Bool = false, simulateLoading: Bool = false) {
        self.shouldFail = shouldFail
        self.simulateLoading = simulateLoading
    }
    
    func signIn(email: String, password: String) async throws -> Bool {
        if simulateLoading {
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds for preview
        } else {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        }
        
        if shouldFail {
            throw NSError(domain: "Preview", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials. Please try again."])
        }
        
        return password != "wrong"
    }
    
    func signUp(email: String, password: String) async throws -> Bool {
        if simulateLoading {
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds for preview
        } else {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        }
        
        if shouldFail {
            throw NSError(domain: "Preview", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create account. Please try again."])
        }
        
        return password != "exists"
    }
}
