//
//  PawnShopViewModel.swift
//  PawnShopAssistant
//
//  ViewModel for managing pawn shop item analysis
//

import SwiftUI
import Combine

@MainActor
class PawnShopViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var analysisResult: String?
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    
    private let claudeService = ClaudeAPIService()
    
    func analyzeItem() async {
        guard let image = selectedImage else {
            errorMessage = "No image selected"
            return
        }

        isAnalyzing = true
        errorMessage = nil
        analysisResult = "" // Clear previous result

        do {
            // Use streaming analysis for real-time updates
            let result = try await claudeService.analyzeImageStreaming(image) { [weak self] partialText in
                self?.analysisResult = partialText
            }
            analysisResult = result
            errorMessage = nil
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
            analysisResult = nil
        }

        isAnalyzing = false
    }
    
    func reset() {
        selectedImage = nil
        analysisResult = nil
        errorMessage = nil
        isAnalyzing = false
    }
}
