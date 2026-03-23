import SwiftUI

struct TeamGuessingView: View {
    @Bindable var viewModel: VibeCheckViewModel

    var body: some View {
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
        .background {
            LinearGradient(
                colors: [GameTheme.vibeCheck.accentColor.opacity(0.1), GameTheme.vibeCheck.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            if let round = viewModel.currentRound {
                Text("Round \(round.roundNumber)")
                    .font(AppTheme.Typography.secondary)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let team = viewModel.currentGuessingTeam {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "hand.tap.fill")
                    Text(team.name)
                }
                .font(AppTheme.Typography.secondary.weight(.semibold))
                .foregroundStyle(.orange)
            }
        }
    }

    private var promptCard: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            if let round = viewModel.currentRound {
                Text("\"\(round.prompt)\"")
                    .font(AppTheme.Typography.body.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.sm)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(AppTheme.pureWhite)
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        }
    }

    private var instructionsCard: some View {
        HStack(spacing: 6) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
                .font(AppTheme.Typography.secondary)

            Text("Discuss as a team! Slide to where you think the prompt belongs.")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.sm)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.warmLinen)
        }
    }

    private var lockInButton: some View {
        Button {
            viewModel.submitGuess()
        } label: {
            HStack {
                Image(systemName: "lock.fill")
                Text("LOCK IN GUESS")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background {
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
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
