//
//  ContentView.swift
//  PawnShopAssistant
//
//  Main view for the pawn shop assistant
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PawnShopViewModel()
    @State private var showingCamera = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title Section
                VStack(spacing: 8) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Pawn Shop Assistant")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("AI-powered item valuation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Image Preview
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                }
                
                // Analysis Results
                if viewModel.isAnalyzing {
                    ProgressView("Analyzing item...")
                        .padding()
                } else if let analysis = viewModel.analysisResult {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Analysis Results")
                                .font(.headline)
                            
                            Text(analysis)
                                .font(.body)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: 300)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showingCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Take Photo")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    if viewModel.selectedImage != nil && !viewModel.isAnalyzing {
                        Button(action: {
                            Task {
                                await viewModel.analyzeItem()
                            }
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Analyze & Get Price")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                    if viewModel.selectedImage != nil {
                        Button(action: {
                            viewModel.reset()
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Start Over")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $viewModel.selectedImage)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
