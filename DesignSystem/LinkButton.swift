//
//  LinkButton.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/22/25.
//

import SwiftUI

struct LinkButton: View {
    @Environment(\.theme) var theme
    
    let icon: String
    let title: String
    let url: URL
    
    var body: some View {
        Link(destination: url) {
            HStack(spacing: theme.spacing12) {
                Image(systemName: icon)
                    .font(theme.title3)
                    .foregroundColor(theme.primaryMedium)
                    .frame(width: 32, height: 32)
                
                Text(title)
                    .font(theme.body)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(theme.subheadline)
                    .foregroundColor(theme.textTertiary)
            }
            .padding(theme.spacing16)
            .card()
        }
    }
}


#Preview {
    LinkButton(
        icon: "link.circle.fill",
        title: "GitHub Profile",
        url: URL(string: "https://github.com/bmantzey")!
    )}
