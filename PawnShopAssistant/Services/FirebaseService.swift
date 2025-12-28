//
//  FirebaseService.swift
//  PawnShopAssistant
//
//  Firebase integration for auth, cloud sync, and real-time updates
//
//  SETUP REQUIRED:
//  1. Add Firebase SDK to project via SPM:
//     - https://github.com/firebase/firebase-ios-sdk
//  2. Add GoogleService-Info.plist from Firebase Console
//  3. Import packages: FirebaseAuth, FirebaseFirestore, FirebaseStorage
//

import Foundation
import SwiftUI

// NOTE: Uncomment these when Firebase SDK is added
// import FirebaseCore
// import FirebaseAuth
// import FirebaseFirestore
// import FirebaseStorage

@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var currentShop: Shop?

    private init() {
        // Configure Firebase
        // FirebaseApp.configure()
        // checkAuthStatus()
    }

    // MARK: - Authentication

    func signIn(email: String, password: String) async throws {
        // Production code:
        /*
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        try await loadUser(uid: result.user.uid)
        isAuthenticated = true
        logActivity(.login)
        */

        // Demo mode for now
        currentUser = User(
            id: "demo-user",
            email: email,
            name: "Demo User",
            role: .owner,
            shopID: "demo-shop"
        )
        isAuthenticated = true
    }

    func signUp(email: String, password: String, name: String, shopName: String) async throws {
        // Production code:
        /*
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let uid = result.user.uid

        // Create shop
        let shop = Shop(id: UUID().uuidString, name: shopName, ownerID: uid)
        try await saveShop(shop)

        // Create user
        let user = User(id: uid, email: email, name: name, role: .owner, shopID: shop.id)
        try await saveUser(user)

        currentUser = user
        currentShop = shop
        isAuthenticated = true
        logActivity(.login)
        */

        // Demo mode
        let shop = Shop(id: "demo-shop", name: shopName, ownerID: "demo-user")
        currentShop = shop

        currentUser = User(
            id: "demo-user",
            email: email,
            name: name,
            role: .owner,
            shopID: shop.id
        )
        isAuthenticated = true
    }

    func signOut() async throws {
        // Production: try Auth.auth().signOut()
        logActivity(.logout)
        currentUser = nil
        currentShop = nil
        isAuthenticated = false
    }

    func resetPassword(email: String) async throws {
        // Production: try await Auth.auth().sendPasswordReset(withEmail: email)
        print("Password reset email sent to \(email)")
    }

    private func checkAuthStatus() {
        // Production:
        /*
        if let firebaseUser = Auth.auth().currentUser {
            Task {
                try await loadUser(uid: firebaseUser.uid)
            }
        }
        */
    }

    // MARK: - User Management

    private func loadUser(uid: String) async throws {
        // Production:
        /*
        let db = Firestore.firestore()
        let doc = try await db.collection("users").document(uid).getDocument()

        if let user = try? doc.data(as: User.self) {
            currentUser = user
            isAuthenticated = true

            // Load shop
            try await loadShop(shopID: user.shopID)
        }
        */
    }

    private func saveUser(_ user: User) async throws {
        // Production:
        /*
        let db = Firestore.firestore()
        try db.collection("users").document(user.id).setData(from: user)
        */
    }

    func updateUser(_ user: User) async throws {
        // Production:
        /*
        try await saveUser(user)
        currentUser = user
        */
        currentUser = user
    }

    func inviteUser(email: String, name: String, role: UserRole) async throws -> User {
        guard let shop = currentShop else {
            throw FirebaseError.noShop
        }

        // Production:
        /*
        // Send invitation email
        let inviteID = UUID().uuidString
        let db = Firestore.firestore()

        let invitation: [String: Any] = [
            "email": email,
            "name": name,
            "role": role.rawValue,
            "shopID": shop.id,
            "invitedBy": currentUser?.id ?? "",
            "createdDate": Timestamp(date: Date()),
            "status": "pending"
        ]

        try await db.collection("invitations").document(inviteID).setData(invitation)
        */

        // Demo: Create user directly
        let newUser = User(
            id: UUID().uuidString,
            email: email,
            name: name,
            role: role,
            shopID: shop.id
        )

        return newUser
    }

    func getShopUsers() async throws -> [User] {
        guard let shopID = currentShop?.id else {
            return []
        }

        // Production:
        /*
        let db = Firestore.firestore()
        let snapshot = try await db.collection("users")
            .whereField("shopID", isEqualTo: shopID)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: User.self) }
        */

        // Demo
        return [currentUser].compactMap { $0 }
    }

    // MARK: - Shop Management

    private func loadShop(shopID: String) async throws {
        // Production:
        /*
        let db = Firestore.firestore()
        let doc = try await db.collection("shops").document(shopID).getDocument()

        if let shop = try? doc.data(as: Shop.self) {
            currentShop = shop
        }
        */
    }

    private func saveShop(_ shop: Shop) async throws {
        // Production:
        /*
        let db = Firestore.firestore()
        try db.collection("shops").document(shop.id).setData(from: shop)
        */
        currentShop = shop
    }

    func updateShop(_ shop: Shop) async throws {
        // Production: try await saveShop(shop)
        currentShop = shop
    }

    // MARK: - Inventory Sync

    func syncInventory() async throws {
        guard let shopID = currentShop?.id else {
            throw FirebaseError.noShop
        }

        // Production:
        /*
        let db = Firestore.firestore()

        // Upload local items to cloud
        let localItems = InventoryManager.shared.items

        for item in localItems {
            try db.collection("shops").document(shopID)
                .collection("inventory").document(item.id.uuidString)
                .setData(from: item)
        }

        // Download cloud items
        let snapshot = try await db.collection("shops").document(shopID)
            .collection("inventory").getDocuments()

        let cloudItems = snapshot.documents.compactMap { try? $0.data(as: PawnItem.self) }

        // Merge with local (cloud wins on conflicts)
        await MainActor.run {
            InventoryManager.shared.items = cloudItems
            InventoryManager.shared.saveItems()
        }
        */

        print("Inventory synced with cloud")
    }

    func syncItem(_ item: PawnItem) async throws {
        guard let shopID = currentShop?.id else { return }

        // Production:
        /*
        let db = Firestore.firestore()
        try db.collection("shops").document(shopID)
            .collection("inventory").document(item.id.uuidString)
            .setData(from: item)
        */
    }

    func deleteCloudItem(_ itemID: UUID) async throws {
        guard let shopID = currentShop?.id else { return }

        // Production:
        /*
        let db = Firestore.firestore()
        try await db.collection("shops").document(shopID)
            .collection("inventory").document(itemID.uuidString)
            .delete()
        */
    }

    func setupRealtimeSync() {
        guard let shopID = currentShop?.id else { return }

        // Production:
        /*
        let db = Firestore.firestore()

        db.collection("shops").document(shopID)
            .collection("inventory")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }

                let items = documents.compactMap { try? $0.data(as: PawnItem.self) }

                Task { @MainActor in
                    InventoryManager.shared.items = items
                }
            }
        */
    }

    // MARK: - Activity Logging

    func logActivity(_ action: ActivityAction, itemID: String? = nil, itemName: String? = nil, details: String? = nil) {
        guard let user = currentUser, let shopID = currentShop?.id else { return }

        let log = ActivityLog(
            userID: user.id,
            userName: user.displayName,
            action: action,
            itemID: itemID,
            itemName: itemName,
            details: details,
            shopID: shopID
        )

        // Production:
        /*
        let db = Firestore.firestore()
        try? db.collection("shops").document(shopID)
            .collection("activityLogs").document(log.id)
            .setData(from: log)
        */

        print("Activity logged: \(action.rawValue)")
    }

    func getActivityLogs(limit: Int = 100) async throws -> [ActivityLog] {
        guard let shopID = currentShop?.id else { return [] }

        // Production:
        /*
        let db = Firestore.firestore()
        let snapshot = try await db.collection("shops").document(shopID)
            .collection("activityLogs")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: ActivityLog.self) }
        */

        return []
    }

    // MARK: - Photo Storage

    func uploadPhoto(_ imageData: Data, itemID: UUID) async throws -> String {
        guard let shopID = currentShop?.id else {
            throw FirebaseError.noShop
        }

        // Production:
        /*
        let storage = Storage.storage()
        let path = "shops/\(shopID)/items/\(itemID.uuidString)/\(UUID().uuidString).jpg"
        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await ref.downloadURL()

        return downloadURL.absoluteString
        */

        return "demo-url://photo-\(itemID.uuidString)"
    }

    func deletePhoto(url: String) async throws {
        // Production:
        /*
        let storage = Storage.storage()
        let ref = storage.reference(forURL: url)
        try await ref.delete()
        */
    }
}

// MARK: - Errors

enum FirebaseError: Error, LocalizedError {
    case noShop
    case notAuthenticated
    case permissionDenied
    case networkError

    var errorDescription: String? {
        switch self {
        case .noShop: return "No shop selected"
        case .notAuthenticated: return "User not authenticated"
        case .permissionDenied: return "Permission denied"
        case .networkError: return "Network error occurred"
        }
    }
}
