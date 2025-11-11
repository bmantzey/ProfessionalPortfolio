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

enum MapStyleType {
    case standard
    case hybrid
    case imagery
}

struct GuestLog: View {
    @State private var guestLogService = GuestLogFirestoreService()
    @State private var showingSignSheet = false
    @State private var nameText = ""
    @State private var companyText = ""
    @State private var messageText = ""
    @State private var isSubmitting = false
    @State private var mapCameraPosition = MapCameraPosition.automatic
    @State private var selectedEntry: GuestLogEntry?
    @State private var isShowingUserEntry = false
    @State private var isMapAnimating = false
    @State private var mapStyle: MapStyle = .standard()
    @State private var selectedMapStyleType: MapStyleType = .standard
    @State private var isShowingMapStylePicker = false
    
    // Use shared location manager that persists
    private let locationManager = LocationManager.shared
    
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
        .navigationTitle(String(localized: "Guest Log"))
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
        .alert(String(localized: "Error"), isPresented: .constant(guestLogService.lastError != nil)) {
            Button(String(localized: "OK")) {
                guestLogService.clearError()
            }
        } message: {
            Text(guestLogService.lastError?.localizedDescription ?? String(localized: "An unknown error occurred"))
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
                Marker(entry.name.isEmpty ? "" : entry.name, coordinate: entry.coordinate)
                    .tint(isCurrentUserEntry(entry) ? .red : .blue)
                    .tag(entry)
            }
        }
        .mapStyle(mapStyle)
        .ignoresSafeArea(edges: .bottom) // Allow map to extend under safe area
        .mapControls {
            MapScaleView()
            MapCompass()
        }
        .overlay(alignment: .topLeading) {
            mapStyleToggleButton
                .padding(.top, 8)
                .padding(.leading, 16)
        }
        .overlay(
            Group {
                if guestLogService.isLoading && guestLogService.entries.isEmpty {
                    ProgressView(String(localized: "Loading guest entries..."))
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                }
            }
        )
        .sheet(item: $selectedEntry) { entry in
            NavigationStack {
                GuestLogDetailView(
                    entry: entry,
                    guestLogService: guestLogService,
                    onDismiss: {
                        selectedEntry = nil
                    }
                )
                .navigationTitle(String(localized: "Guest Entry"))
                .navigationBarTitleDisplayMode(.inline)
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
            return String(localized: "Sign My Guest Log")
        } else if isShowingUserEntry {
            return String(localized: "Show All Entries")
        } else {
            return String(localized: "Go To My Entry")
        }
    }
    
    private var mapStyleToggleButton: some View {
        Menu {
            Button(action: { 
                mapStyle = .standard()
                selectedMapStyleType = .standard
            }) {
                Label(String(localized: "Standard"), systemImage: selectedMapStyleType == .standard ? "checkmark" : "")
            }
            
            Button(action: { 
                mapStyle = .hybrid()
                selectedMapStyleType = .hybrid
            }) {
                Label(String(localized: "Hybrid"), systemImage: selectedMapStyleType == .hybrid ? "checkmark" : "")
            }
            
            Button(action: { 
                mapStyle = .imagery()
                selectedMapStyleType = .imagery
            }) {
                Label(String(localized: "Satellite"), systemImage: selectedMapStyleType == .imagery ? "checkmark" : "")
            }
        } label: {
            Image(systemName: "map")
                .font(.title2)
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
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
    let guestLogService: GuestLogFirestoreService
    let onDismiss: () -> Void
    
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedCompany = ""
    @State private var editedMessage = ""
    @State private var isSubmittingEdit = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    
    /// Check if this entry belongs to the current user
    private var isCurrentUserEntry: Bool {
        guard let currentUser = FirebaseAuth.Auth.auth().currentUser else { return false }
        return entry.userId == currentUser.uid
    }
    
    /// Get the current version of this entry from the service
    private var currentEntry: GuestLogEntry {
        return guestLogService.entries.first { $0.id == entry.id } ?? entry
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isEditing {
                editingView
            } else {
                readOnlyView
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            // Initialize edit fields with current values
            editedName = currentEntry.name
            editedCompany = currentEntry.companyOrAbout
            editedMessage = currentEntry.message
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isCurrentUserEntry {
                    if isEditing {
                        Button(String(localized: "Cancel")) {
                            // Reset to original values
                            editedName = currentEntry.name
                            editedCompany = currentEntry.companyOrAbout
                            editedMessage = currentEntry.message
                            isEditing = false
                        }
                    } else {
                        HStack(spacing: 16) {
                            Button {
                                isEditing = true
                            } label: {
                                Image(systemName: "square.and.pencil")
                            }
                            .disabled(isDeleting)
                            
                            Button {
                                showingDeleteConfirmation = true
                            } label: {
                                Image(systemName: "trash")
                            }
                            .disabled(isDeleting)
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? String(localized: "Save") : String(localized: "Done")) {
                    if isEditing {
                        Task {
                            await saveEdits()
                        }
                    } else {
                        onDismiss()
                    }
                }
                .disabled(isSubmittingEdit || isDeleting)
            }
        }
        .confirmationDialog(
            String(localized: "Delete Entry"),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete"), role: .destructive) {
                Task {
                    await deleteEntry()
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "Are you sure you want to delete your guest log entry? This action cannot be undone."))
        }
    }
    
    private var readOnlyView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Name"))
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(currentEntry.name)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            if !currentEntry.companyOrAbout.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Company/About"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(currentEntry.companyOrAbout)
                        .font(.body)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Message"))
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(currentEntry.message)
                    .font(.body)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Date"))
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(currentEntry.formattedDate)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var editingView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Name"))
                    .font(.headline)
                    .foregroundColor(.secondary)
                TextField(String(localized: "Your name"), text: $editedName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Company/About"))
                    .font(.headline)
                    .foregroundColor(.secondary)
                TextField(String(localized: "Company or tell us about yourself"), text: $editedCompany)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Message"))
                    .font(.headline)
                    .foregroundColor(.secondary)
                TextEditor(text: $editedMessage)
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary, lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Date"))
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(currentEntry.formattedDate)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var isFormValid: Bool {
        !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !editedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    @MainActor
    private func saveEdits() async {
        guard isFormValid else { return }
        
        isSubmittingEdit = true
        
        do {
            // Create updated entry with current timestamp
            var updatedEntry = currentEntry
            updatedEntry.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedEntry.companyOrAbout = editedCompany.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedEntry.message = editedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedEntry.timestamp = Date() // Update to current date/time
            
            try await guestLogService.updateEntry(updatedEntry)
            
            isEditing = false
            print("✅ Successfully updated guest log entry")
            
        } catch {
            print("❌ Failed to update guest log entry: \(error)")
            // Error will be shown via the alert in the main view
        }
        
        isSubmittingEdit = false
    }
    
    @MainActor
    private func deleteEntry() async {
        isDeleting = true
        
        do {
            try await guestLogService.deleteEntry(currentEntry)
            print("✅ Successfully deleted guest log entry")
            onDismiss()
        } catch {
            print("❌ Failed to delete guest log entry: \(error)")
            // Error will be shown via the alert in the main view
        }
        
        isDeleting = false
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
            Text(String(localized: "Name:"))
                .font(.subheadline)
                .fontWeight(.medium)
            TextField(String(localized: "Your name"), text: $nameText)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct CompanyField: View {
    @Binding var companyText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Company/About You:"))
                .font(.subheadline)
                .fontWeight(.medium)
            TextField(String(localized: "Company or tell us about yourself"), text: $companyText)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct MessageField: View {
    @Binding var messageText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Message:"))
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
    
    var body: some View {
        VStack(spacing: 16) {
            NameField(nameText: $nameText)
            CompanyField(companyText: $companyText)
            MessageField(messageText: $messageText)
            
            Button(String(localized: "Sign Guest Log")) {
                Task {
                    await onSubmit()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSubmitting)
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
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(String(localized: "Sign Guest Log"))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if locationManager.authorizationStatus == .notDetermined {
                    VStack(spacing: 16) {
                        Image(systemName: "location.circle")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                        
                        Text(String(localized: "Location Required"))
                            .font(.headline)
                        
                        Text(String(localized: "We need your location to add you to the guest log. This will only be requested once."))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button(String(localized: "Allow Location Access")) {
                            locationManager.requestLocationForSigning()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                    
                } else if locationManager.authorizationStatus == .denied {
                    VStack(spacing: 16) {
                        Image(systemName: "location.slash")
                            .font(.system(size: 64))
                            .foregroundColor(.red)
                        
                        Text(String(localized: "Location Access Denied"))
                            .font(.headline)
                        
                        Text(String(localized: "Please enable location access in Settings to sign the guest log."))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button(String(localized: "Open Settings")) {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    
                } else if locationManager.isRequestingLocation {
                    VStack(spacing: 16) {
                        ProgressView()
                            .controlSize(.large)
                        
                        Text(String(localized: "Getting your location..."))
                            .font(.headline)
                        
                        Text(String(localized: "This may take a moment"))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                } else if let error = locationManager.locationError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 64))
                            .foregroundColor(.orange)
                        
                        Text(String(localized: "Location Error"))
                            .font(.headline)
                        
                        Text(error.localizedDescription)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button(String(localized: "Try Again")) {
                            locationManager.requestLocationForSigning()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    
                } else if locationManager.location != nil {
                    // Show the form once we have location
                    ScrollView {
                        GuestLogFormFields(
                            nameText: $nameText,
                            companyText: $companyText,
                            messageText: $messageText,
                            isSubmitting: $isSubmitting,
                            onSubmit: onSubmit
                        )
                    }
                } else {
                    // This shouldn't happen, but just in case
                    VStack(spacing: 16) {
                        Text(String(localized: "Ready to sign"))
                            .font(.headline)
                        
                        Button(String(localized: "Get Location")) {
                            locationManager.requestLocationForSigning()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    GuestLog()
}

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    var location: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var locationError: Error?
    var isRequestingLocation = false
    
    override init() {
        super.init()
        manager.delegate = self
        authorizationStatus = manager.authorizationStatus
        // DON'T request permission here - only when explicitly needed
    }
    
    func requestLocationPermission() {
        print("Requesting location permission...")
        print("Current status: \(manager.authorizationStatus)")
        manager.requestWhenInUseAuthorization()
    }
    
    /// Request location once - only call this when actually signing the guest log
    func requestLocationForSigning() {
        guard !isRequestingLocation else {
            print("Already requesting location...")
            return
        }
        
        locationError = nil
        isRequestingLocation = true
        
        switch manager.authorizationStatus {
        case .notDetermined:
            print("Requesting location permission for signing...")
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("Permission already granted, requesting location...")
            manager.requestLocation()
        case .denied, .restricted:
            print("Location permission denied/restricted")
            locationError = LocationError.permissionDenied
            isRequestingLocation = false
        @unknown default:
            print("Unknown authorization status")
            locationError = LocationError.unknown
            isRequestingLocation = false
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("Authorization changed to: \(manager.authorizationStatus)")
        authorizationStatus = manager.authorizationStatus
        
        // Only request location if we're currently in the signing flow
        if isRequestingLocation && (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways) {
            print("Permission granted during signing flow, requesting location...")
            manager.requestLocation()
        } else if isRequestingLocation && (authorizationStatus == .denied || authorizationStatus == .restricted) {
            print("Permission denied during signing flow")
            locationError = LocationError.permissionDenied
            isRequestingLocation = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let firstLoc = locations.first ?? CLLocation(latitude: 0.0, longitude: 0.0)
        print("Got location: \(firstLoc.coordinate)")
        location = firstLoc
        isRequestingLocation = false
        locationError = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        locationError = error
        isRequestingLocation = false
    }
}

enum LocationError: Error, LocalizedError {
    case permissionDenied
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return String(localized: "Location permission was denied. Please enable it in Settings to sign the guest log.")
        case .unknown:
            return String(localized: "An unknown location error occurred.")
        }
    }
}
