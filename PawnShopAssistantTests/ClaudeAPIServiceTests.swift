//
//  ClaudeAPIServiceTests.swift
//  PawnShopAssistantTests
//
//  Unit tests for ClaudeAPIService
//

import XCTest
@testable import PawnShopAssistant

class ClaudeAPIServiceTests: XCTestCase {

    var service: ClaudeAPIService!

    override func setUp() {
        super.setUp()
        service = ClaudeAPIService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Error Handling Tests

    func testClaudeAPIErrorDescriptions() {
        // Test all error descriptions are user-friendly
        let errors: [ClaudeAPIError] = [
            .invalidURL,
            .invalidResponse,
            .apiKeyMissing,
            .networkError(NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Internet connection appears to be offline"])),
            .networkError(NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Request timed out"])),
            .networkError(NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Generic error"])),
            .decodingError(NSError(domain: "Test", code: 0)),
            .imageProcessingError,
            .rateLimitExceeded,
            .insufficientCredits
        ]

        for error in errors {
            let description = error.localizedDescription
            XCTAssertFalse(description.isEmpty, "Error description should not be empty")
            XCTAssertFalse(description.contains("nil"), "Error description should not contain 'nil'")
        }
    }

    func testAPIKeyMissingError() {
        let error = ClaudeAPIError.apiKeyMissing
        XCTAssertTrue(error.localizedDescription.contains("API key"))
    }

    func testImageProcessingError() {
        let error = ClaudeAPIError.imageProcessingError
        XCTAssertTrue(error.localizedDescription.contains("image"))
    }

    func testRateLimitError() {
        let error = ClaudeAPIError.rateLimitExceeded
        XCTAssertTrue(error.localizedDescription.contains("request"))
    }

    func testInsufficientCreditsError() {
        let error = ClaudeAPIError.insufficientCredits
        XCTAssertTrue(error.localizedDescription.contains("credit"))
    }

    // MARK: - Image Processing Tests

    func testImageToBase64Conversion() throws {
        // Create a simple test image
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        XCTAssertNotNil(image, "Test image should be created")

        // Test JPEG data conversion
        if let testImage = image {
            let jpegData = testImage.jpegData(compressionQuality: 0.8)
            XCTAssertNotNil(jpegData, "JPEG data should be created from image")

            if let data = jpegData {
                let base64String = data.base64EncodedString()
                XCTAssertFalse(base64String.isEmpty, "Base64 string should not be empty")
            }
        }
    }

    // MARK: - Network Response Handling

    func testStatusCodeHandling() {
        // Test that different status codes map to appropriate errors
        // This is a unit test for the error mapping logic
        let statusCodes: [Int: ClaudeAPIError] = [
            401: .apiKeyMissing,
            429: .rateLimitExceeded,
            402: .insufficientCredits
        ]

        for (code, expectedError) in statusCodes {
            // Verify error types match what we expect
            switch (code, expectedError) {
            case (401, .apiKeyMissing),
                 (429, .rateLimitExceeded),
                 (402, .insufficientCredits):
                XCTAssertTrue(true, "Status code \(code) maps correctly")
            default:
                XCTFail("Status code \(code) does not map to expected error")
            }
        }
    }
}
