import SwiftUI

struct CountryLetterGameView: View {
    @State private var viewModel = CountryGameViewModel()

    var body: some View {
        ZStack {
            // Retro ground base (§3.1). Each state below lays its own
            // MotifGroundView with a distinct seed on top of this, so the
            // ground never flashes through during a state transition.
            AppTheme.Retro.ground.ignoresSafeArea()

            // Content based on game state
            switch viewModel.gameState {
            case .selectingLetter:
                LetterSelectionView(viewModel: viewModel)

            case .playing:
                GamePlayView(viewModel: viewModel)

            case .finished:
                ResultsView(viewModel: viewModel)
            }
        }
        // §6: functional nav glyphs (the hub's back chevron) render ink.
        .tint(AppTheme.Retro.ink)
    }
}
