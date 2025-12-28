//
//  PawnItem.swift
//  PawnShopAssistant
//
//  Comprehensive pawn shop item model
//

import Foundation
import SwiftUI

// MARK: - Main Item Model
struct PawnItem: Identifiable, Codable {
    var id: UUID
    var createdDate: Date
    var modifiedDate: Date

    // Basic Info
    var itemID: String?              // Bravo ticket number
    var itemName: String
    var category: ItemCategory
    var brand: String?
    var model: String?
    var serialNumber: String?
    var description: String

    // Transaction Info
    var transactionType: TransactionType
    var transactionDate: Date
    var customerName: String?
    var customerID: String?

    // Financial
    var purchasePrice: Double        // What you paid/loaned
    var marketValue: Double?         // AI estimated market value
    var suggestedLoanAmount: Double? // AI recommendation
    var suggestedBuyPrice: Double?   // AI recommendation
    var actualSalePrice: Double?     // What you sold it for
    var profit: Double?              // Calculated profit
    var profitMargin: Double?        // Profit %

    // eBay Market Data
    var ebayAveragePrice: Double?
    var ebayRecentSales: [EbaySale]?
    var ebayListingCount: Int?
    var lastPriceUpdate: Date?

    // AI Analysis
    var aiAnalysis: String?
    var authenticityScore: Int?      // 0-100
    var authenticityStatus: AuthenticityStatus?
    var condition: ItemCondition?
    var riskLevel: RiskLevel?
    var estimatedTimeToSell: String? // "2-4 weeks"

    // Status
    var status: ItemStatus
    var dueDate: Date?               // For pawn loans
    var redemptionDate: Date?
    var saleDate: Date?

    // Media
    var photos: [Data]               // Stored as Data (JPEG)
    var primaryPhotoIndex: Int

    // Metadata
    var notes: String?
    var employeeName: String?
    var tags: [String]
    var isFlagged: Bool              // For items needing review
    var flagReason: String?

    init(
        id: UUID = UUID(),
        itemName: String,
        category: ItemCategory = .other,
        description: String = "",
        transactionType: TransactionType = .pawn,
        transactionDate: Date = Date(),
        purchasePrice: Double = 0,
        status: ItemStatus = .inStock,
        photos: [Data] = [],
        primaryPhotoIndex: Int = 0
    ) {
        self.id = id
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.itemName = itemName
        self.category = category
        self.description = description
        self.transactionType = transactionType
        self.transactionDate = transactionDate
        self.purchasePrice = purchasePrice
        self.status = status
        self.photos = photos
        self.primaryPhotoIndex = primaryPhotoIndex
        self.tags = []
        self.isFlagged = false
        self.ebayRecentSales = []
    }

    // Computed property for primary photo
    var primaryPhoto: Data? {
        guard !photos.isEmpty, primaryPhotoIndex < photos.count else { return nil }
        return photos[primaryPhotoIndex]
    }

    // Calculate profit if sold
    mutating func calculateProfit() {
        if let salePrice = actualSalePrice {
            profit = salePrice - purchasePrice
            if purchasePrice > 0 {
                profitMargin = (profit! / purchasePrice) * 100
            }
        }
    }
}

// MARK: - Enums

enum ItemCategory: String, Codable, CaseIterable {
    case jewelry = "Jewelry"
    case watches = "Watches"
    case electronics = "Electronics"
    case tools = "Tools"
    case firearms = "Firearms"
    case musical = "Musical Instruments"
    case gaming = "Gaming"
    case sports = "Sports Equipment"
    case collectibles = "Collectibles"
    case appliances = "Appliances"
    case vehicles = "Vehicles"
    case other = "Other"

    var icon: String {
        switch self {
        case .jewelry: return "💍"
        case .watches: return "⌚"
        case .electronics: return "📱"
        case .tools: return "🔧"
        case .firearms: return "🔫"
        case .musical: return "🎸"
        case .gaming: return "🎮"
        case .sports: return "⚽"
        case .collectibles: return "🏆"
        case .appliances: return "🔌"
        case .vehicles: return "🚗"
        case .other: return "📦"
        }
    }
}

enum TransactionType: String, Codable {
    case pawn = "Pawn"
    case buy = "Buy"
    case retail = "Retail"
    case consignment = "Consignment"
}

enum ItemStatus: String, Codable {
    case inStock = "In Stock"
    case sold = "Sold"
    case redeemed = "Redeemed"
    case forfeited = "Forfeited"
    case onHold = "On Hold"
    case pendingReview = "Pending Review"
}

enum ItemCondition: String, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case damaged = "Damaged"
    case unknown = "Unknown"

    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor, .damaged: return .red
        case .unknown: return .gray
        }
    }
}

enum AuthenticityStatus: String, Codable {
    case authentic = "Authentic"
    case likelyAuthentic = "Likely Authentic"
    case questionable = "Questionable"
    case likelyFake = "Likely Fake"
    case fake = "Fake"
    case unknown = "Unknown"

    var color: Color {
        switch self {
        case .authentic, .likelyAuthentic: return .green
        case .questionable: return .orange
        case .likelyFake, .fake: return .red
        case .unknown: return .gray
        }
    }

    static func from(score: Int) -> AuthenticityStatus {
        switch score {
        case 90...100: return .authentic
        case 75..<90: return .likelyAuthentic
        case 50..<75: return .questionable
        case 25..<50: return .likelyFake
        case 0..<25: return .fake
        default: return .unknown
        }
    }
}

enum RiskLevel: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

// MARK: - eBay Data Model

struct EbaySale: Codable, Identifiable {
    var id = UUID()
    var title: String
    var price: Double
    var saleDate: Date
    var condition: String?
    var url: String?
}

// MARK: - CSV Import Model

struct BravoCSVRow {
    var ticketNumber: String
    var date: Date?
    var customerName: String?
    var itemDescription: String
    var loanAmount: Double?
    var interestRate: Double?
    var dueDate: Date?
    var status: String?

    // Convert to PawnItem
    func toPawnItem() -> PawnItem {
        var item = PawnItem(
            itemName: extractItemName(from: itemDescription),
            description: itemDescription,
            transactionType: .pawn,
            transactionDate: date ?? Date(),
            purchasePrice: loanAmount ?? 0
        )

        item.itemID = ticketNumber
        item.customerName = customerName
        item.dueDate = dueDate
        item.status = mapStatus(status)
        item.category = guessCategory(from: itemDescription)

        return item
    }

    private func extractItemName(from description: String) -> String {
        // Take first 50 chars or until comma/dash
        let separators: [String] = [",", "-", "–"]
        var name = description

        for separator in separators {
            if let index = name.firstIndex(of: Character(separator)) {
                name = String(name[..<index])
                break
            }
        }

        return String(name.prefix(50).trimmingCharacters(in: .whitespaces))
    }

    private func mapStatus(_ status: String?) -> ItemStatus {
        guard let status = status?.lowercased() else { return .inStock }

        if status.contains("active") || status.contains("current") {
            return .inStock
        } else if status.contains("sold") {
            return .sold
        } else if status.contains("redeem") {
            return .redeemed
        } else if status.contains("forfeit") || status.contains("default") {
            return .forfeited
        } else {
            return .inStock
        }
    }

    private func guessCategory(from description: String) -> ItemCategory {
        let desc = description.lowercased()

        if desc.contains("ring") || desc.contains("necklace") || desc.contains("bracelet") ||
           desc.contains("gold") || desc.contains("diamond") || desc.contains("jewelry") {
            return .jewelry
        } else if desc.contains("watch") || desc.contains("rolex") || desc.contains("omega") {
            return .watches
        } else if desc.contains("iphone") || desc.contains("ipad") || desc.contains("laptop") ||
                  desc.contains("tv") || desc.contains("phone") || desc.contains("computer") {
            return .electronics
        } else if desc.contains("xbox") || desc.contains("playstation") || desc.contains("ps5") ||
                  desc.contains("nintendo") || desc.contains("game") {
            return .gaming
        } else if desc.contains("guitar") || desc.contains("drum") || desc.contains("piano") {
            return .musical
        } else if desc.contains("drill") || desc.contains("saw") || desc.contains("tool") {
            return .tools
        } else if desc.contains("gun") || desc.contains("rifle") || desc.contains("pistol") {
            return .firearms
        } else {
            return .other
        }
    }
}
