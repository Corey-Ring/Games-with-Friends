import SwiftUI

struct CompetitionGuessingView: View {
    @Bindable var viewModel: CompetitionVibeCheckViewModel

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // The slider owns the middle of the screen and must stay
                // clear of motifs (§7 — no motifs on interactive controls).
                MotifGroundView(seed: 0x71BE_0C05,
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

            if let player = viewModel.currentGuessingPlayer {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "hand.tap.fill")
                    Text(player.name)
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
            VibeCheckStatusBadge(systemImage: "eye.slash.fill",
                                 color: VibeCheckStyle.accent,
                                 diameter: 20)

            Text("Make your guess! Don't let others see your answer.")
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
    let viewModel = CompetitionVibeCheckViewModel()
    viewModel.settings.playerCount = 4
    viewModel.proceedToPlayerSetup()
    viewModel.startGame()
    viewModel.confirmVibeSetterReady()
    viewModel.currentPrompt = "Clipping your nails in a movie theater"
    viewModel.submitPrompt()
    viewModel.confirmGuessingPlayerReady()
    return CompetitionGuessingView(viewModel: viewModel)
}
