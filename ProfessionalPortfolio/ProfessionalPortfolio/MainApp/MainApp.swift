//
//  MainApp.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/25/25.
//

import SwiftUI

struct MainApp: View {
    @Environment(\.authStateManager) private var authStateManager
    @State private var isSigningOut: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to Professional Portfolio")
                    .font(.title)
                    .padding()
                
                Spacer()
                
                Text("You are successfully signed in!")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
                }
            }
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
    MainApp()
}
