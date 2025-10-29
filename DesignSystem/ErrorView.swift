//
//  ErrorView.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/22/25.
//

import SwiftUI

// TODO: Go through this and take out any code that is not needed (or delete this).
struct ErrorView: View {
    @Environment(\.theme) var theme
    
    let message: String
    let retryAction: (() -> Void)?
    
    init(message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: theme.spacing16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.accentError)
            
            Text(message)
                .font(theme.body)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            
            if let retry = retryAction {
                Button("Try Again", action: retry)
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.horizontal, theme.spacing32)
            }
        }
        .padding(theme.spacing24)
    }
}


#Preview {
    ErrorView(message: "Test Error")
}
