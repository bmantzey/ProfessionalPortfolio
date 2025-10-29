//
//  ThemedTextField.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/22/25.
//

import SwiftUI

struct ThemedTextField: View {
    @Environment(\.theme) var theme
    
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var errorMessage: String? = nil
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing8) {
            Text(title)
                .font(theme.subheadline)
                .foregroundColor(theme.textSecondary)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .focused($isFocused)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                }
            }
            .font(theme.body)
            .padding(theme.spacing16)
            .background(theme.backgroundTertiary)
            .cornerRadius(theme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                    .stroke(
                        errorMessage != nil ? theme.accentError :
                        isFocused ? theme.primaryMedium : theme.backgroundSecondary,
                        lineWidth: isFocused ? theme.borderWidthMedium : theme.borderWidthThin
                    )
            )
            
            if let error = errorMessage {
                HStack(spacing: theme.spacing4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(theme.caption)
                    Text(error)
                        .font(theme.caption)
                }
                .foregroundColor(theme.accentError)
            }
        }
    }
}


#Preview {
    @Previewable @State var email = "test@email.com"
    @Previewable @Environment(\.theme) var theme

    ThemedTextField(
        title: "Email",
        placeholder: "Enter your email",
        text: $email,
        keyboardType: .emailAddress,
        autocapitalization: .never,
        errorMessage: nil
    )
    .padding(theme.spacing16)
    // Background will appear better when this is embedded in a VStack or other parent view and the background is set there.
}
