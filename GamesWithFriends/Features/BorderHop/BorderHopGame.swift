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
