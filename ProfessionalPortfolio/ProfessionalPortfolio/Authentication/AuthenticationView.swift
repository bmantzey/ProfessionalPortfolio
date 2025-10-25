//
//  AuthenticationView.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/22/25.
//

import SwiftUI

// MARK: - Reusable Components

private struct AuthenticationHeader: View {
    let isSignUpMode: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(isSignUpMode ? "Create Account" : "Welcome")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(isSignUpMode ? "Sign up to get started" : "Please sign in to continue")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .animation(.easeInOut(duration: 0.3), value: isSignUpMode)
    }
}

private struct AuthenticationFormFields: View {
    @Binding var viewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            EmailField(viewModel: $viewModel)
            PasswordField(viewModel: $viewModel)
            
            if viewModel.isSignUpMode {
                ConfirmPasswordField(viewModel: $viewModel)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

private struct EmailField: View {
    @Binding var viewModel: AuthenticationViewModel
    
    var body: some View {
        ThemedTextField(
            title: "Email Address",
            placeholder: "Enter your email",
            text: $viewModel.email,
            keyboardType: .emailAddress,
            autocapitalization: .never,
            errorMessage: emailErrorMessage
        )
        .onChange(of: viewModel.email) {
            viewModel.validateEmailAndClearPasswordIfNeeded()
        }
    }
    
    private var emailErrorMessage: String? {
        guard !viewModel.email.isEmpty && !viewModel.isEmailValid else { return nil }
        return "Please enter a valid email address"
    }
}

private struct PasswordField: View {
    @Binding var viewModel: AuthenticationViewModel
    
    var body: some View {
        ThemedTextField(
            title: "Password",
            placeholder: viewModel.isEmailValid ? "Enter your password" : "Complete email first",
            text: $viewModel.password,
            isSecure: true,
            errorMessage: passwordErrorMessage
        )
        .disabled(!viewModel.isEmailValid)
        .opacity(viewModel.isEmailValid ? 1.0 : 0.6)
    }
    
    private var passwordErrorMessage: String? {
        // In sign-up mode, show password strength validation
        if viewModel.isSignUpMode && !viewModel.password.isEmpty {
            return viewModel.passwordValidationMessage
        }
        // In sign-in mode or empty email, show basic validation
        guard !viewModel.isEmailValid && !viewModel.email.isEmpty else { return nil }
        return "Complete your email address first"
    }
}

private struct ConfirmPasswordField: View {
    @Binding var viewModel: AuthenticationViewModel
    
    var body: some View {
        ThemedTextField(
            title: "Confirm Password",
            placeholder: "Confirm your password",
            text: $viewModel.confirmPassword,
            isSecure: true,
            errorMessage: confirmPasswordErrorMessage
        )
        .disabled(!viewModel.isEmailValid)
        .opacity(viewModel.isEmailValid ? 1.0 : 0.6)
    }
    
    private var confirmPasswordErrorMessage: String? {
        guard viewModel.isSignUpMode else { return nil }
        guard !viewModel.confirmPassword.isEmpty else { return nil }
        guard viewModel.password != viewModel.confirmPassword else { return nil }
        return "Passwords don't match"
    }
}

private struct AuthenticationButton: View {
    @Binding var viewModel: AuthenticationViewModel
    
    var body: some View {
        Button {
            Task {
                await performAuthAction()
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isSigningIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
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
    
    private func performAuthAction() async {
        if viewModel.isSignUpMode {
            await viewModel.signUp()
        } else {
            await viewModel.signIn()
        }
    }
}

private struct AccountToggleSection: View {
    @Binding var viewModel: AuthenticationViewModel
    
    var body: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .font(.callout)
                .foregroundStyle(.secondary)
            
            Button("Create one") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.toggleMode()
                }
            }
            .buttonStyle(TextButtonStyle())
        }
        .padding(.top, 16)
    }
}

private struct ErrorDisplayView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
            
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .background(.red.opacity(0.1))
        .cornerRadius(8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

struct AuthenticationView: View {
    @Environment(\.theme) private var theme
    @State private var viewModel: AuthenticationViewModel
    
    init(authService: AuthenticationService) {
        _viewModel = State(initialValue: AuthenticationViewModel(auth: authService))
    }
    
    init(viewModel: AuthenticationViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: theme.spacing32) {
            AuthenticationHeader(isSignUpMode: viewModel.isSignUpMode)
            
            VStack(spacing: theme.spacing24) {
                AuthenticationFormFields(viewModel: $viewModel)
                AuthenticationButton(viewModel: $viewModel)
                
                if !viewModel.isSignUpMode {
                    AccountToggleSection(viewModel: $viewModel)
                }
            }
            .padding(theme.spacing24)
            .elevatedCard()
            
            if let errorMessage = viewModel.errorMessage {
                ErrorDisplayView(message: errorMessage)
            }
            
            Spacer()
        }
        .padding(theme.spacing24)
        .background(authenticationBackground)
        .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isSignUpMode)
    }
    
    private var authenticationBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                theme.backgroundTertiary,
                theme.backgroundPrimary
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Preview

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AuthenticationView(authService: PreviewMockAuthService())
                .previewDisplayName("Sign In")
            
            AuthenticationView(authService: PreviewMockAuthService(simulateLoading: true))
                .previewDisplayName("Loading")
            
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
        await simulateDelay()
        
        if shouldFail {
            throw AuthenticationError.invalidCredentials
        }
        
        return true
    }
    
    func signUp(email: String, password: String) async throws -> Bool {
        await simulateDelay()
        
        if shouldFail {
            throw AuthenticationError.accountCreationFailed
        }
        
        return true
    }
    
    private func simulateDelay() async {
        let delay = simulateLoading ? 3_000_000_000 : 500_000_000 // 3s or 0.5s
        try? await Task.sleep(nanoseconds: UInt64(delay))
    }
}

// MARK: - Authentication Errors

private enum AuthenticationError: LocalizedError {
    case invalidCredentials
    case accountCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials. Please try again."
        case .accountCreationFailed:
            return "Failed to create account. Please try again."
        }
    }
}
