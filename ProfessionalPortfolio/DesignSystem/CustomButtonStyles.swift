//
//  CustomButtonStyles.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/22/25.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.theme) var theme
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.headline)
            .foregroundColor(theme.textOnPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing16)
            .background(isEnabled ? theme.primaryMedium : theme.textTertiary)
            .cornerRadius(theme.cornerRadiusMedium)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct EnhancedPrimaryButtonStyle: ButtonStyle {
    @Environment(\.theme) var theme
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.headline)
            .foregroundColor(theme.textOnPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing16)
            .background(
                Group {
                    if isEnabled {
                        LinearGradient(
                            gradient: Gradient(colors: [theme.primaryMedium, theme.primaryDark]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        theme.textTertiary
                    }
                }
            )
            .cornerRadius(theme.cornerRadiusMedium)
            .shadow(
                color: isEnabled ? theme.primaryMedium.opacity(0.3) : .clear,
                radius: configuration.isPressed ? 2 : 4,
                x: 0,
                y: configuration.isPressed ? 1 : 2
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.theme) var theme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.headline)
            .foregroundColor(theme.primaryMedium)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing16)
            .background(theme.backgroundSecondary)
            .cornerRadius(theme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                    .stroke(theme.primaryMedium, lineWidth: theme.borderWidthThin)
            )
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct TextButtonStyle: ButtonStyle {
    @Environment(\.theme) var theme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.callout)
            .foregroundColor(theme.primaryMedium)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
