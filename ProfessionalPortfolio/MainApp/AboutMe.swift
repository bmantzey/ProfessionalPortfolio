//
//  AboutMe.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/25/25.
//

import SwiftUI

struct AboutMe: View {
    @Environment(\.theme) var theme
    @Environment(\.authStateManager) private var authStateManager
    @State private var isSigningOut: Bool = false
    @Binding var selectedTab: Tab

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing16) {
                    HStack(spacing: 20) {
                        Image("me_striped_shirt")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 216, height: 216)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        VStack(spacing: 16) {
                            Link(destination: URL(string: "https://github.com/bmantzey")!) {
                                Image("github_icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(isSigningOut ? 0.95 : 1.0)
                                    .animation(.easeInOut(duration: 0.1), value: isSigningOut)
                            }
                            .buttonStyle(SocialLinkButtonStyle())
                            
                            Link(destination: URL(string: "https://www.linkedin.com/in/bmantzey")!) {
                                Image("linkedin_icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(isSigningOut ? 0.95 : 1.0)
                                    .animation(.easeInOut(duration: 0.1), value: isSigningOut)
                            }
                            .buttonStyle(SocialLinkButtonStyle())
                        }
                    }
                    .padding(.top, theme.spacing8)
                    
                    Button(action: {
                        selectedTab = .guestLog
                    }) {
                        HStack(spacing: theme.spacing12) {
                            Spacer()
                            
                            Text(String(localized: "Please sign my guest book."))
                                .font(theme.body)
                                .foregroundColor(theme.accentInfo)
                            
                            Image(systemName: "arrow.up.right")
                                .font(theme.subheadline)
                                .foregroundColor(theme.accentInfo)
                        }
                        .padding(theme.spacing16)
                        .card()
                    }
                    .buttonStyle(PlainButtonStyle())
                    Text(String(localized: "about_me.bio_text"))
                        .font(theme.body)
                        .foregroundColor(theme.textSecondary)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(theme.spacing16)
                        .card()
                    
                    LinkButton(
                        icon: "mail",
                        title: String(localized: "Email me with any comments."),
                        url: URL(string: "mailto:bmantzey@mac.com?subject=Portfolio%20Contact&body=Hi%20Brandon,%0A%0AI%20saw%20your%20portfolio%20and%20would%20like%20to%20connect.")!
                    )
                    
                    Button(action: { Task { await signOut() } }) {
                        HStack(spacing: 6) {
                            if isSigningOut {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 14, weight: .regular))
                                Text(String(localized: "Sign Out"))
                                    .font(.system(size: 14, weight: .regular))
                            }
                        }
                        .padding(theme.spacing12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                                )
                        )
                        .foregroundColor(.secondary)
                        .scaleEffect(isSigningOut ? 0.98 : 1.0)
                        .opacity(isSigningOut ? 0.6 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: isSigningOut)
                    }
                    .disabled(isSigningOut)
                    .padding(.top, theme.spacing8)
                    .padding(.bottom, 100) // Tab bar height + 16 pixels spacing
                }
            }
            .ignoresSafeArea(edges: .bottom) // Allow content to scroll under tab bar
            .navigationTitle(String(localized: "Brandon Mantzey!"))
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        theme.backgroundTertiary,
                        Color(.systemGray)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom) // Gradient extends under tab bar
            )
        }
    }
    
    @MainActor
    private func signOut() async {
        guard let authStateManager = authStateManager else { return }
        
        isSigningOut = true
        defer { isSigningOut = false }
        
        do {
            try await authStateManager.signOut()
        } catch {
            // TODO: Show error alert to user
            print("Sign out failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AboutMe(selectedTab: .constant(Tab.aboutMe))
}

struct SocialLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
