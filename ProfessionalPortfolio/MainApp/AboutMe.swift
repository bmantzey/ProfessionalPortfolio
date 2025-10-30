//
//  AboutMe.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/25/25.
//

import SwiftUI

// TODO: Wipe this temporary code and implement the following instead:
/*
 1. Show a professional photo of me.
 2. Put together a summary of who I am, what I do, and what I've been looking for.
 3. Provide a link to my LinkedIn.
 4. Provide a link to my GitHub.
 5. Consider other content that might make sense.
 6. Content will be static for now, but can be provided via Firestore Database later.
 */

struct AboutMe: View {
    @Environment(\.theme) var theme
    @Environment(\.authStateManager) private var authStateManager
    @State private var isSigningOut: Bool = false
    @Binding var selectedTab: Tab

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Welcome to Brandon Mantzey's Portfolio!")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                            .padding(.top, 20)

                        Text("Welcome to my portfolio app. This is a great way to showcase my skills and abilities as an iOS developer and practice my studies of SwiftUI.\n\nI invite you to check out my Github page. There you'll find the source code for this project, where you can see for yourself my work.\n\nPlease visit the Guest Log tab and feel free to email me your comments or suggestions.")
                            .font(theme.body)
                            .foregroundColor(theme.textSecondary)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(theme.spacing16)
                            .card()
                
                        
                        Button(action: {
                            selectedTab = .guestLog
                        }) {
                            HStack(spacing: theme.spacing12) {
                                Spacer()
                                
                                Text("Please sign my guest book.")
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
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    LinkButton(
                        icon: "mail",
                        title: "Email me with any comments.",
                        url: URL(string: "mailto:bmantzey@mac.com?subject=Portfolio%20Contact&body=Hi%20Brandon,%0A%0AI%20saw%20your%20portfolio%20and%20would%20like%20to%20connect.")!
                    )
                }
                // Link Button Example
                Spacer()
                
                Button(action: { Task { await signOut() } }) {
                    HStack(spacing: 6) {
                        if isSigningOut {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 14, weight: .regular))
                            Text("Sign Out")
                                .font(.system(size: 14, weight: .regular))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
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
                .padding(.bottom, 20)
            }
            .navigationTitle("Brandon's Portfolio")
            .background(theme.backgroundPrimary)
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
