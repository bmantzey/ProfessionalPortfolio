//
//  Item.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/20/25.
//

import Foundation
import SwiftData

// Temporary class used for stubbing out SwiftData in the ProfessionalPortfolioApp View, which is the @main entry point into the app.
@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
