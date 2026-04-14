//
//  FinishTheLineGame.swift
//  GamesWithFriends
//

import SwiftUI

struct FinishTheLineGame: GameDefinition {
    let id = "finish-the-line"
    let name = "Finish the Line"
    let description = "Race the clock to shout the missing word from iconic quotes."
    let iconName = "quote.bubble.fill"
    let accentColor = GameTheme.finishTheLine.accentColor

    func makeRootView() -> AnyView {
        AnyView(FinishTheLineRootView())
    }
}

/// Root container that manages phase-based navigation for Finish the Line.
struct FinishTheLineRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewModel: FinishTheLineViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(for: viewModel)
            } else {
                // Transient: modelContext not yet injected; avoid ProgressView.
                Color.clear
                    .onAppear {
                        self.viewModel = FinishTheLineViewModel(modelContext: modelContext)
                    }
            }
        }
    }

    @ViewBuilder
    private func content(for viewModel: FinishTheLineViewModel) -> some View {
        ZStack {
            switch viewModel.phase {
            case .menu:
                FinishTheLineMenuView(viewModel: viewModel)
            case .countdown:
                FinishTheLineCountdownView(viewModel: viewModel)
            case .playing:
                FinishTheLineGameView(viewModel: viewModel)
            case .results:
                FinishTheLineResultsView(viewModel: viewModel)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: viewModel.phase)
        .navigationBarBackButtonHidden(viewModel.phase != .menu)
        .onChange(of: scenePhase) { _, newPhase in
            viewModel.handleScenePhaseChange(newPhase)
        }
    }
}
