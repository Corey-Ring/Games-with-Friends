import SwiftUI

/// Root view for Movie Chain game - manages navigation between game phases
struct MovieChainRootView: View {
    @StateObject private var viewModel = MovieChainViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch viewModel.gamePhase {
            case .setup:
                MovieChainSetupView(viewModel: viewModel)

            case .playing:
                MovieChainGameView(viewModel: viewModel)

            case .chainBroken(let reason):
                ChainBreakView(viewModel: viewModel, reason: reason)

            case .gameOver(let winner):
                MovieChainGameOverView(viewModel: viewModel, winner: winner)
            }
        }
        .navigationBarBackButtonHidden(viewModel.gamePhase != .setup)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .inactive, .background:
                viewModel.pauseTimer()
            case .active:
                viewModel.resumeTimer()
            default:
                break
            }
        }
    }
}

#Preview {
    NavigationStack {
        MovieChainRootView()
    }
}
