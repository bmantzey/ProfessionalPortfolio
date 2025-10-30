//
//  CustomTheme.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/22/25.
//

import SwiftUI

protocol AppTheme {
    // Primary Colors
    var primaryDark: Color { get }
    var primaryMedium: Color { get }
    var primaryLight: Color { get }
    
    // Background Colors
    var backgroundPrimary: Color { get }
    var backgroundSecondary: Color { get }
    var backgroundTertiary: Color { get }
    
    // Text Colors
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var textTertiary: Color { get }
    var textOnPrimary: Color { get }
    
    // Accent Colors
    var accentSuccess: Color { get }
    var accentWarning: Color { get }
    var accentError: Color { get }
    var accentInfo: Color { get }
    
    // Typography
    var largeTitle: Font { get }
    var title1: Font { get }
    var title2: Font { get }
    var title3: Font { get }
    var headline: Font { get }
    var body: Font { get }
    var callout: Font { get }
    var subheadline: Font { get }
    var footnote: Font { get }
    var caption: Font { get }
    
    // Spacing
    var spacing2: CGFloat { get }
    var spacing4: CGFloat { get }
    var spacing8: CGFloat { get }
    var spacing12: CGFloat { get }
    var spacing16: CGFloat { get }
    var spacing24: CGFloat { get }
    var spacing32: CGFloat { get }
    var spacing48: CGFloat { get }
    var spacing64: CGFloat { get }
    
    // Borders & Corners
    var cornerRadiusSmall: CGFloat { get }
    var cornerRadiusMedium: CGFloat { get }
    var cornerRadiusLarge: CGFloat { get }
    var borderWidthThin: CGFloat { get }
    var borderWidthMedium: CGFloat { get }
    
    // Shadows
    var shadowColor: Color { get }
    var shadowRadius: CGFloat { get }
}

struct DefaultTheme: AppTheme {
    // Primary Colors - Dark Blue spectrum
    let primaryDark = Color(red: 0.09, green: 0.16, blue: 0.28)      // #172740
    let primaryMedium = Color(red: 0.13, green: 0.24, blue: 0.42)    // #213D6B
    let primaryLight = Color(red: 0.24, green: 0.38, blue: 0.58)     // #3D6194
    
    // Background Colors - Adaptive to light/dark mode
    let backgroundPrimary = Color(.systemBackground)
    let backgroundSecondary = Color(.secondarySystemBackground)
    let backgroundTertiary = Color(.tertiarySystemBackground)
    
    // Text Colors - Adaptive to light/dark mode
    let textPrimary = Color(.label)
    let textSecondary = Color(.secondaryLabel)
    let textTertiary = Color(.tertiaryLabel)
    let textOnPrimary = Color.white
    
    // Accent Colors
    let accentSuccess = Color(red: 0.20, green: 0.73, blue: 0.45)    // #33BB72
    let accentWarning = Color(red: 0.95, green: 0.71, blue: 0.24)    // #F2B63D
    let accentError = Color(red: 0.92, green: 0.26, blue: 0.31)      // #EB424F
    let accentInfo = Color(red: 0.25, green: 0.59, blue: 0.96)       // #4096F5
    
    // Typography - Using SF Pro (iOS default)
    let largeTitle = Font.largeTitle.weight(.bold)
    let title1 = Font.title.weight(.semibold)
    let title2 = Font.title2.weight(.semibold)
    let title3 = Font.title3.weight(.semibold)
    let headline = Font.headline
    let body = Font.body
    let callout = Font.callout
    let subheadline = Font.subheadline
    let footnote = Font.footnote
    let caption = Font.caption
    
    // Spacing Scale
    let spacing2: CGFloat = 2
    let spacing4: CGFloat = 4
    let spacing8: CGFloat = 8
    let spacing12: CGFloat = 12
    let spacing16: CGFloat = 16
    let spacing24: CGFloat = 24
    let spacing32: CGFloat = 32
    let spacing48: CGFloat = 48
    let spacing64: CGFloat = 64
    
    // Borders & Corners
    let cornerRadiusSmall: CGFloat = 8
    let cornerRadiusMedium: CGFloat = 12
    let cornerRadiusLarge: CGFloat = 16
    let borderWidthThin: CGFloat = 1
    let borderWidthMedium: CGFloat = 2
    
    // Shadows - Adaptive to light/dark mode
    let shadowColor = Color(.systemGray4).opacity(0.3)
    let shadowRadius: CGFloat = 8
}

// MARK: - Environment Key for Theme

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = DefaultTheme()
}

extension EnvironmentValues {
    var theme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

