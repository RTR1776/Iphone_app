//
//  ItemAnalysisTests.swift
//  PawnShopAssistantTests
//
//  Unit tests for ItemAnalysis and PriceRange models
//

import XCTest
@testable import PawnShopAssistant

class ItemAnalysisTests: XCTestCase {

    // MARK: - PriceRange Tests

    func testPriceRangeFormatting_SameMinMax() {
        // Test when min and max are the same
        let priceRange = PriceRange(min: 100.0, max: 100.0, currency: "USD")
        let formatted = priceRange.formatted

        XCTAssertTrue(formatted.contains("100"))
        XCTAssertFalse(formatted.contains("-"))
    }

    func testPriceRangeFormatting_DifferentMinMax() {
        // Test when min and max are different
        let priceRange = PriceRange(min: 50.0, max: 100.0, currency: "USD")
        let formatted = priceRange.formatted

        XCTAssertTrue(formatted.contains("50"))
        XCTAssertTrue(formatted.contains("100"))
        XCTAssertTrue(formatted.contains("-"))
    }

    func testPriceRangeFormatting_DifferentCurrency() {
        // Test with EUR currency
        let priceRange = PriceRange(min: 100.0, max: 200.0, currency: "EUR")
        let formatted = priceRange.formatted

        // The formatted string should contain the values
        XCTAssertTrue(formatted.contains("100"))
        XCTAssertTrue(formatted.contains("200"))
    }

    func testPriceRangeCodable() throws {
        // Test encoding and decoding
        let priceRange = PriceRange(min: 75.5, max: 150.25, currency: "USD")

        let encoder = JSONEncoder()
        let data = try encoder.encode(priceRange)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PriceRange.self, from: data)

        XCTAssertEqual(decoded.min, 75.5)
        XCTAssertEqual(decoded.max, 150.25)
        XCTAssertEqual(decoded.currency, "USD")
    }

    // MARK: - ItemAnalysis Tests

    func testItemAnalysisCodable() throws {
        // Create a sample ItemAnalysis
        let marketValue = PriceRange(min: 100.0, max: 200.0, currency: "USD")
        let pawnValue = PriceRange(min: 25.0, max: 50.0, currency: "USD")

        let item = ItemAnalysis(
            itemName: "Test Watch",
            description: "A vintage timepiece",
            condition: "Good",
            marketValue: marketValue,
            pawnValue: pawnValue,
            keyFactors: ["Brand", "Condition", "Rarity"],
            verificationTips: ["Check serial number", "Verify authenticity"]
        )

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(item)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ItemAnalysis.self, from: data)

        // Verify
        XCTAssertEqual(decoded.itemName, "Test Watch")
        XCTAssertEqual(decoded.description, "A vintage timepiece")
        XCTAssertEqual(decoded.condition, "Good")
        XCTAssertEqual(decoded.marketValue.min, 100.0)
        XCTAssertEqual(decoded.pawnValue.max, 50.0)
        XCTAssertEqual(decoded.keyFactors.count, 3)
        XCTAssertEqual(decoded.verificationTips.count, 2)
    }

    func testItemAnalysisWithEmptyArrays() throws {
        // Test with empty arrays
        let marketValue = PriceRange(min: 0, max: 0, currency: "USD")
        let pawnValue = PriceRange(min: 0, max: 0, currency: "USD")

        let item = ItemAnalysis(
            itemName: "Unknown Item",
            description: "No description",
            condition: "Unknown",
            marketValue: marketValue,
            pawnValue: pawnValue,
            keyFactors: [],
            verificationTips: []
        )

        XCTAssertEqual(item.keyFactors.count, 0)
        XCTAssertEqual(item.verificationTips.count, 0)
    }
}
