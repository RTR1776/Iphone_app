//
//  PriceAlertService.swift
//  PawnShopAssistant
//
//  Price monitoring and alerting system
//
//  SETUP REQUIRED for Push Notifications:
//  1. Enable Push Notifications capability in Xcode
//  2. Configure APNs in Firebase Console
//  3. Add UserNotifications framework
//

import Foundation
import SwiftUI
// import UserNotifications (uncomment when ready)

@MainActor
class PriceAlertService: ObservableObject {
    static let shared = PriceAlertService()

    @Published var alerts: [PriceAlert] = []
    @Published var isMonitoring = false

    private let ebayService = EbayAPIService()
    private var monitoringTimer: Timer?

    private init() {
        loadAlerts()
        requestNotificationPermissions()
    }

    // MARK: - Alert Management

    func createAlert(for item: PawnItem, percentageChange: Double = 10.0) {
        guard let user = FirebaseService.shared.currentUser,
              let shopID = FirebaseService.shared.currentShop?.id,
              let currentPrice = item.marketValue ?? item.ebayAveragePrice else {
            return
        }

        let alert = PriceAlert(
            itemID: item.id.uuidString,
            itemName: item.itemName,
            category: item.category,
            userID: user.id,
            shopID: shopID,
            originalPrice: currentPrice,
            percentageChange: percentageChange
        )

        alerts.append(alert)
        saveAlerts()

        // Sync to cloud
        Task {
            try? await syncAlertToCloud(alert)
        }
    }

    func updateAlert(_ alert: PriceAlert) {
        if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[index] = alert
            saveAlerts()

            Task {
                try? await syncAlertToCloud(alert)
            }
        }
    }

    func deleteAlert(_ alert: PriceAlert) {
        alerts.removeAll { $0.id == alert.id }
        saveAlerts()

        Task {
            try? await deleteCloudAlert(alert)
        }
    }

    func toggleAlert(_ alert: PriceAlert) {
        var updated = alert
        updated.isActive = !updated.isActive
        updateAlert(updated)
    }

    // MARK: - Monitoring

    func startMonitoring(interval: TimeInterval = 3600) { // Default: 1 hour
        guard !isMonitoring else { return }

        isMonitoring = true

        // Check immediately
        Task {
            await checkAllAlerts()
        }

        // Then schedule periodic checks
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkAllAlerts()
            }
        }

        print("Price monitoring started (interval: \(interval/3600) hours)")
    }

    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        isMonitoring = false
        print("Price monitoring stopped")
    }

    private func checkAllAlerts() async {
        let activeAlerts = alerts.filter { $0.isActive && !$0.notificationSent }

        print("Checking \(activeAlerts.count) active price alerts...")

        for alert in activeAlerts {
            await checkAlert(alert)
        }

        saveAlerts()
    }

    private func checkAlert(_ alert: PriceAlert) async {
        // Get current market price
        do {
            let inventory = InventoryManager.shared
            guard let item = inventory.items.first(where: { $0.id.uuidString == alert.itemID }) else {
                return
            }

            // Fetch latest price
            let searchQuery = "\(item.brand ?? "") \(item.model ?? "") \(item.itemName)"
            let pricingData = try await ebayService.fetchRealPricing(query: searchQuery, category: item.category)

            guard let currentPrice = pricingData.averagePrice else {
                return
            }

            // Update alert with new price
            var updatedAlert = alert
            updatedAlert.currentPrice = currentPrice
            updatedAlert.lastCheckedDate = Date()

            // Check if alert should trigger
            if updatedAlert.shouldTrigger {
                updatedAlert.triggeredDate = Date()
                updatedAlert.notificationSent = true

                // Send notification
                await sendNotification(for: updatedAlert, item: item)

                // Update item in inventory with new price
                var updatedItem = item
                updatedItem.ebayAveragePrice = currentPrice
                updatedItem.marketValue = currentPrice
                updatedItem.lastPriceUpdate = Date()
                inventory.updateItem(updatedItem)
            }

            updateAlert(updatedAlert)

        } catch {
            print("Error checking alert for \(alert.itemName): \(error)")
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermissions() {
        // Production:
        /*
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permissions granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
        */
    }

    private func sendNotification(for alert: PriceAlert, item: PawnItem) async {
        let title: String
        let body: String

        let change = alert.priceChange
        let changeAbs = abs(change)

        if change > 0 {
            title = "💰 Price Increased: \(alert.itemName)"
            body = String(format: "$%.2f → $%.2f (+%.1f%%) - Good time to sell!", alert.originalPrice, alert.currentPrice, changeAbs)
        } else {
            title = "📉 Price Decreased: \(alert.itemName)"
            body = String(format: "$%.2f → $%.2f (-%.1f%%) - Market softening", alert.originalPrice, alert.currentPrice, changeAbs)
        }

        // Production:
        /*
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: alerts.filter { $0.notificationSent }.count)
        content.userInfo = ["alertID": alert.id, "itemID": alert.itemID]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: alert.id, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
        */

        print("📱 Notification sent: \(title)")

        // Log activity
        FirebaseService.shared.logActivity(
            .setPriceAlert,
            itemID: alert.itemID,
            itemName: alert.itemName,
            details: body
        )
    }

    // MARK: - Batch Operations

    func createAlertsForAllInventory(threshold: Double = 10.0) {
        let inventory = InventoryManager.shared.items.filter { $0.status == .inStock }

        for item in inventory {
            // Skip if alert already exists
            if alerts.contains(where: { $0.itemID == item.id.uuidString }) {
                continue
            }

            createAlert(for: item, percentageChange: threshold)
        }

        print("Created alerts for \(inventory.count) items")
    }

    func clearTriggeredAlerts() {
        alerts.removeAll { $0.notificationSent }
        saveAlerts()
    }

    func resetAlert(_ alert: PriceAlert) {
        var updated = alert
        updated.notificationSent = false
        updated.triggeredDate = nil
        updated.originalPrice = updated.currentPrice
        updateAlert(updated)
    }

    // MARK: - Analytics

    func getAlertStatistics() -> AlertStatistics {
        let active = alerts.filter { $0.isActive }
        let triggered = alerts.filter { $0.notificationSent }

        let byCategory = Dictionary(grouping: alerts) { $0.category }
            .mapValues { $0.count }

        var priceChanges: [String: Double] = [:]
        for alert in alerts {
            priceChanges[alert.itemName] = alert.priceChange
        }

        return AlertStatistics(
            totalAlerts: alerts.count,
            activeAlerts: active.count,
            triggeredAlerts: triggered.count,
            alertsByCategory: byCategory,
            averagePriceChange: priceChanges.values.reduce(0, +) / Double(max(priceChanges.count, 1))
        )
    }

    // MARK: - Persistence

    private func saveAlerts() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(alerts) {
            let url = getFileURL()
            try? data.write(to: url)
        }
    }

    private func loadAlerts() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let url = getFileURL()
        if let data = try? Data(contentsOf: url),
           let loaded = try? decoder.decode([PriceAlert].self, from: data) {
            alerts = loaded
        }
    }

    private func getFileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("price_alerts.json")
    }

    // MARK: - Cloud Sync

    private func syncAlertToCloud(_ alert: PriceAlert) async throws {
        // Production:
        /*
        let db = Firestore.firestore()
        try db.collection("shops").document(alert.shopID)
            .collection("priceAlerts").document(alert.id)
            .setData(from: alert)
        */
    }

    private func deleteCloudAlert(_ alert: PriceAlert) async throws {
        // Production:
        /*
        let db = Firestore.firestore()
        try await db.collection("shops").document(alert.shopID)
            .collection("priceAlerts").document(alert.id)
            .delete()
        */
    }

    func syncFromCloud() async throws {
        guard let shopID = FirebaseService.shared.currentShop?.id else { return }

        // Production:
        /*
        let db = Firestore.firestore()
        let snapshot = try await db.collection("shops").document(shopID)
            .collection("priceAlerts")
            .getDocuments()

        let cloudAlerts = snapshot.documents.compactMap { try? $0.data(as: PriceAlert.self) }

        await MainActor.run {
            alerts = cloudAlerts
            saveAlerts()
        }
        */
    }
}

// MARK: - Statistics

struct AlertStatistics {
    var totalAlerts: Int
    var activeAlerts: Int
    var triggeredAlerts: Int
    var alertsByCategory: [ItemCategory: Int]
    var averagePriceChange: Double

    var triggeredPercentage: Double {
        guard totalAlerts > 0 else { return 0 }
        return (Double(triggeredAlerts) / Double(totalAlerts)) * 100
    }
}

// MARK: - Background Task (iOS)

extension PriceAlertService {
    /// Register background task for price checking
    /// Call this in AppDelegate or main app init
    func registerBackgroundTask() {
        // Production:
        /*
        import BackgroundTasks

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.pawnshop.pricecheck",
            using: nil
        ) { task in
            self.handleBackgroundPriceCheck(task: task as! BGAppRefreshTask)
        }
        */
    }

    private func handleBackgroundPriceCheck(task: Any) {
        // Production:
        /*
        Task {
            await checkAllAlerts()

            task.setTaskCompleted(success: true)

            // Schedule next check
            scheduleBackgroundCheck()
        }
        */
    }

    func scheduleBackgroundCheck() {
        // Production:
        /*
        let request = BGAppRefreshTaskRequest(identifier: "com.pawnshop.pricecheck")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // 1 hour

        try? BGTaskScheduler.shared.submit(request)
        */
    }
}

// MARK: - Smart Recommendations

extension PriceAlertService {
    /// Suggest items that should have price alerts based on value and volatility
    func suggestAlertsForItems() -> [PawnItem] {
        let inventory = InventoryManager.shared.items.filter { $0.status == .inStock }

        // High-value items without alerts
        let highValue = inventory.filter { item in
            let value = item.marketValue ?? item.purchasePrice
            return value > 500 && !alerts.contains(where: { $0.itemID == item.id.uuidString })
        }

        return highValue.sorted { ($0.marketValue ?? $0.purchasePrice) > ($1.marketValue ?? $1.purchasePrice) }
    }

    /// Recommend alert threshold based on item category
    func recommendedThreshold(for category: ItemCategory) -> Double {
        switch category {
        case .electronics:
            return 8.0 // Electronics depreciate quickly
        case .watches, .jewelry:
            return 5.0 // Luxury items more stable
        case .collectibles:
            return 15.0 // Collectibles volatile
        case .vehicles:
            return 10.0 // Vehicles seasonal
        default:
            return 10.0 // Default 10%
        }
    }
}
