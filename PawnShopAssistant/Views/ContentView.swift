//
//  ContentView.swift
//  PawnShopAssistant
//
//  Main view for the pawn shop assistant
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PawnShopViewModel()
    @State private var showingImagePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .camera
    @State private var showingImageDetail = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerView
                            .padding(.top, 20)

                        // Image Section
                        if let image = viewModel.selectedImage {
                            imagePreviewCard(image: image)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            emptyStateView
                                .transition(.opacity)
                        }

                        // Results Section
                        if viewModel.isAnalyzing {
                            loadingView
                                .transition(.opacity)
                        } else if let analysis = viewModel.analysisResult {
                            analysisResultsCard(analysis: analysis)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Error Section
                        if let error = viewModel.errorMessage {
                            errorView(message: error)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }

                // Floating Action Buttons
                VStack {
                    Spacer()
                    actionButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $viewModel.selectedImage, sourceType: imagePickerSourceType)
            }
            .sheet(isPresented: $showingImageDetail) {
                if let image = viewModel.selectedImage {
                    ImageDetailView(image: image)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedImage)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isAnalyzing)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.analysisResult)
    }

    // MARK: - View Components

    private var headerView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)

                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("Pawn Shop Assistant")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("AI-powered item valuation")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No item selected")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Take a photo or choose from library to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }

    private func imagePreviewCard(image: UIImage) -> some View {
        VStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .onTapGesture {
                    showingImageDetail = true
                }

            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text("Tap image to view full size")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))

            Text("Analyzing item...")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("This may take a few moments")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }

    private func analysisResultsCard(analysis: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)

                Text("Analysis Complete")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()
            }

            Divider()

            Text(analysis)
                .font(.body)
                .lineSpacing(6)
                .foregroundColor(.primary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }

    private func errorView(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if viewModel.selectedImage == nil {
                HStack(spacing: 12) {
                    // Camera Button
                    Button(action: {
                        imagePickerSourceType = .camera
                        showingImagePicker = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.title3)
                            Text("Camera")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }

                    // Photo Library Button
                    Button(action: {
                        imagePickerSourceType = .photoLibrary
                        showingImagePicker = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        HStack {
                            Image(systemName: "photo.fill")
                                .font(.title3)
                            Text("Library")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
            } else {
                // Analyze Button
                if !viewModel.isAnalyzing && viewModel.analysisResult == nil {
                    Button(action: {
                        Task {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            await viewModel.analyzeItem()
                            if viewModel.analysisResult != nil {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "sparkles.rectangle.stack.fill")
                                .font(.title3)
                            Text("Analyze & Get Price")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.green.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                }

                // Start Over Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    viewModel.reset()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.title3)
                        Text("Start Over")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground).opacity(0.95))
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -5)
        )
        .padding(.horizontal, -20)
        .padding(.bottom, -30)
        .padding(.top, 20)
        .padding(.horizontal, 20)
    }
}

// MARK: - Image Detail View

struct ImageDetailView: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale < 1 {
                                    withAnimation {
                                        scale = 1
                                        lastScale = 1
                                    }
                                }
                            }
                    )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
