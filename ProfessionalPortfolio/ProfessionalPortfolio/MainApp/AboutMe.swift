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
    @Environment(\.authStateManager) private var authStateManager
    @State private var isSigningOut: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to Brandon Mantzey's Professional Portfolio App!")
                    .font(.title)
                    .padding()
                
                Spacer()
                
                Text("You are successfully signed in!")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await signOut()
                    }
                }) {
                    if isSigningOut {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                            .scaleEffect(0.8)
                    } else {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                .disabled(isSigningOut)

                Spacer()
            }
            .navigationTitle("Brandon's Portfolio")
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
    AboutMe()
}
