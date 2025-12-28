//
//  InventoryManager.swift
//  PawnShopAssistant
//
//  Manages inventory database and operations
//

import Foundation
import SwiftUI

@MainActor
class InventoryManager: ObservableObject {
    static let shared = InventoryManager()

    @Published var items: [PawnItem] = []
    @Published var isLoading = false
    @Published var error: String?

    // Statistics
    @Published var totalInventoryValue: Double = 0
    @Published var totalItems: Int = 0
    @Published var totalProfit: Double = 0

    private let fileName = "inventory.json"

    private init() {
        loadItems()
        updateStatistics()
    }

    // MARK: - CRUD Operations

    func addItem(_ item: PawnItem) {
        items.append(item)
        saveItems()
        updateStatistics()
    }

    func updateItem(_ item: PawnItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            var updatedItem = item
            updatedItem.modifiedDate = Date()
            items[index] = updatedItem
            saveItems()
            updateStatistics()
        }
    }

    func deleteItem(_ item: PawnItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
        updateStatistics()
    }

    func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveItems()
        updateStatistics()
    }

    // MARK: - Search & Filter

    func searchItems(query: String) -> [PawnItem] {
        guard !query.isEmpty else { return items }

        return items.filter { item in
            item.itemName.localizedCaseInsensitiveContains(query) ||
            item.description.localizedCaseInsensitiveContains(query) ||
            item.brand?.localizedCaseInsensitiveContains(query) == true ||
            item.model?.localizedCaseInsensitiveContains(query) == true ||
            item.itemID?.localizedCaseInsensitiveContains(query) == true
        }
    }

    func filterByCategory(_ category: ItemCategory) -> [PawnItem] {
        items.filter { $0.category == category }
    }

    func filterByStatus(_ status: ItemStatus) -> [PawnItem] {
        items.filter { $0.status == status }
    }

    func filterByTransactionType(_ type: TransactionType) -> [PawnItem] {
        items.filter { $0.transactionType == type }
    }

    func flaggedItems() -> [PawnItem] {
        items.filter { $0.isFlagged }
    }

    // MARK: - Statistics

    func updateStatistics() {
        totalItems = items.count
        totalInventoryValue = items
            .filter { $0.status == .inStock }
            .reduce(0) { $0 + $1.purchasePrice }

        totalProfit = items
            .filter { $0.status == .sold }
            .compactMap { $0.profit }
            .reduce(0, +)
    }

    func statisticsByCategory() -> [ItemCategory: (count: Int, value: Double)] {
        var stats: [ItemCategory: (count: Int, value: Double)] = [:]

        for category in ItemCategory.allCases {
            let categoryItems = filterByCategory(category)
                .filter { $0.status == .inStock }

            stats[category] = (
                count: categoryItems.count,
                value: categoryItems.reduce(0) { $0 + $1.purchasePrice }
            )
        }

        return stats
    }

    func averageProfitMargin() -> Double {
        let soldItems = items.filter { $0.status == .sold && $0.profitMargin != nil }
        guard !soldItems.isEmpty else { return 0 }

        let totalMargin = soldItems.compactMap { $0.profitMargin }.reduce(0, +)
        return totalMargin / Double(soldItems.count)
    }

    // MARK: - Persistence

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func getFileURL() -> URL {
        getDocumentsDirectory().appendingPathComponent(fileName)
    }

    func saveItems() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(items)
            try data.write(to: getFileURL())
        } catch {
            print("Error saving items: \(error)")
            self.error = "Failed to save inventory: \(error.localizedDescription)"
        }
    }

    func loadItems() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let data = try Data(contentsOf: getFileURL())
            items = try decoder.decode([PawnItem].self, from: data)
        } catch {
            // File doesn't exist yet or is corrupted
            print("No existing inventory found or error loading: \(error)")
            items = []
        }
    }

    // MARK: - CSV Export

    func exportToCSV() -> String {
        var csv = "Item ID,Date,Item Name,Category,Brand,Model,Description,Transaction Type,Purchase Price,Market Value,Suggested Loan,eBay Avg Price,Authenticity,Condition,Status,Profit,Profit Margin,AI Analysis\n"

        for item in items {
            let row = [
                item.itemID ?? "",
                formatDate(item.transactionDate),
                escapeCSV(item.itemName),
                item.category.rawValue,
                item.brand ?? "",
                item.model ?? "",
                escapeCSV(item.description),
                item.transactionType.rawValue,
                String(format: "%.2f", item.purchasePrice),
                item.marketValue.map { String(format: "%.2f", $0) } ?? "",
                item.suggestedLoanAmount.map { String(format: "%.2f", $0) } ?? "",
                item.ebayAveragePrice.map { String(format: "%.2f", $0) } ?? "",
                item.authenticityStatus?.rawValue ?? "",
                item.condition?.rawValue ?? "",
                item.status.rawValue,
                item.profit.map { String(format: "%.2f", $0) } ?? "",
                item.profitMargin.map { String(format: "%.1f%%", $0) } ?? "",
                escapeCSV(item.aiAnalysis ?? "")
            ].joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    private func escapeCSV(_ text: String) -> String {
        let escapedText = text.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escapedText)\""
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: date)
    }

    // MARK: - CSV Import (Bravo Format)

    func importFromCSV(_ csvString: String, onProgress: @escaping (Int, Int) -> Void) async throws -> [PawnItem] {
        let rows = parseCSV(csvString)
        var importedItems: [PawnItem] = []

        for (index, row) in rows.enumerated() {
            await MainActor.run {
                onProgress(index + 1, rows.count)
            }

            if let bravoRow = parseBravoRow(row) {
                let item = bravoRow.toPawnItem()
                importedItems.append(item)
            }

            // Small delay to prevent overwhelming the system
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }

        // Add to inventory
        await MainActor.run {
            items.append(contentsOf: importedItems)
            saveItems()
            updateStatistics()
        }

        return importedItems
    }

    private func parseCSV(_ csvString: String) -> [[String]] {
        var rows: [[String]] = []
        let lines = csvString.components(separatedBy: .newlines).filter { !$0.isEmpty }

        for line in lines {
            var fields: [String] = []
            var currentField = ""
            var inQuotes = false

            for char in line {
                if char == "\"" {
                    inQuotes.toggle()
                } else if char == "," && !inQuotes {
                    fields.append(currentField.trimmingCharacters(in: .whitespaces))
                    currentField = ""
                } else {
                    currentField.append(char)
                }
            }

            fields.append(currentField.trimmingCharacters(in: .whitespaces))
            rows.append(fields)
        }

        return rows
    }

    private func parseBravoRow(_ fields: [String]) -> BravoCSVRow? {
        // Skip header row
        if fields.first?.lowercased().contains("ticket") == true {
            return nil
        }

        guard fields.count >= 4 else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"

        return BravoCSVRow(
            ticketNumber: fields[0],
            date: fields.count > 1 ? dateFormatter.date(from: fields[1]) : nil,
            customerName: fields.count > 2 ? fields[2] : nil,
            itemDescription: fields.count > 3 ? fields[3] : "Unknown Item",
            loanAmount: fields.count > 4 ? Double(fields[4].replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) : nil,
            interestRate: fields.count > 5 ? Double(fields[5].replacingOccurrences(of: "%", with: "")) : nil,
            dueDate: fields.count > 6 ? dateFormatter.date(from: fields[6]) : nil,
            status: fields.count > 7 ? fields[7] : nil
        )
    }

    // MARK: - Bulk Operations

    func deleteAll() {
        items = []
        saveItems()
        updateStatistics()
    }

    func clearSoldItems() {
        items.removeAll { $0.status == .sold }
        saveItems()
        updateStatistics()
    }
}
