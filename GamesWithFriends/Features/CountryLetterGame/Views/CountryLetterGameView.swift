import SwiftUI

struct CountryLetterGameView: View {
    @StateObject private var viewModel = CountryGameViewModel()

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.88, green: 0.95, blue: 1.0),
                    Color(red: 0.95, green: 0.96, blue: 0.98),
                    Color(red: 0.89, green: 0.91, blue: 0.94)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

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
