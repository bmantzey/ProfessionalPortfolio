//
//  LinkIcon.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/27/25.
//

import SwiftUI

struct LinkIcon: View {
    @Environment(\.theme) var theme
    
    let icon: String
    let url: URL
    
    var body: some View {
        Link(destination: url) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
        }
    }
}


#Preview {
    LinkIcon(
        icon: "linkedin_icon",
        url: URL(string: "https://github.com/bmantzey")!
    )}
