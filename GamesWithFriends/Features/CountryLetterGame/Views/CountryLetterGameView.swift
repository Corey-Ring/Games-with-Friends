import SwiftUI

struct CountryLetterGameView: View {
    @State private var viewModel = CountryGameViewModel()

    var body: some View {
        ZStack {
            GameBackground(gameTheme: .countryLetter)

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
    }
}
