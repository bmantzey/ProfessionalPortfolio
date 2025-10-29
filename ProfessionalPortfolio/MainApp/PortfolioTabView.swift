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
    @State private var resumeRefreshTrigger = 0
    
    var body: some View {
        TabView(selection: Binding(
            get: { selectedTab },
            set: { newTab in
                if selectedTab == .resume && newTab == .resume {
                    // Resume tab tapped while already selected - trigger refresh
                    resumeRefreshTrigger += 1
                } else {
                    selectedTab = newTab
                }
            }
        )) {
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
                .id(resumeRefreshTrigger) // This will recreate the Resume view when refreshTrigger changes
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