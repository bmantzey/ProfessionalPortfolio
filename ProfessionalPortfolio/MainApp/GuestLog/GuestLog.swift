//
//  GuestLog.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/26/25.
//

import SwiftUI
import MapKit
import SwiftData
import CoreLocation

// TODO: Figure out the best implementation of a map view.
/*
 Want to have a "Sign My Guest Log" link in a space somewhere on the screen that will:
 1. Display the pins for all users that have signed the guest log.
 2. Prompt for permission to use the user's location.
 3. Present a text box that prompts them to “Introduce yourself, give feedback, or say anything."
 4. Submit the GPS location and text feedback when submitted.
 5. Tapping on a pin will show the text feedback that was submitted by the user at that location.
 6. Have an AI summary of all user feedback displayed near where the button to sign the guest book is.
 */

struct GuestLog: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [GuestLogEntry]
    @State private var showingSignSheet = false
    @State private var locationManager = LocationManager()
    @State private var nameText = ""
    @State private var companyText = ""
    @State private var messageText = ""
    
    var body: some View {
        VStack {
            Map {
                ForEach(entries, id: \.id) { entry in
                    Annotation("Guest Entry", coordinate: entry.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .frame(height: 400)
            
            Button("Sign My Guest Log") {
                showingSignSheet = true
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle("Guest Log")
        .sheet(isPresented: $showingSignSheet) {
            VStack {
                Text("Sign Guest Log")
                    .font(.title)
                    .padding()
                
                if locationManager.authorizationStatus == .notDetermined {
                    Text("We need your location to add you to the guest log.")
                        .padding()
                    
                    Button("Allow Location Access") {
                        locationManager.requestLocationPermission()
                    }
                    .buttonStyle(.borderedProminent)
                } else if locationManager.authorizationStatus == .denied {
                    Text("Location access was denied. Please enable it in Settings.")
                        .padding()
                } else if locationManager.location != nil {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Your name", text: $nameText)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Company/About You:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Company or tell us about yourself", text: $companyText)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextEditor(text: $messageText)
                                .frame(height: 120)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary, lineWidth: 1)
                                )
                        }
                        
                        Button("Sign Guest Log") {
                            if let location = locationManager.location {
                                let entry = GuestLogEntry(
                                    name: nameText,
                                    companyOrAbout: companyText,
                                    message: messageText,
                                    latitude: location.coordinate.latitude,
                                    longitude: location.coordinate.longitude
                                )
                                modelContext.insert(entry)
                                
                                // Clear the form and close the sheet
                                nameText = ""
                                companyText = ""
                                messageText = ""
                                showingSignSheet = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                 messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding()
                } else {
                    Text("Getting your location...")
                        .padding()
                }
            }
            .padding()
        }
    }
}

#Preview {
    GuestLog()
}

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var location: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        authorizationStatus = manager.authorizationStatus
        
        // Request permission once when the LocationManager is created
        if authorizationStatus == .notDetermined {
            requestLocationPermission()
        }
    }
    
    func requestLocationPermission() {
        print("Requesting location permission...")
        print("Current status: \(manager.authorizationStatus)")
        manager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("Authorization changed to: \(manager.authorizationStatus)")
        authorizationStatus = manager.authorizationStatus
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            print("Requesting location...")
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Got location: \(locations.first?.coordinate)")
        location = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}
