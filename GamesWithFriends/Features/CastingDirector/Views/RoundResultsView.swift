import SwiftUI

/// Score display after each round
struct RoundResultsView: View {
    @ObservedObject var viewModel: CastingDirectorViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [GameTheme.castingDirector.accentColor.opacity(0.2), GameTheme.castingDirector.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Result header
                    resultHeader

                    // Actor reveal
                    actorReveal

                    // Score breakdown
                    scoreBreakdown

                    // Clue summary
                    clueSummary

                    // Action buttons
                    actionButtons
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden()
    }

    // MARK: - Result Header

    private var resultHeader: some View {
        VStack(spacing: 12) {
            if viewModel.roundState.foundByPlayer != nil {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppTheme.success)

                Text("Correct!")
                    .font(AppTheme.Typography.hero)
                    .fontWeight(.bold)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppTheme.error)

                Text("Time's Up!")
                    .font(AppTheme.Typography.hero)
                    .fontWeight(.bold)
            }

            if viewModel.gameMode == .passAndPlay, let player = viewModel.roundState.foundByPlayer {
                HStack(spacing: 6) {
                    Circle()
                        .fill(player.color)
                        .frame(width: 12, height: 12)
                    Text("\(player.name) got it!")
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top)
    }

    // MARK: - Actor Reveal

    private var actorReveal: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            if let actor = viewModel.roundState.targetActor {
                Text("The actor was...")
                    .font(AppTheme.Typography.secondary)
                    .foregroundStyle(.secondary)

                Text(actor.name)
                    .font(AppTheme.Typography.screenTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(GameTheme.castingDirector.accentColor)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    // MARK: - Score Breakdown

    private var scoreBreakdown: some View {
        VStack(spacing: 12) {
            Text("Score")
                .font(AppTheme.Typography.cardTitle)

            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    ScoreRow(label: "Base Score", value: "1,000")
                    ScoreRow(label: "Clues Revealed (\(viewModel.roundState.cluesRevealed))", value: "-\(viewModel.roundState.cluesRevealed * 50)", isNegative: true)
                    if viewModel.roundState.wrongGuessCount > 0 {
                        ScoreRow(label: "Wrong Guesses (\(viewModel.roundState.wrongGuessCount))", value: "-\(viewModel.roundState.wrongGuessCount * viewModel.difficulty.wrongGuessPenalty)", isNegative: true)
                    }

                    Divider()

                    HStack {
                        Text("Round Score")
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(viewModel.roundState.currentScore)")
                            .fontWeight(.bold)
                            .foregroundStyle(GameTheme.castingDirector.accentColor)
                    }
                    .font(AppTheme.Typography.subsectionHeader)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    // MARK: - Clue Summary

    private var clueSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Clues")
                .font(AppTheme.Typography.cardTitle)

            VStack(spacing: 6) {
                ForEach(viewModel.roundState.revealedClues) { clue in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text("\(clue.orderNumber)")
                            .font(AppTheme.Typography.tabLabel)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(tierColor(clue.tier))
                            .clipShape(Circle())

                        Image(systemName: clue.type.icon)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(tierColor(clue.tier))
                            .frame(width: 16)

                        Text(clue.text)
                            .font(AppTheme.Typography.secondary)
                            .lineLimit(2)

                        Spacer()
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.nextRound()
            } label: {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text(viewModel.currentRound >= viewModel.numberOfRounds ? "See Final Results" : "Next Round")
                }
                .font(AppTheme.Typography.subsectionHeader)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(GameTheme.castingDirector.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button {
                viewModel.returnToSetup()
            } label: {
                Text("Back to Setup")
                    .font(AppTheme.Typography.secondary)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top)
    }

    private func tierColor(_ tier: ClueTier) -> Color {
        switch tier {
        case .vague: return AppTheme.skyBlue
        case .narrowing: return AppTheme.forestGreen
        case .strongSignal: return AppTheme.warmGold
        case .giveaway: return AppTheme.coralRed
        }
    }
}

// MARK: - Score Row

struct ScoreRow: View {
    let label: String
    let value: String
    var isNegative: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.secondary)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.secondary)
                .monospacedDigit()
                .foregroundStyle(isNegative ? .red : .primary)
        }
    }
}
