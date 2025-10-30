//
//  GuestLogFirestoreService.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/30/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// Service for managing guest log entries in Firestore
/// Provides CRUD operations and real-time updates
@Observable
class GuestLogFirestoreService {
    
    // MARK: - Properties
    
    /// Published array of guest log entries that automatically updates the UI
    private(set) var entries: [GuestLogEntry] = []
    
    /// Loading state for UI feedback
    private(set) var isLoading = false
    
    /// Error state for UI error handling
    private(set) var lastError: Error?
    
    // MARK: - Private Properties
    
    private let db = Firestore.firestore()
    private let collectionName = "guestLogEntries"
    private var listener: ListenerRegistration?
    
    // MARK: - Initialization
    
    init() {
        startListening()
    }
    
    deinit {
        stopListening()
    }
    
    // MARK: - Public Methods
    
    /// Add a new guest log entry to Firestore (requires authentication)
    /// - Parameter entry: The guest log entry to add
    /// - Throws: Error if the operation fails or user is not authenticated
    func addEntry(_ entry: GuestLogEntry) async throws {
        // Check if user is authenticated
        guard let currentUser = Auth.auth().currentUser else {
            throw GuestLogError.notAuthenticated
        }
        
        // Verify the entry's userId matches the current user
        guard entry.userId == currentUser.uid else {
            throw GuestLogError.unauthorizedAccess
        }
        
        do {
            let data = entry.toFirestoreData()
            _ = try await db.collection(collectionName).addDocument(data: data)
            print("✅ Successfully added guest log entry for: \(entry.name) by user: \(currentUser.uid)")
        } catch {
            print("❌ Failed to add guest log entry: \(error)")
            await MainActor.run {
                self.lastError = error
            }
            throw error
        }
    }
    
    /// Manually fetch all entries (useful for pull-to-refresh)
    func fetchEntries() async {
        await MainActor.run {
            self.isLoading = true
            self.lastError = nil
        }
        
        do {
            let snapshot = try await db.collection(collectionName)
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            let fetchedEntries = snapshot.documents.compactMap { document in
                GuestLogEntry(from: document.data(), documentId: document.documentID)
            }
            
            await MainActor.run {
                self.entries = fetchedEntries
                self.isLoading = false
            }
            
            print("✅ Successfully fetched \(fetchedEntries.count) guest log entries")
            
        } catch {
            print("❌ Failed to fetch guest log entries: \(error)")
            await MainActor.run {
                self.lastError = error
                self.isLoading = false
            }
        }
    }
    
    /// Start listening for real-time updates from Firestore
    private func startListening() {
        print("🎧 Starting to listen for guest log updates...")
        
        listener = db.collection(collectionName)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Firestore listener error: \(error)")
                    Task { @MainActor in
                        self.lastError = error
                        self.isLoading = false
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No documents in snapshot")
                    return
                }
                
                let entries = documents.compactMap { document in
                    GuestLogEntry(from: document.data(), documentId: document.documentID)
                }
                
                Task { @MainActor in
                    self.entries = entries
                    self.isLoading = false
                    print("🔄 Updated guest log entries: \(entries.count) entries")
                }
            }
    }
    
    /// Stop listening for real-time updates
    private func stopListening() {
        listener?.remove()
        listener = nil
        print("🔇 Stopped listening for guest log updates")
    }
    
    /// Clear the last error (useful for UI error dismissal)
    func clearError() {
        lastError = nil
    }
    
    /// Set an error (useful for external error reporting)
    func setError(_ error: Error) {
        lastError = error
    }
}

// MARK: - Error Types

/// Specific errors for guest log operations
enum GuestLogError: LocalizedError {
    case addFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case invalidData
    case notAuthenticated
    case unauthorizedAccess
    
    var errorDescription: String? {
        switch self {
        case .addFailed:
            return "Failed to save your guest log entry"
        case .fetchFailed:
            return "Failed to load guest log entries"
        case .invalidData:
            return "Invalid guest log data"
        case .notAuthenticated:
            return "You must be signed in to add a guest log entry"
        case .unauthorizedAccess:
            return "You are not authorized to perform this action"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .addFailed, .fetchFailed:
            return "Please check your internet connection and try again"
        case .invalidData:
            return "Please verify your information and try again"
        case .notAuthenticated:
            return "Please sign in to your account first"
        case .unauthorizedAccess:
            return "Please contact support if this error persists"
        }
    }
}