import SwiftUI

struct RevealView: View {
    var viewModel: VibeCheckViewModel
    @State private var showResults = false
    @State private var revealedPositions = false

    var body: some View {
        ZStack {
            GeometryReader { geo in
                MotifGroundView(seed: 0x71BE_0C06,
                                exclusions: [CGRect(x: 8, y: 8,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 16)])
            }
            .ignoresSafeArea()

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
                .scrollIndicators(.hidden)

                // Continue button
                continueButton
            }
            .padding()
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
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .retroLozenge()
            }

            // Framed Lilita title on the game accent (Rule 4).
            Text("Results")
                .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                .foregroundColor(VibeCheckStyle.chipTextColor(on: VibeCheckStyle.accent))
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .retroPanel(VibeCheckStyle.accent)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                        .fill(AppTheme.Retro.ink)
                        .offset(x: AppTheme.Retro.shadowOffset,
                                y: AppTheme.Retro.shadowOffset)
                )
                .rotationEffect(.degrees(-1))
        }
    }

    private var promptCard: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("THE PROMPT")
                .font(AppTheme.Retro.Typography.pillLabel)
                .foregroundColor(AppTheme.Retro.cocoa)
                .tracking(2)

            if let round = viewModel.currentRound {
                Text("\"\(round.prompt)\"")
                    .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title3))
                    .foregroundColor(AppTheme.Retro.panelText)
                    .multilineTextAlignment(.center)
            }

            if let setter = viewModel.promptSetterTeam {
                Text("Set by \(setter.name)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Retro.cocoa)
            }
        }
        .frame(maxWidth: .infinity)
        .retroCard()
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
                    legendSwatch(color: VibeCheckStyle.targetMarker, label: "Target")
                    legendSwatch(color: VibeCheckStyle.guessMarker, label: "Your Guess")
                }
                .padding(.vertical, AppTheme.Spacing.xs)
                .retroLozenge()
            }
        }
    }

    private func legendSwatch(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                .frame(width: 12, height: 12)
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.panelText)
        }
    }

    private var resultsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("SCORING")
                .font(AppTheme.Retro.Typography.pillLabel)
                .foregroundColor(AppTheme.Retro.cocoa)
                .tracking(2)

            ForEach(viewModel.getRoundResults()) { result in
                TeamResultRow(result: result)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .frame(maxWidth: .infinity)
        .retroCard()
    }

    private var continueButton: some View {
        RetroPrimaryButton(title: viewModel.isGameOver ? "See Final Results" : "Continue",
                           icon: viewModel.isGameOver ? "trophy.fill" : "arrow.right",
                           accent: VibeCheckStyle.accent) {
            viewModel.proceedFromReveal()
        }
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
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText)

                Text(distanceText)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
            }

            Spacer()

            // Points badge — flat zone fill, ink outline, ink numeral (§8).
            VibeCheckPointsChip(zone: result.zone, points: result.pointsEarned)
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .padding(.horizontal, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                .fill(AppTheme.Retro.ground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                .stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth)
        )
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
