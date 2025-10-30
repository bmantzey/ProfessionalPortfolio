//
//  GuestLogEntry.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/29/25.
//

import Foundation
import CoreLocation
import FirebaseFirestore

/// A guest log entry model that works with Firestore
/// This represents a single entry in our guest log with location and user details
struct GuestLogEntry: Codable, Identifiable, Hashable {
    let id: String
    let userId: String  // Firebase Auth user ID
    var name: String
    var companyOrAbout: String
    var message: String
    let latitude: Double
    let longitude: Double
    var timestamp: Date
    let documentId: String? // Firestore document ID for updates
    
    init(userId: String, name: String, companyOrAbout: String, message: String, latitude: Double, longitude: Double) {
        self.id = UUID().uuidString
        self.userId = userId
        self.name = name
        self.companyOrAbout = companyOrAbout
        self.message = message
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = Date()
        self.documentId = nil
    }
    
    // Computed properties for CoreLocation integration
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // Formatted date for display in callouts
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy @ h:mm a zzz"
        return formatter.string(from: timestamp)
    }
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: GuestLogEntry, rhs: GuestLogEntry) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Firestore Extensions

extension GuestLogEntry {
    /// Initialize from Firestore document data
    init?(from data: [String: Any], documentId: String) {
        guard 
            let userId = data["userId"] as? String,
            let name = data["name"] as? String,
            let companyOrAbout = data["companyOrAbout"] as? String,
            let message = data["message"] as? String,
            let latitude = data["latitude"] as? Double,
            let longitude = data["longitude"] as? Double
        else {
            print("❌ Failed to parse guest log entry: missing required fields")
            print("Available data keys: \(data.keys)")
            return nil
        }
        
        // Handle Firestore timestamp - it could be a Timestamp or Date
        let timestamp: Date
        if let firestoreTimestamp = data["timestamp"] as? Timestamp {
            timestamp = firestoreTimestamp.dateValue()
        } else if let dateTimestamp = data["timestamp"] as? Date {
            timestamp = dateTimestamp
        } else {
            print("❌ Failed to parse timestamp from: \(data["timestamp"] ?? "nil")")
            return nil
        }
        
        self.id = documentId
        self.userId = userId
        self.name = name
        self.companyOrAbout = companyOrAbout
        self.message = message
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.documentId = documentId
        
        print("✅ Successfully parsed guest log entry: \(name) at (\(latitude), \(longitude))")
    }
    
    /// Convert to Firestore document data
    func toFirestoreData() -> [String: Any] {
        return [
            "userId": userId,
            "name": name,
            "companyOrAbout": companyOrAbout,
            "message": message,
            "latitude": latitude,
            "longitude": longitude,
            "timestamp": Timestamp(date: timestamp)  // Use Firestore Timestamp
        ]
    }
}
