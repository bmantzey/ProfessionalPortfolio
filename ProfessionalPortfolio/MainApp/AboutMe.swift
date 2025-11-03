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
            VStack(spacing: 0) {
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
                        Text("I'm Brandon, a Senior Mobile Software Engineer who's been building iOS apps since the early App Store days. For over 16 years, I've specialized in Swift and Objective-C, working on production applications for companies like Garmin, TD Ameritrade/Schwab, Perficient, and GE. I love tackling complex problems with clean architecture and delivering features that make a real impact. From launching the Garmin Dive app to building the system that migrated 13.5 million TD Ameritrade customers to Schwab Mobile, I've led and contributed to successful projects across multiple industries.\n\nI’ve spent the past several months sharpening my skills with SwiftUI through intensive study and leveraging AI as a force multiplier in my development process. What used to take weeks now takes days, and I built this portfolio to demonstrate that synergy in action and showcase the result of that growth.\n\nI’m excited to connect with fellow developers and potential collaborators in the software development world. Feel free to explore, sign my Guest Log, check out my GitHub for the source code, and drop me a note via Email. I'd love to hear from you.")
                            .font(theme.body)
                            .foregroundColor(theme.textSecondary)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(theme.spacing16)
                            .card()
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
            }
            .navigationTitle("Brandon Mantzey!")
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
