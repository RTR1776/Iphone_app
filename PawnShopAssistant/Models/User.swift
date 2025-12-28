//
//  User.swift
//  PawnShopAssistant
//
//  Multi-user authentication and roles
//

import Foundation
import SwiftUI

// MARK: - User Model

struct User: Identifiable, Codable {
    var id: String // Firebase UID
    var email: String
    var name: String
    var role: UserRole
    var shopID: String // Multiple shops can use the app
    var createdDate: Date
    var lastLoginDate: Date
    var isActive: Bool
    var photoURL: String?

    // Permissions
    var permissions: UserPermissions

    // Statistics
    var totalItemsAnalyzed: Int
    var totalValueProcessed: Double
    var accuracy: Double? // For training mode

    init(
        id: String,
        email: String,
        name: String,
        role: UserRole,
        shopID: String
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role
        self.shopID = shopID
        self.createdDate = Date()
        self.lastLoginDate = Date()
        self.isActive = true
        self.permissions = UserPermissions.defaults(for: role)
        self.totalItemsAnalyzed = 0
        self.totalValueProcessed = 0
    }

    var displayName: String {
        name.isEmpty ? email : name
    }
}

// MARK: - User Roles

enum UserRole: String, Codable, CaseIterable {
    case owner = "Owner"
    case manager = "Manager"
    case employee = "Employee"
    case viewer = "Viewer"

    var icon: String {
        switch self {
        case .owner: return "crown.fill"
        case .manager: return "star.fill"
        case .employee: return "person.fill"
        case .viewer: return "eye.fill"
        }
    }

    var color: Color {
        switch self {
        case .owner: return .purple
        case .manager: return .blue
        case .employee: return .green
        case .viewer: return .gray
        }
    }
}

// MARK: - Permissions

struct UserPermissions: Codable {
    var canAnalyzeItems: Bool
    var canEditItems: Bool
    var canDeleteItems: Bool
    var canImportCSV: Bool
    var canExportData: Bool
    var canManageUsers: Bool
    var canViewReports: Bool
    var canSetPriceAlerts: Bool
    var canAccessAllItems: Bool // Or only their own
    var canModifySettings: Bool

    static func defaults(for role: UserRole) -> UserPermissions {
        switch role {
        case .owner:
            return UserPermissions(
                canAnalyzeItems: true,
                canEditItems: true,
                canDeleteItems: true,
                canImportCSV: true,
                canExportData: true,
                canManageUsers: true,
                canViewReports: true,
                canSetPriceAlerts: true,
                canAccessAllItems: true,
                canModifySettings: true
            )
        case .manager:
            return UserPermissions(
                canAnalyzeItems: true,
                canEditItems: true,
                canDeleteItems: true,
                canImportCSV: true,
                canExportData: true,
                canManageUsers: false,
                canViewReports: true,
                canSetPriceAlerts: true,
                canAccessAllItems: true,
                canModifySettings: false
            )
        case .employee:
            return UserPermissions(
                canAnalyzeItems: true,
                canEditItems: true,
                canDeleteItems: false,
                canImportCSV: false,
                canExportData: false,
                canManageUsers: false,
                canViewReports: false,
                canSetPriceAlerts: false,
                canAccessAllItems: false,
                canModifySettings: false
            )
        case .viewer:
            return UserPermissions(
                canAnalyzeItems: false,
                canEditItems: false,
                canDeleteItems: false,
                canImportCSV: false,
                canExportData: false,
                canManageUsers: false,
                canViewReports: true,
                canSetPriceAlerts: false,
                canAccessAllItems: true,
                canModifySettings: false
            )
        }
    }
}

// MARK: - Shop Model

struct Shop: Identifiable, Codable {
    var id: String
    var name: String
    var address: String?
    var phone: String?
    var ownerID: String
    var createdDate: Date
    var isActive: Bool

    // Settings
    var loanPercentages: LoanSettings
    var categories: [String] // Custom categories
    var priceAlertSettings: PriceAlertSettings

    init(id: String, name: String, ownerID: String) {
        self.id = id
        self.name = name
        self.ownerID = ownerID
        self.createdDate = Date()
        self.isActive = true
        self.loanPercentages = LoanSettings()
        self.categories = []
        self.priceAlertSettings = PriceAlertSettings()
    }
}

// MARK: - Settings

struct LoanSettings: Codable {
    var electronics: (min: Double, max: Double) = (0.40, 0.50)
    var jewelry: (min: Double, max: Double) = (0.50, 0.60)
    var tools: (min: Double, max: Double) = (0.30, 0.40)
    var firearms: (min: Double, max: Double) = (0.60, 0.70)
    var general: (min: Double, max: Double) = (0.40, 0.50)
}

struct PriceAlertSettings: Codable {
    var enabled: Bool = true
    var priceChangeThreshold: Double = 10.0 // % change
    var checkFrequency: Int = 24 // hours
    var notifyOnIncrease: Bool = true
    var notifyOnDecrease: Bool = true
}

// MARK: - Activity Log

struct ActivityLog: Identifiable, Codable {
    var id: String
    var userID: String
    var userName: String
    var action: ActivityAction
    var itemID: String?
    var itemName: String?
    var details: String?
    var timestamp: Date
    var shopID: String

    init(
        userID: String,
        userName: String,
        action: ActivityAction,
        itemID: String? = nil,
        itemName: String? = nil,
        details: String? = nil,
        shopID: String
    ) {
        self.id = UUID().uuidString
        self.userID = userID
        self.userName = userName
        self.action = action
        self.itemID = itemID
        self.itemName = itemName
        self.details = details
        self.timestamp = Date()
        self.shopID = shopID
    }
}

enum ActivityAction: String, Codable {
    case login = "Logged In"
    case logout = "Logged Out"
    case analyzedItem = "Analyzed Item"
    case addedItem = "Added Item"
    case editedItem = "Edited Item"
    case deletedItem = "Deleted Item"
    case importedCSV = "Imported CSV"
    case exportedData = "Exported Data"
    case setPriceAlert = "Set Price Alert"
    case soldItem = "Sold Item"
    case redeemedItem = "Redeemed Item"
}

// MARK: - Price Alert

struct PriceAlert: Identifiable, Codable {
    var id: String
    var itemID: String
    var itemName: String
    var category: ItemCategory
    var userID: String
    var shopID: String

    var originalPrice: Double
    var currentPrice: Double
    var targetPrice: Double? // Alert when reaches this price
    var percentageChange: Double // Alert on % change

    var alertOnIncrease: Bool
    var alertOnDecrease: Bool

    var isActive: Bool
    var createdDate: Date
    var lastCheckedDate: Date?
    var triggeredDate: Date?
    var notificationSent: Bool

    init(
        itemID: String,
        itemName: String,
        category: ItemCategory,
        userID: String,
        shopID: String,
        originalPrice: Double,
        percentageChange: Double = 10.0
    ) {
        self.id = UUID().uuidString
        self.itemID = itemID
        self.itemName = itemName
        self.category = category
        self.userID = userID
        self.shopID = shopID
        self.originalPrice = originalPrice
        self.currentPrice = originalPrice
        self.percentageChange = percentageChange
        self.alertOnIncrease = true
        self.alertOnDecrease = true
        self.isActive = true
        self.createdDate = Date()
        self.notificationSent = false
    }

    var priceChange: Double {
        ((currentPrice - originalPrice) / originalPrice) * 100
    }

    var shouldTrigger: Bool {
        guard isActive, !notificationSent else { return false }

        let change = abs(priceChange)
        let increasing = currentPrice > originalPrice

        if increasing && alertOnIncrease && change >= percentageChange {
            return true
        }

        if !increasing && alertOnDecrease && change >= percentageChange {
            return true
        }

        if let target = targetPrice {
            if alertOnIncrease && currentPrice >= target {
                return true
            }
            if alertOnDecrease && currentPrice <= target {
                return true
            }
        }

        return false
    }
}
