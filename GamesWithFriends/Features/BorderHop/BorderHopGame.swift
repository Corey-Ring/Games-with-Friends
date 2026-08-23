import SwiftUI

struct BorderHopGame: GameDefinition {
    let id = "border-hop"
    let name = "Border Hop"
    let description = "Navigate the world one border at a time"
    let iconName = "globe.europe.africa.fill"
    let accentColor = GameTheme.borderHop.accentColor

    func makeRootView() -> AnyView {
        AnyView(BorderHopRootView())
    }
}

struct BorderHopRootView: View {
    @State private var viewModel = BorderHopViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            // Plain retro ground at the root — the playing phase is a live map
            // and the quiz sheet sits on top of it, so no motif field there
            // (playbook §3); the setup, briefing and results screens layer
            // their own motifs on top.
            AppTheme.Retro.ground
                .ignoresSafeArea()

            Group {
                switch viewModel.phase {
                case .menu:
                    BorderHopDifficultyView(viewModel: viewModel)
                        .transition(.move(edge: .leading))
                case .loading:
                    BorderHopLoadingView(viewModel: viewModel)
                        .transition(.move(edge: .trailing))
                case .playing:
                    BorderHopGameView(viewModel: viewModel)
                        .transition(.move(edge: .trailing))
                case .results:
                    BorderHopResultsView(viewModel: viewModel)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.35), value: viewModel.phase)
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
