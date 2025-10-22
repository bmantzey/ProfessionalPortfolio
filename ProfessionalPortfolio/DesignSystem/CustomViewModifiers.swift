//
//  CustomViewModifiers.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/22/25.
//

import SwiftUI

struct CardModifier: ViewModifier {
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        content
            .background(theme.backgroundTertiary)
            .cornerRadius(theme.cornerRadiusMedium)
            .shadow(color: theme.shadowColor, radius: theme.shadowRadius, x: 0, y: 2)
    }
}

struct ElevatedCardModifier: ViewModifier {
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        content
            .background(theme.backgroundTertiary)
            .cornerRadius(theme.cornerRadiusLarge)
            .shadow(color: theme.shadowColor, radius: theme.shadowRadius * 1.5, x: 0, y: 4)
    }
}

extension View {
    func card() -> some View {
        modifier(CardModifier())
    }
    
    func elevatedCard() -> some View {
        modifier(ElevatedCardModifier())
    }
}
