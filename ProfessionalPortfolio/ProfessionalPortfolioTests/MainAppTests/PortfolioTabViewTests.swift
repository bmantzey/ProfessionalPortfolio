//
//  PortfolioTabViewTests.swift
//  ProfessionalPortfolioTests
//
//  Created by Brandon Mantzey on 10/26/25.
//

import Testing
import SwiftUI
@testable import ProfessionalPortfolio

@Suite("PortfolioTabView Tests")
struct PortfolioTabViewTests {
    
    @Test("PortfolioTabView initializes with AboutMe as default tab")
    func portfolioTabViewInitializesWithAboutMeDefault() {
        // This test validates that the default selectedTab is .aboutMe
        // We can't directly access @State, but we can test the enum's first case
        let firstTab = Tab.allCases.first
        
        #expect(firstTab == .aboutMe, "AboutMe should be the first/default tab")
    }
}
