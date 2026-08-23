import SwiftUI

/// Score display after each round
struct RoundResultsView: View {
    @ObservedObject var viewModel: CastingDirectorViewModel

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Interstitial screen — content column owns the middle,
                // motifs keep to the gutters (§7).
                MotifGroundView(seed: 0xCA57_0D02,
                                exclusions: [CGRect(x: 8, y: 60,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 60)])
            }
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
            .scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden()
    }

    // MARK: - Result Header

    private var resultHeader: some View {
        VStack(spacing: 12) {
            let didFind = viewModel.roundState.foundByPlayer != nil

            // Status disc on a spot plate — never a naked SF hero (§9).
            ZStack {
                Circle().fill(didFind ? CastingDirectorStyle.successColor : CastingDirectorStyle.errorColor)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                Image(systemName: didFind ? "checkmark" : "xmark")
                    .font(.system(size: 34, weight: .black))
                    .foregroundColor(AppTheme.Retro.ink)
            }
            .frame(width: 84, height: 84)

            Text(didFind ? "Correct!" : (viewModel.roundState.gaveUp ? "Revealed!" : "Out of Clues!"))
                .font(AppTheme.Retro.Typography.heading(24, relativeTo: .title))
                .foregroundColor(AppTheme.Retro.ink)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .retroPanel(didFind ? CastingDirectorStyle.successColor : CastingDirectorStyle.accent)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                        .fill(AppTheme.Retro.ink)
                        .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
                )
                .rotationEffect(.degrees(-1))

            if viewModel.gameMode == .passAndPlay, let player = viewModel.roundState.foundByPlayer {
                HStack(spacing: 6) {
                    Circle()
                        .fill(player.color)
                        .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                        .frame(width: 12, height: 12)
                    Text("\(player.name) got it!")
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .foregroundColor(AppTheme.Retro.panelText)
                }
                .retroLozenge()
                .rotationEffect(.degrees(0.8))
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
                    .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))

                Text(actor.name)
                    .font(AppTheme.Retro.Typography.heading(26, relativeTo: .title))
                    .foregroundColor(AppTheme.Retro.panelText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .retroCard()
    }

    // MARK: - Score Breakdown

    private var scoreBreakdown: some View {
        VStack(spacing: 12) {
            Text("Score")
                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)

            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    if viewModel.roundState.foundByPlayer != nil {
                        // The line items must sum to the awarded score —
                        // this breakdown is derived from the same state the VM scored with.
                        let extraClues = max(0, viewModel.roundState.cluesRevealed - 1)
                        let clueCost = extraClues * 50
                        let wrongCost = viewModel.roundState.wrongGuessCount * viewModel.difficulty.wrongGuessPenalty
                        let floorAdjustment = viewModel.roundState.currentScore - (1000 - clueCost - wrongCost)

                        ScoreRow(label: "Base Score", value: "1,000")
                        if extraClues > 0 {
                            ScoreRow(label: "Extra Clues (\(extraClues)) — first is free", value: "-\(clueCost)", isNegative: true)
                        }
                        if viewModel.roundState.wrongGuessCount > 0 {
                            ScoreRow(label: "Wrong Guesses (\(viewModel.roundState.wrongGuessCount))", value: "-\(wrongCost)", isNegative: true)
                        }
                        if floorAdjustment != 0 {
                            ScoreRow(label: "Score can't go below 0", value: "+\(floorAdjustment)")
                        }
                    } else {
                        ScoreRow(
                            label: viewModel.roundState.gaveUp ? "Answer revealed — no points" : "No correct guess",
                            value: "0"
                        )
                    }

                    Rectangle()
                        .fill(AppTheme.Retro.ink.opacity(0.25))
                        .frame(height: 1.5)

                    HStack {
                        Text("Round Score")
                            .foregroundColor(AppTheme.Retro.panelText)
                        Spacer()
                        Text("\(viewModel.roundState.currentScore)")
                            .foregroundColor(AppTheme.Retro.panelText)
                            .monospacedDigit()
                    }
                    .font(AppTheme.Retro.Typography.heading(17))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .retroCard()
    }

    // MARK: - Clue Summary

    private var clueSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Clues")
                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)

            VStack(spacing: 6) {
                ForEach(viewModel.roundState.revealedClues) { clue in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text("\(clue.orderNumber)")
                            .font(AppTheme.Typography.tabLabel)
                            .fontWeight(.bold)
                            .foregroundStyle(CastingDirectorStyle.chipTextColor(on: CastingDirectorStyle.tierColor(clue.tier)))
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(CastingDirectorStyle.tierColor(clue.tier)))
                            .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1.5))

                        Image(systemName: clue.type.icon)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Retro.panelText.opacity(0.7))
                            .frame(width: 16)

                        Text(clue.text)
                            .font(AppTheme.Typography.secondary)
                            .foregroundColor(AppTheme.Retro.panelText)
                            .lineLimit(2)

                        Spacer()
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            RetroPrimaryButton(
                title: viewModel.currentRound >= viewModel.numberOfRounds ? "See Final Results" : "Next Round",
                icon: "arrow.right",
                accent: CastingDirectorStyle.accent
            ) {
                viewModel.nextRound()
            }

            RetroPrimaryButton(title: "Back to Setup", icon: "gearshape",
                               accent: AppTheme.Retro.panel) {
                viewModel.returnToSetup()
            }
        }
        .padding(.top)
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
                .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
            Spacer()
            Text(value)
                .font(AppTheme.Typography.secondary)
                .monospacedDigit()
                .foregroundColor(isNegative ? CastingDirectorStyle.errorColor : AppTheme.Retro.panelText)
        }
    }
}
