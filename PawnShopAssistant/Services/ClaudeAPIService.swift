//
//  ClaudeAPIService.swift
//  PawnShopAssistant
//
//  Service for interacting with Claude API
//

import Foundation
import UIKit

enum ClaudeAPIError: Error {
    case invalidURL
    case invalidResponse
    case apiKeyMissing
    case networkError(Error)
    case decodingError(Error)
    case imageProcessingError
    case rateLimitExceeded
    case insufficientCredits

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Unable to connect to the AI service. Please try again."
        case .invalidResponse:
            return "Received an unexpected response. Please try again."
        case .apiKeyMissing:
            return "API key not configured. Please check your settings and add a valid Claude API key."
        case .networkError(let error):
            let message = error.localizedDescription
            if message.contains("Internet connection") {
                return "No internet connection. Please check your network and try again."
            } else if message.contains("timed out") {
                return "Request timed out. Please check your connection and try again."
            } else {
                return "Network error occurred. Please try again."
            }
        case .decodingError:
            return "Unable to process the analysis. Please try again with a different image."
        case .imageProcessingError:
            return "Unable to process the image. Please try taking a new photo."
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment and try again."
        case .insufficientCredits:
            return "API credits depleted. Please check your account at Anthropic."
        }
    }
}

class ClaudeAPIService {
    private let apiURL = "https://api.anthropic.com/v1/messages"
    private let apiVersion = "2023-06-01"
    
    // API key should be stored in Config.xcconfig or environment
    private var apiKey: String? {
        // Try to get from bundle configuration
        if let key = Bundle.main.object(forInfoDictionaryKey: "CLAUDE_API_KEY") as? String, !key.isEmpty {
            return key
        }
        return nil
    }
    
    func analyzeImage(_ image: UIImage) async throws -> String {
        guard let apiKey = apiKey else {
            throw ClaudeAPIError.apiKeyMissing
        }

        guard let url = URL(string: apiURL) else {
            throw ClaudeAPIError.invalidURL
        }

        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ClaudeAPIError.imageProcessingError
        }
        let base64Image = imageData.base64EncodedString()
        
        // Prepare request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        
        // Create request body
        let requestBody: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": """
                            You are an expert pawn shop assistant. Analyze this item and provide:
                            
                            1. Item identification and description
                            2. Condition assessment
                            3. Estimated market value range
                            4. Estimated pawn value (typically 25-60% of market value)
                            5. Key factors affecting the price
                            6. Tips for verification or authentication
                            
                            Be specific and practical in your assessment.
                            """
                        ]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClaudeAPIError.invalidResponse
            }
            
            // Handle different status codes
            guard httpResponse.statusCode == 200 else {
                // Handle specific HTTP status codes
                switch httpResponse.statusCode {
                case 401:
                    throw ClaudeAPIError.apiKeyMissing
                case 429:
                    throw ClaudeAPIError.rateLimitExceeded
                case 402:
                    throw ClaudeAPIError.insufficientCredits
                default:
                    if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorJSON["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        throw ClaudeAPIError.networkError(NSError(domain: "ClaudeAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message]))
                    }
                    throw ClaudeAPIError.invalidResponse
                }
            }
            
            // Parse response
            let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let content = responseJSON?["content"] as? [[String: Any]],
                  let firstContent = content.first,
                  let text = firstContent["text"] as? String else {
                throw ClaudeAPIError.decodingError(NSError(domain: "ClaudeAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not extract text from response"]))
            }
            
            return text
            
        } catch let error as ClaudeAPIError {
            throw error
        } catch {
            throw ClaudeAPIError.networkError(error)
        }
    }
}
