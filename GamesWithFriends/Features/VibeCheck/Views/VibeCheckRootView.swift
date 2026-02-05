import SwiftUI

struct VibeCheckRootView: View {
    @StateObject private var classicViewModel = VibeCheckViewModel()
    @State private var selectedMode: VibeCheckGameMode = .classic
    @State private var competitionViewModel: CompetitionVibeCheckViewModel?

    var body: some View {
        Group {
            if let competitionVM = competitionViewModel, selectedMode == .competition {
                competitionModeView(viewModel: competitionVM)
            } else {
                classicModeView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: classicViewModel.gameState)
    }

    // MARK: - Classic Mode

    @ViewBuilder
    private var classicModeView: some View {
        switch classicViewModel.gameState {
        case .setup:
            VibeCheckHomeView(viewModel: classicViewModel, selectedMode: $selectedMode)

        case .teamSetup:
            if selectedMode == .competition {
                // Transition to competition mode: create the VM and start its flow
                Color.clear.onAppear {
                    let vm = CompetitionVibeCheckViewModel()
                    vm.settings = classicViewModel.competitionSettings
                    vm.proceedToPlayerSetup()
                    competitionViewModel = vm
                    classicViewModel.gameState = .setup
                }
            } else {
                TeamSetupView(viewModel: classicViewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }

        case .passingToPromptSetter:
            PromptSetterPassView(viewModel: classicViewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

        case .promptEntry:
            PromptEntryView(viewModel: classicViewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

        case .passingToGuessingTeam:
            GuessingTeamPassView(viewModel: classicViewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

        case .guessing:
            TeamGuessingView(viewModel: classicViewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

        case .reveal:
            RevealView(viewModel: classicViewModel)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))

        case .scoreboard:
            ScoreboardView(viewModel: classicViewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

        case .gameOver:
            VibeCheckGameOverView(viewModel: classicViewModel)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
        }
    }

    // MARK: - Competition Mode

    @ViewBuilder
    private func competitionModeView(viewModel: CompetitionVibeCheckViewModel) -> some View {
        switch viewModel.gameState {
        case .setup:
            // Competition VM returned to setup — go back to shared home view
            Color.clear.onAppear {
                competitionViewModel = nil
            }

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
}

#Preview {
    VibeCheckRootView()
}
