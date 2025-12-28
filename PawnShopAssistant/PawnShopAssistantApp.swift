//
//  PawnShopAssistantApp.swift
//  PawnShopAssistant
//
//  Professional pawn shop management system with AI
//

import SwiftUI

@main
struct PawnShopAssistantApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            // Camera Analysis Tab
            ContentView()
                .tabItem {
                    Label("Analyze", systemImage: "camera.fill")
                }

            // Inventory Tab
            InventoryListView()
                .tabItem {
                    Label("Inventory", systemImage: "list.bullet.rectangle.fill")
                }
        }
    }
}
