//
//  GuestLogEntry.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/29/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class GuestLogEntry {
    var id: UUID
    var name: String
    var companyOrAbout: String
    var message: String
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    
    init(name: String, companyOrAbout: String, message: String, latitude: Double, longitude: Double) {
        self.id = UUID()
        self.name = name
        self.companyOrAbout = companyOrAbout
        self.message = message
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = Date()
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}
