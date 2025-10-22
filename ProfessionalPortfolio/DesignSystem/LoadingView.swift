//
//  LoadingView.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/22/25.
//

import SwiftUI

struct LoadingView: View {
    @Environment(\.theme) var theme
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: theme.spacing16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(theme.primaryMedium)
            
            if let message = message {
                Text(message)
                    .font(theme.callout)
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
}

#Preview {
    @Previewable @Environment(\.theme) var theme
    VStack {
        Text("Standard Loading View with short message")
        LoadingView(message: "Loading, please wait...")
            .padding(.bottom, theme.spacing16)
        Text("Standard Loading View with no message")
        LoadingView()
            .padding(.bottom, theme.spacing16)
        Text("Standard Loading View with long message")
        LoadingView(message: "Loading, please wait longer message to test how it looks when it's very long.")
            .padding(.bottom, theme.spacing16)
    }
    .padding()
    

}
