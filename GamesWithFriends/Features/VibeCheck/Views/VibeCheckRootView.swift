import SwiftUI

/// Root for Vibe Check 1.0 — drives the Competition flow directly.
///
/// Classic mode is hidden for 1.0 (see DECISIONS.md). This root deliberately
/// never instantiates `VibeCheckViewModel` (the classic state machine), so no
/// stray state mutation can surface a classic screen. To revive Classic in
/// 1.1, restore the mode-picker root from git history.
struct VibeCheckRootView: View {
    @State private var viewModel = CompetitionVibeCheckViewModel()

    var body: some View {
        Group {
            switch viewModel.gameState {
            case .setup:
                VibeCheckHomeView(viewModel: viewModel)

            case .playerSetup:
                CompetitionPlayerSetupView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

            case .passingToVibeSetter:
                CompetitionVibeSetterPassView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

            case .promptEntry:
                CompetitionPromptEntryView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

            case .passingToGuesser:
                CompetitionGuesserPassView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

            case .guessing:
                CompetitionGuessingView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

            case .reveal:
                CompetitionRevealView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))

            case .scoreboard:
                CompetitionScoreboardView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

            case .gameOver:
                CompetitionGameOverView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.gameState)
    }
}

#Preview {
    VibeCheckRootView()
}
