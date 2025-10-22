//
//  InfoCard.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/22/25.
//

import SwiftUI

struct InfoCard: View {
    @Environment(\.theme) var theme
    
    let title: String
    let content: String
    let icon: String?
    
    init(title: String, content: String, icon: String? = nil) {
        self.title = title
        self.content = content
        self.icon = icon
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing12) {
            HStack(spacing: theme.spacing12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(theme.title3)
                        .foregroundColor(theme.primaryMedium)
                }
                
                Text(title)
                    .font(theme.headline)
                    .foregroundColor(theme.textPrimary)
            }
            
            Text(content)
                .font(theme.body)
                .foregroundColor(theme.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing16)
        .card()
    }
}


#Preview {
    @Previewable @Environment(\.theme) var theme
    InfoCard(title: "Test Card Title", content: "Test Card Content.  This content is really great.  It is quite possibly the greatest content ever.  I have seen much content in my life but never any content quite like this.  I believe it is the greatest content ever.", icon: "exclamationmark.circle")
}
