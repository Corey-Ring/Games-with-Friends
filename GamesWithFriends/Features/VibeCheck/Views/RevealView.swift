import SwiftUI

struct RevealView: View {
    var viewModel: VibeCheckViewModel
    @State private var showResults = false
    @State private var revealedPositions = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerSection

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // The prompt
                    promptCard

                    // Spectrum with both positions revealed
                    if let round = viewModel.currentRound {
                        revealSection(round: round)
                    }

                    // Results for each team
                    if showResults {
                        resultsSection
                    }
                }
            }

            // Continue button
            continueButton
        }
        .padding()
        .background {
            LinearGradient(
                colors: [GameTheme.vibeCheck.accentColor.opacity(0.1), GameTheme.vibeCheck.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .onAppear {
            // Animate the reveal
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    revealedPositions = true
                }
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showResults = true
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            if let round = viewModel.currentRound {
                Text("Round \(round.roundNumber)")
                    .font(AppTheme.Typography.secondary)
                    .foregroundStyle(.secondary)
            }

            Text("RESULTS")
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(.purple)
        }
    }

    private var promptCard: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("THE PROMPT")
                .font(AppTheme.Typography.pillLabel)
                .foregroundStyle(.secondary)
                .tracking(2)

            if let round = viewModel.currentRound {
                Text("\"\(round.prompt)\"")
                    .font(AppTheme.Typography.subsectionHeader.weight(.semibold))
                    .multilineTextAlignment(.center)
            }

            if let setter = viewModel.promptSetterTeam {
                Text("Set by \(setter.name)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(AppTheme.pureWhite)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
    }

    @ViewBuilder
    private func revealSection(round: VibeCheckRound) -> some View {
        let results = viewModel.getRoundResults()

        // For single team or first result, show the main reveal slider
        if let firstResult = results.first {
            VStack(spacing: AppTheme.Spacing.md) {
                RevealSliderView(
                    spectrum: round.spectrum,
                    targetPosition: round.targetPosition,
                    guessPosition: firstResult.guessedPosition,
                    zone: firstResult.zone
                )
                .opacity(revealedPositions ? 1 : 0)
                .scaleEffect(revealedPositions ? 1 : 0.9)

                // Legend
                HStack(spacing: AppTheme.Spacing.lg) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppTheme.success)
                            .frame(width: 12, height: 12)
                        Text("Target")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppTheme.warning)
                            .frame(width: 12, height: 12)
                        Text("Your Guess")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var resultsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("SCORING")
                .font(AppTheme.Typography.pillLabel)
                .foregroundStyle(.secondary)
                .tracking(2)

            ForEach(viewModel.getRoundResults()) { result in
                TeamResultRow(result: result)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(AppTheme.pureWhite)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
    }

    private var continueButton: some View {
        Button {
            viewModel.proceedFromReveal()
        } label: {
            HStack {
                Image(systemName: viewModel.isGameOver ? "trophy.fill" : "arrow.right.circle.fill")
                Text(viewModel.isGameOver ? "SEE FINAL RESULTS" : "CONTINUE")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background {
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
        .buttonStyle(.plain)
        .opacity(showResults ? 1 : 0.5)
        .disabled(!showResults)
    }
}

// MARK: - Team Result Row

struct TeamResultRow: View {
    let result: VibeCheckRoundResult

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Team name
            VStack(alignment: .leading, spacing: 2) {
                Text(result.teamName)
                    .font(AppTheme.Typography.cardTitle)

                Text(distanceText)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Points badge
            HStack(spacing: 6) {
                Circle()
                    .fill(result.zone.color)
                    .frame(width: 16, height: 16)

                Text("+\(result.pointsEarned)")
                    .font(AppTheme.Typography.subsectionHeader.weight(.bold))
                    .foregroundStyle(result.zone.color)
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background {
                Capsule()
                    .fill(result.zone.color.opacity(0.15))
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(AppTheme.warmLinen)
        }
    }

    private var distanceText: String {
        let distance = abs(result.guessedPosition - result.targetPosition)
        let percentage = Int(distance * 100)
        return "\(percentage)% away"
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
    viewModel.currentGuessPosition = 0.18
    viewModel.submitGuess()
    return RevealView(viewModel: viewModel)
}
