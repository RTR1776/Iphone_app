//
//  InventoryListView.swift
//  PawnShopAssistant
//
//  Professional inventory management interface
//

import SwiftUI

struct InventoryListView: View {
    @StateObject private var inventoryManager = InventoryManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: ItemCategory?
    @State private var selectedStatus: ItemStatus?
    @State private var showingCSVImport = false
    @State private var showingExport = false
    @State private var shareItem: ActivityItem?

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Stats Dashboard
                    statsHeader

                    // Filters
                    filterBar

                    // Items List
                    if filteredItems.isEmpty {
                        emptyState
                    } else {
                        itemsList
                    }
                }
            }
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingCSVImport = true }) {
                            Label("Import CSV", systemImage: "square.and.arrow.down")
                        }

                        Button(action: { exportToCSV() }) {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        Button(role: .destructive, action: {}) {
                            Label("Clear Sold Items", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search items")
            .sheet(isPresented: $showingCSVImport) {
                CSVImportView()
            }
            .sheet(item: $shareItem) { item in
                ActivityViewController(activityItems: item.items)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                QuickStatCard(
                    icon: "cube.box.fill",
                    value: "\(inventoryManager.totalItems)",
                    label: "Total Items",
                    color: .blue
                )

                QuickStatCard(
                    icon: "dollarsign.circle.fill",
                    value: "$\(inventoryManager.totalInventoryValue, specifier: "%.0f")",
                    label: "Inventory Value",
                    color: .green
                )

                QuickStatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    value: "\(inventoryManager.averageProfitMargin(), specifier: "%.0f")%",
                    label: "Avg Margin",
                    color: .purple
                )

                QuickStatCard(
                    icon: "checkmark.shield.fill",
                    value: "\(inventoryManager.items.filter { $0.status == .inStock }.count)",
                    label: "In Stock",
                    color: .orange
                )
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Category Filter
                Menu {
                    Button("All Categories") {
                        selectedCategory = nil
                    }

                    Divider()

                    ForEach(ItemCategory.allCases, id: \.self) { category in
                        Button("\(category.icon) \(category.rawValue)") {
                            selectedCategory = category
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCategory?.rawValue ?? "All")
                        Image(systemName: "chevron.down")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedCategory != nil ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(selectedCategory != nil ? .white : .primary)
                    .cornerRadius(20)
                }

                // Status Filter
                Menu {
                    Button("All Status") {
                        selectedStatus = nil
                    }

                    Divider()

                    ForEach([ItemStatus.inStock, .sold, .redeemed, .forfeited, .onHold], id: \.self) { status in
                        Button(status.rawValue) {
                            selectedStatus = status
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedStatus?.rawValue ?? "All")
                        Image(systemName: "chevron.down")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedStatus != nil ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(selectedStatus != nil ? .white : .primary)
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Items List

    private var itemsList: some View {
        List {
            ForEach(filteredItems) { item in
                NavigationLink(destination: ItemDetailView(item: item)) {
                    InventoryItemRow(item: item)
                }
            }
            .onDelete { indexSet in
                inventoryManager.deleteItems(at: indexSet)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No items in inventory")
                .font(.headline)
                .foregroundColor(.secondary)

            Button(action: { showingCSVImport = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import CSV")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Filtered Items

    private var filteredItems: [PawnItem] {
        var items = inventoryManager.items

        // Search
        if !searchText.isEmpty {
            items = inventoryManager.searchItems(query: searchText)
        }

        // Category filter
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }

        // Status filter
        if let status = selectedStatus {
            items = items.filter { $0.status == status }
        }

        return items.sorted { $0.createdDate > $1.createdDate }
    }

    // MARK: - CSV Export

    private func exportToCSV() {
        let csvString = inventoryManager.exportToCSV()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("inventory_export.csv")

        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            shareItem = ActivityItem(items: [tempURL])
        } catch {
            print("Error exporting CSV: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title3.bold())

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct InventoryItemRow: View {
    let item: PawnItem

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Text(item.category.icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.itemName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(item.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let condition = item.condition {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(condition.rawValue)
                            .font(.caption)
                            .foregroundColor(condition.color)
                    }

                    if let authStatus = item.authenticityStatus {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(authStatus.rawValue)
                            .font(.caption)
                            .foregroundColor(authStatus.color)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let marketValue = item.marketValue {
                    Text("$\(marketValue, specifier: "%.0f")")
                        .font(.headline)
                        .foregroundColor(.green)
                } else {
                    Text("$\(item.purchasePrice, specifier: "%.0f")")
                        .font(.headline)
                }

                if let margin = item.profitMargin {
                    Text("\(margin, specifier: "%.0f")% margin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ItemDetailView: View {
    let item: PawnItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Photos (if available)
                if let photoData = item.primaryPhoto, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                }

                // Basic Info
                VStack(alignment: .leading, spacing: 12) {
                    Text(item.itemName)
                        .font(.title.bold())

                    if let brand = item.brand {
                        Text(brand)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }

                // Financial Info
                GroupBox("Financial") {
                    VStack(spacing: 12) {
                        InfoRow(label: "Purchase Price", value: "$\(item.purchasePrice, specifier: "%.2f")")
                        if let marketValue = item.marketValue {
                            InfoRow(label: "Market Value", value: "$\(marketValue, specifier: "%.2f")")
                        }
                        if let suggestedLoan = item.suggestedLoanAmount {
                            InfoRow(label: "Suggested Loan", value: "$\(suggestedLoan, specifier: "%.2f")")
                        }
                        if let profit = item.profit {
                            InfoRow(label: "Profit", value: "$\(profit, specifier: "%.2f")", valueColor: .green)
                        }
                    }
                }

                // AI Analysis
                if let analysis = item.aiAnalysis {
                    GroupBox("AI Analysis") {
                        Text(analysis)
                            .font(.body)
                    }
                }

                // eBay Data
                if let ebayAvg = item.ebayAveragePrice {
                    GroupBox("Market Data") {
                        VStack(spacing: 12) {
                            InfoRow(label: "eBay Average", value: "$\(ebayAvg, specifier: "%.2f")")
                            if let count = item.ebayListingCount {
                                InfoRow(label: "Active Listings", value: "\(count)")
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Activity View Controller

struct ActivityItem: Identifiable {
    let id = UUID()
    let items: [Any]
}

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
