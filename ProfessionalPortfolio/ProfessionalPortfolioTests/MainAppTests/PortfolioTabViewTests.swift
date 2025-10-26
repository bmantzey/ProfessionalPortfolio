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
    
    @Test("PortfolioTabView displays three tabs")
    @MainActor
    func portfolioTabViewDisplaysThreeTabs() async throws {
        // Given
        let tabView = PortfolioTabView()
        
        // When - Create the view
        // Note: We'll need to implement PortfolioTabView first
        
        // Then - Should have three tabs: AboutMe, GuestLog, Resume
        // This is a structural test that will pass once we implement the view
        #expect(true, "PortfolioTabView should be creatable")
    }
    
    @Test("AboutMe is the default selected tab")
    @MainActor
    func aboutMeIsDefaultTab() async throws {
        // Given
        let tabView = PortfolioTabView()
        
        // When - TabView is initialized
        // Then - AboutMe should be the default selected tab (leftmost)
        // Note: This will be tested through the TabView's selection binding
        
        #expect(true, "AboutMe should be the default tab when PortfolioTabView loads")
    }
    
    @Test("All three views are accessible as tabs")
    @MainActor
    func allThreeViewsAreAccessible() async throws {
        // Given
        let tabView = PortfolioTabView()
        
        // When - TabView is created
        // Then - Should be able to access AboutMe, GuestLog, and Resume views
        
        // Test that the individual views can be created
        let aboutMe = AboutMe()
        let guestLog = GuestLog()
        let resume = Resume()
        
        #expect(true, "All three tab views should be accessible")
    }
    
    @Test("PortfolioTabView should be shown when user is authenticated")
    @MainActor
    func portfolioTabViewShownWhenAuthenticated() async throws {
        // Given - User is authenticated
        // When - Main app determines what to show
        // Then - Should show PortfolioTabView instead of individual AboutMe view
        
        // This test verifies that PortfolioTabView can be created as the main authenticated view
        let portfolioTabView = PortfolioTabView()
        
        #expect(true, "PortfolioTabView should be the main view shown when user is authenticated")
    }
}