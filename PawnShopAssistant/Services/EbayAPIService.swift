//
//  EbayAPIService.swift
//  PawnShopAssistant
//
//  Real eBay Finding API integration for accurate market pricing
//
//  SETUP REQUIRED:
//  1. Sign up for eBay Developer account: https://developer.ebay.com/
//  2. Create an app to get API credentials
//  3. Add EBAY_APP_ID to Config.xcconfig
//  4. For production: implement OAuth for higher rate limits
//

import Foundation

class EbayAPIService {
    // eBay Finding API endpoint
    private let findingAPIURL = "https://svcs.ebay.com/services/search/FindingService/v1"

    // Get from Config.xcconfig
    private var appID: String? {
        Bundle.main.object(forInfoDictionaryKey: "EBAY_APP_ID") as? String
    }

    // MARK: - Public API

    /// Fetch real eBay pricing data for an item
    func fetchRealPricing(query: String, category: ItemCategory? = nil) async throws -> EbayPricingData {
        // For now, check if we have real API credentials
        guard let appID = appID, !appID.isEmpty, appID != "your_ebay_app_id_here" else {
            // Fall back to simulated data if no real API key
            return simulatePricing(for: query)
        }

        // Real API call
        return try await fetchFromEbayAPI(query: query, category: category)
    }

    // MARK: - Real eBay API Implementation

    private func fetchFromEbayAPI(query: String, category: ItemCategory?) async throws -> EbayPricingData {
        guard let appID = appID else {
            throw EbayError.missingCredentials
        }

        // Build request URL
        var components = URLComponents(string: findingAPIURL)!

        // Standard parameters for Finding API
        var queryItems = [
            URLQueryItem(name: "OPERATION-NAME", value: "findCompletedItems"),
            URLQueryItem(name: "SERVICE-VERSION", value: "1.0.0"),
            URLQueryItem(name: "SECURITY-APPNAME", value: appID),
            URLQueryItem(name: "RESPONSE-DATA-FORMAT", value: "JSON"),
            URLQueryItem(name: "REST-PAYLOAD", value: ""),
            URLQueryItem(name: "keywords", value: query),
            URLQueryItem(name: "paginationInput.entriesPerPage", value: "100"),
            URLQueryItem(name: "sortOrder", value: "EndTimeSoonest")
        ]

        // Filter for sold items only
        queryItems.append(URLQueryItem(name: "itemFilter(0).name", value: "SoldItemsOnly"))
        queryItems.append(URLQueryItem(name: "itemFilter(0).value", value: "true"))

        // Filter by category if provided
        if let category = category {
            if let ebayCategory = mapToEbayCategory(category) {
                queryItems.append(URLQueryItem(name: "categoryId", value: ebayCategory))
            }
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw EbayError.invalidURL
        }

        // Make request
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EbayError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw EbayError.apiError(code: httpResponse.statusCode)
        }

        // Parse response
        return try parseEbayResponse(data: data)
    }

    // MARK: - Response Parsing

    private func parseEbayResponse(data: Data) throws -> EbayPricingData {
        struct EbayResponse: Codable {
            let findCompletedItemsResponse: [FindingResponse]

            struct FindingResponse: Codable {
                let searchResult: [SearchResult]?

                struct SearchResult: Codable {
                    let item: [EbayItem]?

                    struct EbayItem: Codable {
                        let title: [String]?
                        let sellingStatus: [SellingStatus]?
                        let listingInfo: [ListingInfo]?
                        let condition: [ItemCondition]?
                        let viewItemURL: [String]?

                        struct SellingStatus: Codable {
                            let convertedCurrentPrice: [Price]?

                            struct Price: Codable {
                                let __value__: String?
                            }
                        }

                        struct ListingInfo: Codable {
                            let endTime: [String]?
                        }

                        struct ItemCondition: Codable {
                            let conditionDisplayName: [String]?
                        }
                    }
                }
            }
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(EbayResponse.self, from: data)

        guard let items = response.findCompletedItemsResponse.first?.searchResult?.first?.item else {
            return EbayPricingData(averagePrice: nil, recentSales: [], listingCount: 0)
        }

        // Parse items into sales
        var sales: [EbaySale] = []
        var prices: [Double] = []

        for item in items {
            guard let title = item.title?.first,
                  let priceString = item.sellingStatus?.first?.convertedCurrentPrice?.first?.__value__,
                  let price = Double(priceString) else {
                continue
            }

            let dateFormatter = ISO8601DateFormatter()
            let saleDate = item.listingInfo?.first?.endTime?.first
                .flatMap { dateFormatter.date(from: $0) } ?? Date()

            let sale = EbaySale(
                title: title,
                price: price,
                saleDate: saleDate,
                condition: item.condition?.first?.conditionDisplayName?.first,
                url: item.viewItemURL?.first
            )

            sales.append(sale)
            prices.append(price)
        }

        // Calculate average
        let averagePrice = prices.isEmpty ? nil : prices.reduce(0, +) / Double(prices.count)

        return EbayPricingData(
            averagePrice: averagePrice,
            recentSales: Array(sales.prefix(10)), // Top 10 most recent
            listingCount: sales.count
        )
    }

    // MARK: - Category Mapping

    private func mapToEbayCategory(_ category: ItemCategory) -> String? {
        // eBay category IDs
        switch category {
        case .jewelry: return "281" // Jewelry & Watches
        case .watches: return "31387" // Wristwatches
        case .electronics: return "293" // Consumer Electronics
        case .tools: return "631" // Hand Tools
        case .firearms: return "73956" // Sporting Goods > Hunting
        case .musical: return "619" // Musical Instruments
        case .gaming: return "1249" // Video Games
        case .sports: return "888" // Sporting Goods
        case .collectibles: return "1" // Collectibles
        case .appliances: return "20710" // Home Appliances
        case .vehicles: return "6001" // eBay Motors
        case .other: return nil
        }
    }

    // MARK: - Simulated Data (Fallback)

    private func simulatePricing(for query: String) -> EbayPricingData {
        let q = query.lowercased()
        let basePrice = estimateBasePrice(from: q)

        // Generate realistic sales data
        let salesCount = Int.random(in: 5...25)
        var sales: [EbaySale] = []

        for i in 0..<min(salesCount, 10) {
            let variation = Double.random(in: 0.85...1.15)
            let price = basePrice * variation

            let daysAgo = Int.random(in: 1...30)
            let saleDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!

            let sale = EbaySale(
                title: query,
                price: price,
                saleDate: saleDate,
                condition: ["New", "Like New", "Excellent", "Good", "Used"].randomElement()
            )

            sales.append(sale)
        }

        let avgPrice = sales.isEmpty ? basePrice : sales.map { $0.price }.reduce(0, +) / Double(sales.count)

        return EbayPricingData(
            averagePrice: avgPrice,
            recentSales: sales,
            listingCount: salesCount
        )
    }

    private func estimateBasePrice(from query: String) -> Double {
        let q = query.lowercased()

        // Electronics
        if q.contains("iphone") {
            if q.contains("15") || q.contains("16") { return 750 }
            if q.contains("14") || q.contains("13") { return 550 }
            if q.contains("12") || q.contains("11") { return 350 }
            return 250
        }
        if q.contains("ipad") {
            if q.contains("pro") { return 600 }
            if q.contains("air") { return 400 }
            return 300
        }
        if q.contains("macbook") {
            if q.contains("pro") { return 1200 }
            if q.contains("air") { return 800 }
            return 600
        }
        if q.contains("xbox") || q.contains("playstation") {
            if q.contains("series x") || q.contains("ps5") { return 450 }
            return 300
        }
        if q.contains("nintendo") {
            if q.contains("switch") { return 250 }
            return 150
        }

        // Watches
        if q.contains("rolex") {
            if q.contains("submariner") || q.contains("daytona") { return 12000 }
            if q.contains("datejust") { return 8000 }
            return 6000
        }
        if q.contains("omega") { return 3500 }
        if q.contains("tag heuer") || q.contains("breitling") { return 2500 }
        if q.contains("apple watch") {
            if q.contains("ultra") { return 600 }
            return 300
        }

        // Jewelry
        if q.contains("gold") {
            if q.contains("ring") { return 600 }
            if q.contains("necklace") || q.contains("chain") { return 800 }
            if q.contains("bracelet") { return 500 }
            return 400
        }
        if q.contains("diamond") {
            if q.contains("ring") { return 1500 }
            return 1000
        }

        // Tools
        if q.contains("dewalt") || q.contains("milwaukee") {
            if q.contains("drill") { return 150 }
            if q.contains("saw") { return 200 }
            return 120
        }

        // Musical
        if q.contains("guitar") {
            if q.contains("gibson") || q.contains("fender") { return 1200 }
            return 400
        }
        if q.contains("piano") || q.contains("keyboard") { return 800 }

        // Default
        return 150
    }
}

// MARK: - Data Structures

struct EbayPricingData {
    var averagePrice: Double?
    var recentSales: [EbaySale]
    var listingCount: Int

    var formattedAverage: String {
        guard let price = averagePrice else { return "N/A" }
        return String(format: "$%.2f", price)
    }

    var priceRange: (min: Double, max: Double)? {
        guard !recentSales.isEmpty else { return nil }
        let prices = recentSales.map { $0.price }
        return (min: prices.min() ?? 0, max: prices.max() ?? 0)
    }

    var confidence: ConfidenceLevel {
        switch listingCount {
        case 0: return .none
        case 1...5: return .low
        case 6...15: return .medium
        case 16...50: return .high
        default: return .veryHigh
        }
    }

    enum ConfidenceLevel: String {
        case none = "No Data"
        case low = "Low Confidence"
        case medium = "Medium Confidence"
        case high = "High Confidence"
        case veryHigh = "Very High Confidence"
    }
}

// MARK: - Errors

enum EbayError: Error, LocalizedError {
    case missingCredentials
    case invalidURL
    case invalidResponse
    case apiError(code: Int)
    case parsingError

    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "eBay API credentials not configured"
        case .invalidURL:
            return "Invalid eBay API URL"
        case .invalidResponse:
            return "Invalid response from eBay"
        case .apiError(let code):
            return "eBay API error (code: \(code))"
        case .parsingError:
            return "Failed to parse eBay response"
        }
    }
}

// MARK: - Advanced Features

extension EbayAPIService {
    /// Get price trends over time
    func getPriceTrends(query: String, days: Int = 30) async throws -> PriceTrend {
        let data = try await fetchRealPricing(query: query)

        // Group sales by week
        var weeklyAverages: [Date: Double] = [:]

        for sale in data.recentSales {
            let weekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: sale.saleDate))!

            if weeklyAverages[weekStart] == nil {
                weeklyAverages[weekStart] = sale.price
            } else {
                weeklyAverages[weekStart] = (weeklyAverages[weekStart]! + sale.price) / 2
            }
        }

        let sortedWeeks = weeklyAverages.sorted { $0.key < $1.key }
        let trend = calculateTrend(from: sortedWeeks.map { $0.value })

        return PriceTrend(
            weeklyPrices: weeklyAverages,
            trend: trend,
            currentAverage: data.averagePrice ?? 0
        )
    }

    private func calculateTrend(from prices: [Double]) -> TrendDirection {
        guard prices.count >= 2 else { return .stable }

        let first = prices.prefix(prices.count / 2).reduce(0, +) / Double(prices.count / 2)
        let last = prices.suffix(prices.count / 2).reduce(0, +) / Double(prices.count / 2)

        let change = ((last - first) / first) * 100

        if change > 5 { return .increasing }
        if change < -5 { return .decreasing }
        return .stable
    }
}

struct PriceTrend {
    var weeklyPrices: [Date: Double]
    var trend: TrendDirection
    var currentAverage: Double

    var changePercentage: Double {
        let prices = weeklyPrices.values.sorted()
        guard prices.count >= 2 else { return 0 }

        let first = prices.first!
        let last = prices.last!

        return ((last - first) / first) * 100
    }
}

enum TrendDirection: String {
    case increasing = "Increasing"
    case decreasing = "Decreasing"
    case stable = "Stable"

    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var color: String {
        switch self {
        case .increasing: return "green"
        case .decreasing: return "red"
        case .stable: return "gray"
        }
    }
}
