//
//  ContentView.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/22/25.
//

import SwiftUI

// MARK: - Example Usage (Remove in production)

struct DesignSystemPreview: View {
    @Environment(\.theme) var theme
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing24) {
                    // Text Field Examples
                    ThemedTextField(
                        title: "Email",
                        placeholder: "Enter your email",
                        text: $email,
                        keyboardType: .emailAddress,
                        autocapitalization: .never,
                        errorMessage: showError ? "Invalid email address" : nil
                    )
                    
                    ThemedTextField(
                        title: "Password",
                        placeholder: "Enter your password",
                        text: $password,
                        isSecure: true
                    )
                    
                    // Button Examples
                    Button("Primary Button") {}
                        .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Secondary Button") {}
                        .buttonStyle(SecondaryButtonStyle())
                    
                    Button("Text Button") {}
                        .buttonStyle(TextButtonStyle())
                    
                    // Card Examples
                    InfoCard(
                        title: "About Me",
                        content: "iOS Developer specializing in Swift and SwiftUI with experience in modern app architecture.",
                        icon: "person.circle.fill"
                    )
                    
                    // Link Button Example
                    LinkButton(
                        icon: "link.circle.fill",
                        title: "GitHub Profile",
                        url: URL(string: "https://github.com/bmantzey")!
                    )
                    
                    // Loading Example
                    LoadingView(message: "Loading...")
                        .padding(theme.spacing24)
                    
                    // Error Example
                    ErrorView(message: "Something went wrong") {
                        print("Retry tapped")
                    }
                }
                .padding(theme.spacing16)
            }
            .background(theme.backgroundPrimary)
            .navigationTitle("Design System")
        }
    }
}

#Preview {
    DesignSystemPreview()
        .environment(\.theme, DefaultTheme())
}
