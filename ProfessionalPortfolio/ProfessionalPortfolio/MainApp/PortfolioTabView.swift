//
//  PortfolioTabView.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/26/25.
//

import SwiftUI

enum Tab: CaseIterable {
    case aboutMe
    case guestLog
    case resume
}

struct PortfolioTabView: View {
    @State private var selectedTab: Tab = .aboutMe
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AboutMe(selectedTab: $selectedTab)
                .tabItem {
                    Label("About Me", systemImage: "person.circle")
                }
                .tag(Tab.aboutMe)
            
            GuestLog()
                .tabItem {
                    Label("Guest Log", systemImage: "book.closed")
                }
                .tag(Tab.guestLog)
            
            Resume()
                .tabItem {
                    Label("Resume", systemImage: "doc.text")
                }
                .tag(Tab.resume)
        }
    }
}

#Preview {
    PortfolioTabView()
}