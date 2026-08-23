import SwiftUI

struct TeamGuessingView: View {
    @Bindable var viewModel: VibeCheckViewModel

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // The slider owns the middle of the screen and must stay
                // clear of motifs (§7 — no motifs on interactive controls).
                MotifGroundView(seed: 0x71BE_0C04,
                                exclusions: [CGRect(x: 8, y: 8,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 16)])
            }
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // Header
                headerSection

                // The prompt to evaluate
                promptCard

                // Spectrum slider for guessing
                if let round = viewModel.currentRound {
                    SpectrumSliderView(
                        spectrum: round.spectrum,
                        position: $viewModel.currentGuessPosition,
                        isInteractive: true
                    )
                }

                // Instructions
                instructionsCard

                // Lock in button
                lockInButton
            }
            .padding(.horizontal)
            .padding(.top, AppTheme.Spacing.sm)
            .padding(.bottom)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            if let round = viewModel.currentRound {
                Text("Round \(round.roundNumber)")
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .retroLozenge()
            }

            Spacer()

            if let team = viewModel.currentGuessingTeam {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "hand.tap.fill")
                    Text(team.name)
                }
                .font(AppTheme.Retro.Typography.pillLabel)
                .foregroundColor(VibeCheckStyle.chipTextColor(on: VibeCheckStyle.guesserRole))
                .retroLozenge(VibeCheckStyle.guesserRole)
            }
        }
    }

    private var promptCard: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            if let round = viewModel.currentRound {
                Text("\"\(round.prompt)\"")
                    .font(AppTheme.Retro.Typography.heading(19, relativeTo: .title3))
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
        .retroCard()
    }

    private var instructionsCard: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            VibeCheckStatusBadge(systemImage: "lightbulb.fill",
                                 color: AppTheme.Retro.mustard,
                                 diameter: 20)

            Text("Discuss as a team! Slide to where you think the prompt belongs.")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.panelText)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .frame(maxWidth: .infinity)
        .retroLozenge()
    }

    private var lockInButton: some View {
        RetroPrimaryButton(title: "Lock In Guess", icon: "lock.fill",
                           accent: VibeCheckStyle.accent) {
            viewModel.submitGuess()
        }
    }
}

#Preview {
    let viewModel = VibeCheckViewModel()
    viewModel.settings.teamCount = 2
    viewModel.settings.playersPerTeam = 3
    viewModel.proceedToTeamSetup()
    viewModel.startGame()
    viewModel.confirmPromptSetterReady()
    viewModel.currentPrompt = "Clipping your nails in a movie theater"
    viewModel.submitPrompt()
    viewModel.confirmGuessingTeamReady()
    return TeamGuessingView(viewModel: viewModel)
}
