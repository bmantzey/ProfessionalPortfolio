//
//  InlineErrorView.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/29/25.
//

import SwiftUI

struct InlineErrorView: View {
    @Environment(\.theme) private var theme
    
    let message: String
    var icon: String = "exclamationmark.triangle.fill"
    var style: ErrorStyle = .standard
    
    enum ErrorStyle {
        case standard
        case compact
        case subtle
    }
    
    var body: some View {
        HStack(spacing: iconSpacing) {
            Image(systemName: icon)
                .font(iconFont)
                .foregroundColor(theme.accentError)
            
            Text(message)
                .font(textFont)
                .foregroundColor(theme.accentError)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
        .padding(contentPadding)
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Style Computed Properties
    
    private var iconSpacing: CGFloat {
        switch style {
        case .standard: return theme.spacing8
        case .compact: return theme.spacing4
        case .subtle: return theme.spacing8
        }
    }
    
    private var iconFont: Font {
        switch style {
        case .standard: return theme.caption
        case .compact: return theme.caption.weight(.medium)
        case .subtle: return theme.caption
        }
    }
    
    private var textFont: Font {
        switch style {
        case .standard: return theme.caption
        case .compact: return theme.caption
        case .subtle: return theme.caption.weight(.medium)
        }
    }
    
    private var contentPadding: EdgeInsets {
        switch style {
        case .standard: return EdgeInsets(top: theme.spacing12, leading: theme.spacing12, bottom: theme.spacing12, trailing: theme.spacing12)
        case .compact: return EdgeInsets(top: theme.spacing8, leading: theme.spacing8, bottom: theme.spacing8, trailing: theme.spacing8)
        case .subtle: return EdgeInsets(top: theme.spacing4, leading: 0, bottom: theme.spacing4, trailing: 0)
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .standard: return theme.accentError.opacity(0.1)
        case .compact: return theme.accentError.opacity(0.08)
        case .subtle: return Color.clear
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .standard: return theme.cornerRadiusSmall
        case .compact: return theme.cornerRadiusSmall * 0.5
        case .subtle: return 0
        }
    }
}

// MARK: - Convenience Initializers

extension InlineErrorView {
    /// Creates a compact inline error view suitable for form fields
    static func compact(_ message: String, icon: String = "exclamationmark.circle.fill") -> InlineErrorView {
        InlineErrorView(message: message, icon: icon, style: .compact)
    }
    
    /// Creates a subtle inline error view with no background
    static func subtle(_ message: String, icon: String = "exclamationmark.triangle") -> InlineErrorView {
        InlineErrorView(message: message, icon: icon, style: .subtle)
    }
}

// MARK: - View Extension for Conditional Display

extension View {
    /// Conditionally displays an inline error view below this view
    func inlineError(_ message: String?, style: InlineErrorView.ErrorStyle = .standard) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            self
            
            if let message = message {
                InlineErrorView(message: message, style: style)
                    .padding(.top, 4)
            }
        }
    }
    
    /// Conditionally displays a compact inline error view below this view
    func compactError(_ message: String?) -> some View {
        inlineError(message, style: .compact)
    }
    
    /// Conditionally displays a subtle inline error view below this view
    func subtleError(_ message: String?) -> some View {
        inlineError(message, style: .subtle)
    }
}

// MARK: - Preview

#Preview("Error Styles") {
    let theme = DefaultTheme()
    
    VStack(spacing: theme.spacing24) {
        // Standard style
        InlineErrorView(message: "Please enter a valid email address")
        
        // Compact style
        InlineErrorView.compact("Password is too short")
        
        // Subtle style
        InlineErrorView.subtle("Passwords don't match")
        
        // Long message test
        InlineErrorView(message: "This is a much longer error message to test how the component handles text wrapping and layout when the content spans multiple lines.")
        
        // Usage with view extension
        VStack {
            Rectangle()
                .fill(theme.backgroundSecondary)
                .frame(height: 44)
                .cornerRadius(theme.cornerRadiusSmall)
                .inlineError("Standard error message below component")
            
            Rectangle()
                .fill(theme.backgroundSecondary)
                .frame(height: 44)
                .cornerRadius(theme.cornerRadiusSmall)
                .compactError("Compact error message")
            
            Rectangle()
                .fill(theme.backgroundSecondary)
                .frame(height: 44)
                .cornerRadius(theme.cornerRadiusSmall)
                .subtleError("Subtle error message")
        }
    }
    .padding(theme.spacing16)
    .background(theme.backgroundPrimary)
    .environment(\.theme, theme)
}


