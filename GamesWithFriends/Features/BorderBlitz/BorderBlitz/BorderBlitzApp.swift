//
//  BorderBlitzApp.swift
//  Border Blitz
//
//  A country identification game where players guess countries based on their geographic borders
//

import SwiftUI

@main
struct BorderBlitzApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var gameViewModel = GameViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if gameViewModel.gameStarted {
                    GameView(viewModel: gameViewModel)
                } else {
                    MenuView(viewModel: gameViewModel)
                }
            }
            .navigationTitle("Border Blitz")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
