//
//  GuestLog.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/26/25.
//

import SwiftUI
import MapKit
import CoreLocation
import FirebaseAuth

// TODO: Figure out the best implementation of a map view.
/*
 Want to have a "Sign My Guest Log" link in a space somewhere on the screen that will:
 √ 1. Display the pins for all users that have signed the guest log.
 √ 2. Prompt for permission to use the user's location.
 √ 3. Present a text box that prompts them to “Introduce yourself, give feedback, or say anything."
 √ 4. Submit the GPS location and text feedback when submitted.
 5. Tapping on a pin will show the text feedback that was submitted by the user at that location.
 6. Have an AI summary of all user feedback displayed near where the button to sign the guest book is.
 */

struct GuestLog: View {
    @State private var guestLogService = GuestLogFirestoreService()
    @State private var showingSignSheet = false
    @State private var locationManager = LocationManager()
    @State private var nameText = ""
    @State private var companyText = ""
    @State private var messageText = ""
    @State private var isSubmitting = false
    @State private var mapCameraPosition = MapCameraPosition.automatic
    
    var body: some View {
        VStack {
            Map(position: $mapCameraPosition) {
                ForEach(guestLogService.entries) { entry in
                    Annotation("Guest Entry", coordinate: entry.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .frame(height: 400)
            .overlay(
                Group {
                    if guestLogService.isLoading && guestLogService.entries.isEmpty {
                        ProgressView("Loading guest entries...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                    }
                }
            )
            
            Button("Sign My Guest Log") {
                showingSignSheet = true
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle("Guest Log")
        .onAppear {
            // Fit all entries when view appears
            updateMapToFitAllEntries()
        }
        .onChange(of: guestLogService.entries.count) { _, _ in
            // Update map whenever entries count changes (including real-time updates)
            updateMapToFitAllEntries()
        }
        .alert("Error", isPresented: .constant(guestLogService.lastError != nil)) {
            Button("OK") {
                guestLogService.clearError()
            }
        } message: {
            Text(guestLogService.lastError?.localizedDescription ?? "An unknown error occurred")
        }
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
                            Task {
                                await submitGuestLogEntry()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                 messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                 isSubmitting)
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
    
    // MARK: - Private Methods
    
    /// Calculates the map region to fit all guest log entries
    private func updateMapToFitAllEntries() {
        guard !guestLogService.entries.isEmpty else {
            mapCameraPosition = .automatic
            return
        }
        
        let coordinates = guestLogService.entries.map { $0.coordinate }
        
        // Calculate the bounding box
        let minLatitude = coordinates.map { $0.latitude }.min() ?? 0
        let maxLatitude = coordinates.map { $0.latitude }.max() ?? 0
        let minLongitude = coordinates.map { $0.longitude }.min() ?? 0
        let maxLongitude = coordinates.map { $0.longitude }.max() ?? 0
        
        // Calculate center and span
        let centerLatitude = (minLatitude + maxLatitude) / 2
        let centerLongitude = (minLongitude + maxLongitude) / 2
        let center = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
        
        // Add padding to the span (20% extra on each side)
        let latitudeDelta = max((maxLatitude - minLatitude) * 1.4, 0.01) // Minimum span of 0.01
        let longitudeDelta = max((maxLongitude - minLongitude) * 1.4, 0.01) // Minimum span of 0.01
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        
        let region = MKCoordinateRegion(center: center, span: span)
        
        withAnimation(.easeInOut(duration: 1.0)) {
            mapCameraPosition = .region(region)
        }
    }
    
    /// Submits the guest log entry to Firestore (requires authentication)
    @MainActor
    private func submitGuestLogEntry() async {
        guard let location = locationManager.location else {
            print("❌ No location available for guest log entry")
            return
        }
        
        // Check if user is authenticated
        guard let currentUser = Auth.auth().currentUser else {
            guestLogService.setError(GuestLogError.notAuthenticated)
            print("❌ User not authenticated for guest log entry")
            return
        }
        
        isSubmitting = true
        
        do {
            let entry = GuestLogEntry(
                userId: currentUser.uid,
                name: nameText.trimmingCharacters(in: .whitespacesAndNewlines),
                companyOrAbout: companyText.trimmingCharacters(in: .whitespacesAndNewlines),
                message: messageText.trimmingCharacters(in: .whitespacesAndNewlines),
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            
            try await guestLogService.addEntry(entry)
            
            // Clear the form and close the sheet on success
            nameText = ""
            companyText = ""
            messageText = ""
            showingSignSheet = false
            
            // Update map to show all pins including the new one
            updateMapToFitAllEntries()
            
            print("✅ Successfully submitted guest log entry")
            
        } catch {
            print("❌ Failed to submit guest log entry: \(error)")
            // Error will be shown via the alert in the UI
        }
        
        isSubmitting = false
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
        let firstLoc = locations.first ?? CLLocation(latitude: 0.0, longitude: 0.0)
        print("Got location: \(firstLoc.coordinate)")
        location = firstLoc
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}
