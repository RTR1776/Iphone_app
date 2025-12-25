//
//  ItemAnalysis.swift
//  PawnShopAssistant
//
//  Model for item analysis data
//

import Foundation

struct ItemAnalysis: Codable {
    let itemName: String
    let description: String
    let condition: String
    let marketValue: PriceRange
    let pawnValue: PriceRange
    let keyFactors: [String]
    let verificationTips: [String]
}

struct PriceRange: Codable {
    let min: Double
    let max: Double
    let currency: String
    
    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        
        if min == max {
            return formatter.string(from: NSNumber(value: min)) ?? "$\(min)"
        } else {
            let minStr = formatter.string(from: NSNumber(value: min)) ?? "$\(min)"
            let maxStr = formatter.string(from: NSNumber(value: max)) ?? "$\(max)"
            return "\(minStr) - \(maxStr)"
        }
    }
}
