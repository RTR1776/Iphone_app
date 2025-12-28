//
//  AIEnrichmentService.swift
//  PawnShopAssistant
//
//  AI-powered batch analysis and price enrichment
//

import Foundation
import UIKit

@MainActor
class AIEnrichmentService: ObservableObject {
    @Published var isProcessing = false
    @Published var currentProgress: (current: Int, total: Int) = (0, 0)
    @Published var currentItemName: String = ""
    @Published var currentAnalysis: String = ""

    private let claudeService = ClaudeAPIService()
    private let priceService = PriceLookupService()

    // MARK: - Batch Analysis

    /// Enriches multiple items with AI analysis and market pricing
    func enrichItems(
        _ items: [PawnItem],
        onItemUpdate: @escaping (PawnItem, Int) -> Void
    ) async throws -> [PawnItem] {
        isProcessing = true
        var enrichedItems = items
        currentProgress = (0, items.count)

        for (index, var item) in items.enumerated() {
            currentProgress = (index + 1, items.count)
            currentItemName = item.itemName

            do {
                // Get AI analysis
                item = try await analyzeItem(item)

                // Get market pricing
                item = try await fetchMarketPricing(item)

                enrichedItems[index] = item

                // Callback to update UI
                onItemUpdate(item, index)

                // Rate limiting - small delay between requests
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            } catch {
                print("Error enriching item \(item.itemName): \(error)")
                // Continue with next item even if this one fails
                item.notes = (item.notes ?? "") + "\nError: \(error.localizedDescription)"
                enrichedItems[index] = item
            }
        }

        isProcessing = false
        currentProgress = (0, 0)
        currentItemName = ""
        currentAnalysis = ""

        return enrichedItems
    }

    // MARK: - AI Analysis

    private func analyzeItem(_ item: PawnItem) async throws -> PawnItem {
        var enrichedItem = item

        // Create a text-based analysis query
        let itemDescription = """
        Item: \(item.itemName)
        Category: \(item.category.rawValue)
        \(item.brand != nil ? "Brand: \(item.brand!)" : "")
        \(item.model != nil ? "Model: \(item.model!)" : "")
        Description: \(item.description)
        Purchase Price: $\(item.purchasePrice)
        """

        let prompt = """
        You are an expert pawn shop analyst. Analyze this item:

        \(itemDescription)

        Provide a concise professional analysis with:
        1. Market value estimate
        2. Recommended loan amount (25-50% of value)
        3. Recommended buy price (50-70% of value)
        4. Authenticity assessment (score 0-100)
        5. Condition estimate
        6. Profit potential
        7. Risk factors

        Format your response as structured data we can parse.
        """

        // Use streaming for real-time updates
        let analysis = try await claudeService.analyzeText(prompt) { [weak self] partialText in
            Task { @MainActor in
                self?.currentAnalysis = partialText
            }
        }

        // Parse AI response and extract structured data
        enrichedItem = parseAIAnalysis(analysis, into: enrichedItem)
        enrichedItem.aiAnalysis = analysis

        return enrichedItem
    }

    private func parseAIAnalysis(_ analysis: String, into item: PawnItem) -> PawnItem {
        var result = item

        // Extract market value
        if let marketValue = extractValue(from: analysis, pattern: #"market value[:\s]*\$?([\d,]+)"#) {
            result.marketValue = marketValue
        }

        // Extract loan recommendation
        if let loanAmount = extractValue(from: analysis, pattern: #"loan[:\s]*\$?([\d,]+)"#) {
            result.suggestedLoanAmount = loanAmount
        }

        // Extract buy price recommendation
        if let buyPrice = extractValue(from: analysis, pattern: #"buy price[:\s]*\$?([\d,]+)"#) {
            result.suggestedBuyPrice = buyPrice
        }

        // Extract authenticity score
        if let authScore = extractAuthenticityScore(from: analysis) {
            result.authenticityScore = authScore
            result.authenticityStatus = AuthenticityStatus.from(score: authScore)
        }

        // Extract condition
        result.condition = extractCondition(from: analysis)

        // Extract risk level
        result.riskLevel = extractRiskLevel(from: analysis)

        // Calculate profit estimates
        if let marketValue = result.marketValue {
            let expectedSalePrice = marketValue * 0.9 // 90% of market
            let estimatedProfit = expectedSalePrice - item.purchasePrice
            result.profitMargin = (estimatedProfit / item.purchasePrice) * 100
        }

        return result
    }

    // MARK: - Market Pricing

    private func fetchMarketPricing(_ item: PawnItem) async throws -> PawnItem {
        var enrichedItem = item

        // Search eBay for similar items
        let searchQuery = "\(item.brand ?? "") \(item.model ?? "") \(item.itemName)".trimmingCharacters(in: .whitespaces)

        let ebayData = try await priceService.fetchEbayPricing(query: searchQuery)

        enrichedItem.ebayAveragePrice = ebayData.averagePrice
        enrichedItem.ebayRecentSales = ebayData.recentSales
        enrichedItem.ebayListingCount = ebayData.listingCount
        enrichedItem.lastPriceUpdate = Date()

        // If we got eBay data and no AI market value, use eBay average
        if enrichedItem.marketValue == nil, let ebayAvg = ebayData.averagePrice {
            enrichedItem.marketValue = ebayAvg
        }

        return enrichedItem
    }

    // MARK: - Parsing Helpers

    private func extractValue(from text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else {
            return nil
        }

        guard let valueRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        let valueString = String(text[valueRange]).replacingOccurrences(of: ",", with: "")
        return Double(valueString)
    }

    private func extractAuthenticityScore(from text: String) -> Int? {
        // Look for patterns like "90%", "Score: 85", etc.
        let patterns = [
            #"authenticity[:\s]*([\d]+)%"#,
            #"score[:\s]*([\d]+)"#,
            #"([\d]+)%\s*authentic"#
        ]

        for pattern in patterns {
            if let value = extractValue(from: text, pattern: pattern) {
                return Int(value)
            }
        }

        // Default heuristic based on keywords
        let lowercased = text.lowercased()
        if lowercased.contains("authentic") && !lowercased.contains("questionable") {
            return 85
        } else if lowercased.contains("likely authentic") {
            return 75
        } else if lowercased.contains("questionable") {
            return 50
        } else if lowercased.contains("fake") || lowercased.contains("counterfeit") {
            return 20
        }

        return nil
    }

    private func extractCondition(from text: String) -> ItemCondition? {
        let lowercased = text.lowercased()

        if lowercased.contains("excellent") {
            return .excellent
        } else if lowercased.contains("good") {
            return .good
        } else if lowercased.contains("fair") {
            return .fair
        } else if lowercased.contains("poor") {
            return .poor
        } else if lowercased.contains("damaged") {
            return .damaged
        }

        return nil
    }

    private func extractRiskLevel(from text: String) -> RiskLevel? {
        let lowercased = text.lowercased()

        if lowercased.contains("high risk") || lowercased.contains("critical") {
            return .high
        } else if lowercased.contains("medium risk") || lowercased.contains("moderate") {
            return .medium
        } else if lowercased.contains("low risk") || lowercased.contains("minimal") {
            return .low
        }

        // Default based on authenticity mentions
        if lowercased.contains("fake") || lowercased.contains("counterfeit") {
            return .high
        } else if lowercased.contains("questionable") {
            return .medium
        }

        return .low
    }
}

// MARK: - Price Lookup Service

class PriceLookupService {
    struct EbayPricingData {
        var averagePrice: Double?
        var recentSales: [EbaySale]
        var listingCount: Int
    }

    func fetchEbayPricing(query: String) async throws -> EbayPricingData {
        // For now, we'll simulate eBay data
        // In production, you would:
        // 1. Use eBay Finding API (requires API key)
        // 2. Or web scraping (against ToS, not recommended)
        // 3. Or use a pricing database API

        // Simulated data for demo
        // TODO: Implement real eBay API integration
        return simulateEbayData(for: query)
    }

    private func simulateEbayData(for query: String) -> EbayPricingData {
        // Simulate realistic pricing based on common items
        let randomVariation = Double.random(in: 0.8...1.2)
        let basePrice = estimateBasePrice(from: query) * randomVariation

        let recentSales = (0..<3).map { index in
            EbaySale(
                title: query,
                price: basePrice * Double.random(in: 0.9...1.1),
                saleDate: Calendar.current.date(byAdding: .day, value: -index * 7, to: Date())!,
                condition: ["Excellent", "Good", "Used"].randomElement()
            )
        }

        return EbayPricingData(
            averagePrice: basePrice,
            recentSales: recentSales,
            listingCount: Int.random(in: 10...100)
        )
    }

    private func estimateBasePrice(from query: String) -> Double {
        let q = query.lowercased()

        // Electronics
        if q.contains("iphone") {
            if q.contains("15") || q.contains("14") { return 600 }
            if q.contains("13") || q.contains("12") { return 400 }
            return 250
        }
        if q.contains("ipad") { return 350 }
        if q.contains("macbook") { return 800 }
        if q.contains("xbox") || q.contains("playstation") || q.contains("ps5") { return 350 }

        // Watches
        if q.contains("rolex") { return 8000 }
        if q.contains("omega") { return 3000 }
        if q.contains("apple watch") { return 250 }

        // Jewelry
        if q.contains("gold") && q.contains("ring") { return 500 }
        if q.contains("diamond") { return 1200 }

        // Tools
        if q.contains("drill") || q.contains("saw") { return 100 }

        // Default
        return 150
    }
}

// MARK: - Claude Service Extension

extension ClaudeAPIService {
    /// Analyze text without image (for CSV data enrichment)
    func analyzeText(_ text: String, onUpdate: @escaping (String) -> Void) async throws -> String {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "CLAUDE_API_KEY") as? String, !apiKey.isEmpty else {
            throw ClaudeAPIError.apiKeyMissing
        }

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw ClaudeAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-5-20250929",
            "max_tokens": 1024,
            "stream": true,
            "messages": [
                [
                    "role": "user",
                    "content": text
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        var fullText = ""
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ClaudeAPIError.invalidResponse
        }

        for try await line in asyncBytes.lines {
            if line.isEmpty || !line.hasPrefix("data: ") { continue }
            let jsonString = String(line.dropFirst(6))
            if jsonString == "[DONE]" { break }

            guard let jsonData = jsonString.data(using: .utf8),
                  let event = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let type = event["type"] as? String, type == "content_block_delta",
                  let delta = event["delta"] as? [String: Any],
                  let text = delta["text"] as? String else {
                continue
            }

            fullText += text
            await MainActor.run {
                onUpdate(fullText)
            }
        }

        return fullText
    }
}
