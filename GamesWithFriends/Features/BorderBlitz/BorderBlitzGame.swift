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
        ZStack {
            // Plain retro ground at the root — the playing screen is a live
            // speech visualiser, so no motif field there (playbook §3); the
            // menu and the two end states layer their own motifs on top.
            AppTheme.Retro.ground
                .ignoresSafeArea()

            if viewModel.gameStarted {
                BorderBlitzGameView(viewModel: viewModel)
            } else {
                BorderBlitzMenuView(viewModel: viewModel)
            }
        }
        // §6: functional nav glyphs (the hub's back chevron) render ink.
        .tint(AppTheme.Retro.ink)
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
