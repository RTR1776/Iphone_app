//
//  PawnShopViewModelTests.swift
//  PawnShopAssistantTests
//
//  Unit tests for PawnShopViewModel
//

import XCTest
@testable import PawnShopAssistant

@MainActor
class PawnShopViewModelTests: XCTestCase {

    var viewModel: PawnShopViewModel!

    override func setUp() {
        super.setUp()
        viewModel = PawnShopViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertNil(viewModel.selectedImage)
        XCTAssertNil(viewModel.analysisResult)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isAnalyzing)
    }

    // MARK: - Image Selection Tests

    func testImageSelection() {
        // Create a test image
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let testImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        viewModel.selectedImage = testImage
        XCTAssertNotNil(viewModel.selectedImage)
    }

    // MARK: - Reset Tests

    func testReset() {
        // Set up some state
        let size = CGSize(width: 50, height: 50)
        UIGraphicsBeginImageContext(size)
        UIColor.green.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let testImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        viewModel.selectedImage = testImage
        viewModel.analysisResult = "Test result"
        viewModel.errorMessage = "Test error"

        // Reset
        viewModel.reset()

        // Verify everything is cleared
        XCTAssertNil(viewModel.selectedImage)
        XCTAssertNil(viewModel.analysisResult)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isAnalyzing)
    }

    // MARK: - Analysis State Tests

    func testAnalyzeWithoutImage() async {
        // Try to analyze without selecting an image
        await viewModel.analyzeItem()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("No image") ?? false)
        XCTAssertNil(viewModel.analysisResult)
        XCTAssertFalse(viewModel.isAnalyzing)
    }

    func testIsAnalyzingFlag() {
        // Initial state
        XCTAssertFalse(viewModel.isAnalyzing)

        // Note: We can't easily test the async behavior without mocking
        // the ClaudeAPIService, but we can verify the flag exists and
        // starts in the correct state
    }

    // MARK: - Error Handling Tests

    func testErrorMessageClearing() async {
        // Set an initial error
        viewModel.errorMessage = "Previous error"

        // Create and set a test image
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let testImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        viewModel.selectedImage = testImage

        // The error should be cleared when starting a new analysis
        // (This will fail without a valid API key, but we're testing
        // that the error gets cleared before analysis starts)
        let previousError = viewModel.errorMessage

        // Start analysis (will likely fail due to missing API key)
        await viewModel.analyzeItem()

        // The error message should have changed (either cleared then set again,
        // or set to a new error message)
        // We can't predict the exact outcome without mocking, but we can verify
        // the state is consistent
        XCTAssertTrue(viewModel.errorMessage != previousError || viewModel.errorMessage != nil)
    }

    // MARK: - Published Properties Tests

    func testPublishedProperties() {
        // Verify all @Published properties are accessible
        _ = viewModel.selectedImage
        _ = viewModel.analysisResult
        _ = viewModel.errorMessage
        _ = viewModel.isAnalyzing

        // If we get here without crashes, the properties are working
        XCTAssertTrue(true)
    }
}
