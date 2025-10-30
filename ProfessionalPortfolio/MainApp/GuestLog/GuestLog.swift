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

/*
TODO: LATER: Have an AI summary of all user feedback displayed near where the button to sign the guest book is.
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
    @State private var selectedEntry: GuestLogEntry?
    @State private var isShowingUserEntry = false
    @State private var isMapAnimating = false
    
    /// Computed property to check if current user has already signed
    private var hasCurrentUserSigned: Bool {
        guard let currentUser = Auth.auth().currentUser else { return false }
        return guestLogService.entries.contains { $0.userId == currentUser.uid }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            mapView
            signButton
        }
        .navigationTitle("Guest Log")
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                updateMapToFitAllEntries()
            }
        }
        .onChange(of: guestLogService.entries.count) { _, _ in
            withAnimation(.easeInOut(duration: 1.0)) {
                updateMapToFitAllEntries()
            }
        }
        .alert("Error", isPresented: .constant(guestLogService.lastError != nil)) {
            Button("OK") {
                guestLogService.clearError()
            }
        } message: {
            Text(guestLogService.lastError?.localizedDescription ?? "An unknown error occurred")
        }
        .sheet(isPresented: $showingSignSheet) {
            SignGuestLogSheetView(
                nameText: $nameText,
                companyText: $companyText,
                messageText: $messageText,
                isSubmitting: $isSubmitting,
                locationManager: locationManager,
                onSubmit: submitGuestLogEntry
            )
        }
    }
    
    private var mapView: some View {
        Map(position: $mapCameraPosition, selection: $selectedEntry) {
            ForEach(guestLogService.entries) { entry in
                Marker(entry.name, coordinate: entry.coordinate)
                    .tint(isCurrentUserEntry(entry) ? .red : .blue)
                    .tag(entry)
            }
        }
        .ignoresSafeArea(edges: .bottom) // Allow map to extend under safe area
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
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
        .sheet(item: $selectedEntry) { entry in
            NavigationStack {
                GuestLogDetailView(entry: entry)
                    .navigationTitle("Guest Entry")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                selectedEntry = nil
                            }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    private var signButton: some View {
        Button(buttonText) {
            if hasCurrentUserSigned {
                if isShowingUserEntry {
                    showAllEntries()
                } else {
                    zoomToCurrentUserEntry()
                }
            } else {
                showingSignSheet = true
            }
        }
        .font(.headline)
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.gradient)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .disabled(isMapAnimating)
        .opacity(isMapAnimating ? 0.6 : 1.0)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var buttonText: String {
        if !hasCurrentUserSigned {
            return "Sign My Guest Log"
        } else if isShowingUserEntry {
            return "Show All Entries"
        } else {
            return "Go To My Entry"
        }
    }
    
    // MARK: - Private Methods
    
    /// Checks if the given entry was made by the currently logged-in user
    private func isCurrentUserEntry(_ entry: GuestLogEntry) -> Bool {
        guard let currentUser = Auth.auth().currentUser else { return false }
        return entry.userId == currentUser.uid
    }
    
    /// Zooms the map to the current user's guest log entry within a ~15-mile radius
    private func zoomToCurrentUserEntry() {
        guard let currentUser = Auth.auth().currentUser,
              let userEntry = guestLogService.entries.first(where: { $0.userId == currentUser.uid }) else {
            print("❌ Could not find current user's entry")
            return
        }
        
        isMapAnimating = true
        
        // Create a region with approximately 15-mile radius
        // 1 degree latitude ≈ 69 miles, so 15 miles ≈ 0.217 degrees
        // Longitude varies by latitude, but we'll use the same approximation
        let span = MKCoordinateSpan(latitudeDelta: 0.217, longitudeDelta: 0.217)
        let region = MKCoordinateRegion(center: userEntry.coordinate, span: span)
        
        withAnimation(.easeInOut(duration: 1.0)) {
            mapCameraPosition = .region(region)
        }
        
        // Set state after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isShowingUserEntry = true
            isMapAnimating = false
        }
    }
    
    /// Shows all entries on the map
    private func showAllEntries() {
        isMapAnimating = true
        
        withAnimation(.easeInOut(duration: 1.0)) {
            updateMapToFitAllEntries()
        }
        
        // Set state after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isShowingUserEntry = false
            isMapAnimating = false
        }
    }
    
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
        
        mapCameraPosition = .region(region)
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
        
        // Check if user has already signed (double-check)
        if hasCurrentUserSigned {
            print("❌ User has already signed the guest log")
            showingSignSheet = false
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
            withAnimation(.easeInOut(duration: 1.0)) {
                updateMapToFitAllEntries()
            }
            
            print("✅ Successfully submitted guest log entry")
            
        } catch {
            print("❌ Failed to submit guest log entry: \(error)")
            // Error will be shown via the alert in the UI
        }
        
        isSubmitting = false
    }
}

// MARK: - Helper Views

struct GuestLogDetailView: View {
    let entry: GuestLogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(entry.name)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            if !entry.companyOrAbout.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Company/About")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(entry.companyOrAbout)
                        .font(.body)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Message")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(entry.message)
                    .font(.body)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Date")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(entry.formattedDate)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GuestLogCalloutView: View {
    let entry: GuestLogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.companyOrAbout)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(entry.message)
                .font(.body)
            
            Text(entry.formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: 200)
    }
}

struct NameField: View {
    @Binding var nameText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name:")
                .font(.subheadline)
                .fontWeight(.medium)
            TextField("Your name", text: $nameText)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct CompanyField: View {
    @Binding var companyText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Company/About You:")
                .font(.subheadline)
                .fontWeight(.medium)
            TextField("Company or tell us about yourself", text: $companyText)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct MessageField: View {
    @Binding var messageText: String
    
    var body: some View {
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
    }
}

struct GuestLogFormFields: View {
    @Binding var nameText: String
    @Binding var companyText: String
    @Binding var messageText: String
    @Binding var isSubmitting: Bool
    let onSubmit: () async -> Void
    
    private var isFormValid: Bool {
        !nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 16) {
            NameField(nameText: $nameText)
            CompanyField(companyText: $companyText)
            MessageField(messageText: $messageText)
            
            Button("Sign Guest Log") {
                Task {
                    await onSubmit()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isFormValid || isSubmitting)
        }
        .padding()
    }
}

struct SignGuestLogSheetView: View {
    @Binding var nameText: String
    @Binding var companyText: String
    @Binding var messageText: String
    @Binding var isSubmitting: Bool
    let locationManager: LocationManager
    let onSubmit: () async -> Void
    
    var body: some View {
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
                GuestLogFormFields(
                    nameText: $nameText,
                    companyText: $companyText,
                    messageText: $messageText,
                    isSubmitting: $isSubmitting,
                    onSubmit: onSubmit
                )
            } else {
                Text("Getting your location...")
                    .padding()
            }
        }
        .padding()
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
