//
//  CSVImportView.swift
//  PawnShopAssistant
//
//  Magic CSV import with AI enrichment
//

import SwiftUI
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var inventoryManager = InventoryManager.shared
    @StateObject private var enrichmentService = AIEnrichmentService()

    @State private var isImporting = false
    @State private var showFilePicker = false
    @State private var importedItems: [PawnItem] = []
    @State private var enrichedCount = 0
    @State private var showingResults = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if !isImporting && importedItems.isEmpty {
                            // Upload State
                            uploadSection
                        } else if isImporting {
                            // Processing State
                            processingSection
                        } else if !importedItems.isEmpty {
                            // Results State
                            resultsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Import from Bravo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if !importedItems.isEmpty && !isImporting {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            // Save to inventory
                            for item in importedItems {
                                inventoryManager.addItem(item)
                            }
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showFilePicker) {
                DocumentPicker { url in
                    handleFileSelection(url)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Upload Section

    private var uploadSection: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)

                Image(systemName: "doc.text.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .padding(.top, 40)

            VStack(spacing: 12) {
                Text("Import Bravo CSV")
                    .font(.title.bold())

                Text("Upload your inventory file and watch the magic happen")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Features
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "sparkles", title: "AI Analysis", description: "Every item analyzed by Claude")
                FeatureRow(icon: "dollarsign.circle", title: "Live Pricing", description: "Current eBay market values")
                FeatureRow(icon: "shield.checkmark", title: "Auth Check", description: "Authenticity verification")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Profit Calc", description: "Estimated margins")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 10)
            )

            // Upload Button
            Button(action: {
                showFilePicker = true
            }) {
                HStack {
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.title3)
                    Text("Choose CSV File")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
            }

            // Sample Format
            VStack(alignment: .leading, spacing: 8) {
                Text("Expected Format:")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                Text("Ticket,Date,Customer,Item,Amount,Interest,Due,Status")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }

            Spacer()
        }
    }

    // MARK: - Processing Section

    private var processingSection: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated Icon
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 8
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "brain")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }

            VStack(spacing: 12) {
                Text("AI Magic in Progress")
                    .font(.title2.bold())

                Text(enrichmentService.currentItemName.isEmpty ? "Processing items..." : enrichmentService.currentItemName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Progress
            VStack(spacing: 12) {
                ProgressView(value: Double(enrichmentService.currentProgress.current),
                           total: Double(enrichmentService.currentProgress.total))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)

                Text("\(enrichmentService.currentProgress.current) of \(enrichmentService.currentProgress.total) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            // Live Analysis Preview
            if !enrichmentService.currentAnalysis.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Live Analysis")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    ScrollView {
                        Text(enrichmentService.currentAnalysis)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 150)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .transition(.opacity)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(spacing: 24) {
            // Success Icon
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("Import Complete!")
                    .font(.title.bold())

                Text("\(importedItems.count) items analyzed and enriched")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Stats Cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(icon: "checkmark.shield.fill", value: "\(enrichedCount)", label: "Enriched", color: .green)
                StatCard(icon: "dollarsign.circle.fill", value: "$\(totalValue, specifier: "%.0f")", label: "Total Value", color: .blue)
                StatCard(icon: "chart.line.uptrend.xyaxis", value: "\(avgProfit, specifier: "%.0f")%", label: "Avg Margin", color: .purple)
                StatCard(icon: "exclamationmark.triangle.fill", value: "\(flaggedCount)", label: "Flagged", color: .orange)
            }

            // Items List Preview
            VStack(alignment: .leading, spacing: 12) {
                Text("Imported Items")
                    .font(.headline)

                ForEach(importedItems.prefix(5)) { item in
                    ImportedItemRow(item: item)
                }

                if importedItems.count > 5 {
                    Text("+ \(importedItems.count - 5) more items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 10)
            )
        }
    }

    // MARK: - Computed Properties

    private var totalValue: Double {
        importedItems.reduce(0) { $0 + ($1.marketValue ?? $1.purchasePrice) }
    }

    private var avgProfit: Double {
        let margins = importedItems.compactMap { $0.profitMargin }
        guard !margins.isEmpty else { return 0 }
        return margins.reduce(0, +) / Double(margins.count)
    }

    private var flaggedCount: Int {
        importedItems.filter { $0.isFlagged || ($0.authenticityScore ?? 100) < 70 }.count
    }

    // MARK: - File Handling

    private func handleFileSelection(_ url: URL) {
        Task {
            do {
                isImporting = true

                // Read CSV
                let csvString = try String(contentsOf: url, encoding: .utf8)

                // Import and parse
                let items = try await inventoryManager.importFromCSV(csvString) { current, total in
                    // Progress callback
                }

                // Enrich with AI
                let enriched = try await enrichmentService.enrichItems(items) { item, index in
                    importedItems = items
                    enrichedCount = index + 1
                }

                importedItems = enriched
                enrichedCount = enriched.count
                isImporting = false

            } catch {
                errorMessage = error.localizedDescription
                isImporting = false
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3.bold())

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5)
        )
    }
}

struct ImportedItemRow: View {
    let item: PawnItem

    var body: some View {
        HStack {
            Text(item.category.icon)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.itemName)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let marketValue = item.marketValue {
                        Text("$\(marketValue, specifier: "%.0f")")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    if let authStatus = item.authenticityStatus {
                        Text(authStatus.rawValue)
                            .font(.caption)
                            .foregroundColor(authStatus.color)
                    }
                }
            }

            Spacer()

            if item.isFlagged || (item.authenticityScore ?? 100) < 70 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.commaSeparatedText, .text])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onDocumentPicked(url)
        }
    }
}
