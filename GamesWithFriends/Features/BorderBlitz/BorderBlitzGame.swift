//
//  BorderBlitzGame.swift
//  GamesWithFriends
//

import SwiftUI

struct BorderBlitzGame: GameDefinition {
    let id = "border-blitz"
    let name = "Border Blitz"
    let description = "Guess countries by their borders!"
    let iconName = "map.fill"
    let accentColor = GameTheme.borderBlitz.accentColor

    func makeRootView() -> AnyView {
        AnyView(BorderBlitzRootView())
    }
}

/// Root view that manages navigation between menu and game
struct BorderBlitzRootView: View {
    @State private var viewModel = BorderBlitzViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if viewModel.gameStarted {
                BorderBlitzGameView(viewModel: viewModel)
            } else {
                BorderBlitzMenuView(viewModel: viewModel)
            }
        }
        .navigationBarBackButtonHidden(viewModel.gameStarted)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .inactive, .background:
                viewModel.pauseGame()
            case .active:
                viewModel.resumeGame()
            default:
                break
            }
        }
    }
}
