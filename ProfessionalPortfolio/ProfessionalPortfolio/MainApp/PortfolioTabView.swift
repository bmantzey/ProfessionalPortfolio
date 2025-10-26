//
//  PortfolioTabView.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/26/25.
//

import SwiftUI

struct PortfolioTabView: View {
    var body: some View {
        TabView {
            AboutMe()
                .tabItem {
                    Label("About Me", systemImage: "person.circle")
                }
            
            GuestLog()
                .tabItem {
                    Label("Guest Log", systemImage: "book.closed")
                }
            
            Resume()
                .tabItem {
                    Label("Resume", systemImage: "doc.text")
                }
        }
    }
}

#Preview {
    PortfolioTabView()
}