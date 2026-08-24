//
//  BorderBlitzGameView.swift
//  BorderBlitz
//

import SwiftUI

struct BorderBlitzGameView: View {
    @Bindable var viewModel: BorderBlitzViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if viewModel.gameState == .playing {
                playingView
            } else if viewModel.gameState == .roundComplete {
                roundCompleteView
            } else if viewModel.gameState == .gameOver {
                gameOverView
            }

            if viewModel.showFeedback {
                feedbackOverlay
            }
        }
    }

    // MARK: - Playing
    // No motif field here: the screen is a live speech visualiser over a
    // country outline, and §7 keeps motifs out of interactive/visualiser
    // areas. Plain retro ground (supplied by the root) is the correct base.

    private var playingView: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Round indicator + timer
            HStack {
                Text("Round \(viewModel.currentRoundNumber) of \(viewModel.maxRounds)")
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .retroLozenge()
                    .accessibilityLabel("Round \(viewModel.currentRoundNumber) of \(viewModel.maxRounds)")
                Spacer()
                timerView
            }
            .padding(.horizontal, AppTheme.Spacing.md)

            // Country silhouette — fills available space, framed in a cream
            // panel (Rule 5) so the landmass reads as a printed plate. The
            // shape's path data and scaling math are untouched.
            if let country = viewModel.currentCountry {
                BorderBlitzCountrySilhouetteView(country: country)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(AppTheme.Spacing.md)
                    .retroPanel(AppTheme.Retro.panel)
                    .padding(.horizontal, AppTheme.Spacing.md)
            }

            // Letter tiles
            BorderBlitzLetterTilesView(tiles: viewModel.letterRevealManager.tiles)

            // Score display
            HStack {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text("Score: \(viewModel.totalScore)")
                        .font(AppTheme.Retro.Typography.heading(17))
                        .foregroundColor(AppTheme.Retro.panelText)
                        .accessibilityLabel("Score: \(viewModel.totalScore) points")

                    if viewModel.currentStreak > 1 {
                        // Streak heat rides an ink-outlined tangerine chip so
                        // the number stays ink (§8), never colored text on a
                        // busy ground.
                        Text("Streak: \(viewModel.currentStreak) 🔥")
                            .font(AppTheme.Retro.Typography.pillLabel)
                            .foregroundColor(BorderBlitzStyle.chipTextColor(on: BorderBlitzStyle.warningColor))
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(BorderBlitzStyle.warningColor))
                            .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))
                            .accessibilityLabel("Current streak: \(viewModel.currentStreak)")
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
                .retroLozenge()

                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.md)

            // Voice input
            VStack(spacing: AppTheme.Spacing.sm) {
                BorderBlitzWaveformView(
                    audioLevel: viewModel.speechManager.audioLevel,
                    isListening: viewModel.speechManager.isListening,
                    accentColor: BorderBlitzStyle.accent
                )

                HStack(spacing: AppTheme.Spacing.md) {
                    RetroPrimaryButton(title: "I Said It!", icon: "hand.raised.fill",
                                       accent: BorderBlitzStyle.accent) {
                        viewModel.handleManualConfirm()
                    }

                    // Cream panel + ink label is this language's secondary
                    // button; §3.2's one-accent rule keeps poolBlue alone.
                    RetroPrimaryButton(title: "Skip", accent: AppTheme.Retro.panel) {
                        viewModel.skipRound()
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.sm)
        }
    }

    private var timerView: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "clock.fill")
                .foregroundColor(timeColor)
            Text(timeString)
                .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title3))
                .foregroundColor(timeColor)
                .monospacedDigit()
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        // Ink-on-cream lozenge; only the urgent ramp brings color (§3 recipe).
        .retroLozenge()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Int(viewModel.timeRemaining)) seconds remaining")
    }

    private var timeString: String {
        let seconds = Int(viewModel.timeRemaining)
        return String(format: "%02d", seconds)
    }

    private var timeColor: Color {
        if viewModel.timeRemaining <= 10 {
            return BorderBlitzStyle.timerUrgent
        } else if viewModel.timeRemaining <= 20 {
            return BorderBlitzStyle.timerWarning
        } else {
            return BorderBlitzStyle.timerCalm
        }
    }

    // MARK: - Round complete

    private var roundCompleteView: some View {
        ZStack {
            GeometryReader { geo in
                // Interstitial: the result column owns the middle, motifs
                // live in the gutters (§7).
                MotifGroundView(seed: 0xB0DE_8B02,
                                exclusions: [CGRect(x: 16, y: 80,
                                                    width: geo.size.width - 32,
                                                    height: geo.size.height - 100)])
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    if let result = viewModel.roundResults.last {
                        // Result plate — never a naked SF hero (§9).
                        ZStack {
                            Circle().fill(AppTheme.Retro.panel)
                            Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                            Image(systemName: result.guessedCorrectly ? "checkmark" : "xmark")
                                .font(.system(size: 44, weight: .black))
                                .foregroundColor(result.guessedCorrectly
                                                 ? BorderBlitzStyle.successColor
                                                 : BorderBlitzStyle.dangerColor)
                        }
                        .frame(width: 110, height: 110)

                        // Country name — the screen's loudest object: chunky
                        // Lilita, ink on poolBlue, hard-shadowed (§4/§5).
                        Text(result.countryName)
                            .font(AppTheme.Retro.Typography.heading(24, relativeTo: .title))
                            .foregroundColor(AppTheme.Retro.ink)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .retroPanel(BorderBlitzStyle.accent)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                                    .fill(AppTheme.Retro.ink)
                                    .offset(x: AppTheme.Retro.shadowOffset,
                                            y: AppTheme.Retro.shadowOffset)
                            )
                            .rotationEffect(.degrees(-1))

                        // Score breakdown
                        if result.guessedCorrectly {
                            VStack(spacing: AppTheme.Spacing.md) {
                                if result.isPerfect {
                                    Text("PERFECT! 🎉")
                                        .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                                        .foregroundColor(BorderBlitzStyle.chipTextColor(on: BorderBlitzStyle.warningColor))
                                        .padding(.vertical, 2)
                                        .retroLozenge(BorderBlitzStyle.warningColor)
                                }

                                Text("+\(result.score) points")
                                    .font(AppTheme.Retro.Typography.heading(28, relativeTo: .title))
                                    .foregroundColor(AppTheme.Retro.panelText)

                                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                    Text("• Hidden letters: \(result.hiddenLettersCount)")
                                    Text("• Time remaining: \(Int(result.timeRemaining))s")
                                    if result.streak > 1 {
                                        Text("• Streak bonus: \(result.streak)x 🔥")
                                    }
                                }
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .retroCard()
                        }

                        // Total score
                        Text("Total Score: \(viewModel.totalScore)")
                            .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                            .foregroundColor(AppTheme.Retro.panelText)
                            .retroLozenge()
                            .padding(.top, AppTheme.Spacing.sm)

                        // Buttons
                        HStack(spacing: AppTheme.Spacing.md) {
                            RetroPrimaryButton(title: "Continue",
                                               accent: BorderBlitzStyle.accent) {
                                viewModel.continueToNextRound()
                            }

                            RetroPrimaryButton(title: "Menu",
                                               accent: AppTheme.Retro.panel) {
                                viewModel.returnToMenu()
                            }
                        }
                        .padding(.top, AppTheme.Spacing.sm)
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Game over

    private var gameOverView: some View {
        ZStack {
            GeometryReader { geo in
                // Celebration column owns the middle; motifs fill the gutters
                // (§7 / §3 rule 3 — the end state is a package, not a void).
                MotifGroundView(seed: 0xB0DE_8B03,
                                exclusions: [CGRect(x: 16, y: 80,
                                                    width: geo.size.width - 32,
                                                    height: geo.size.height - 100)])
            }
            .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                // Spot plate + framed Lilita heading (§3 recipe, §9).
                ZStack {
                    Circle().fill(AppTheme.Retro.panel)
                    Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                    RetroSpotIllustration(kind: .borderMap)
                        .frame(width: 74, height: 74)
                }
                .frame(width: 110, height: 110)

                Text("Game Complete!")
                    .font(AppTheme.Retro.Typography.heading(24, relativeTo: .title))
                    .foregroundColor(AppTheme.Retro.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .retroPanel(BorderBlitzStyle.accent)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                            .fill(AppTheme.Retro.ink)
                            .offset(x: AppTheme.Retro.shadowOffset,
                                    y: AppTheme.Retro.shadowOffset)
                    )
                    .rotationEffect(.degrees(-1))

                // Final score — big Lilita numeral on cream (§8: the count is
                // body-adjacent reading, so it stays on a panel).
                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("Final Score")
                        .font(AppTheme.Typography.secondary)
                        .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))

                    Text("\(viewModel.totalScore)")
                        .font(AppTheme.Retro.Typography.heading(52, relativeTo: .largeTitle))
                        .foregroundColor(AppTheme.Retro.panelText)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .retroCard()

                // Stats
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Rounds Played: \(viewModel.roundResults.count)")
                    Text("Correct: \(viewModel.roundResults.filter { $0.guessedCorrectly }.count)")
                    Text("Best Streak: \(viewModel.roundResults.map { $0.streak }.max() ?? 0)")
                }
                .font(AppTheme.Retro.Typography.cardTitle)
                .foregroundColor(AppTheme.Retro.panelText)
                .frame(maxWidth: .infinity)
                .retroCard()

                RetroPrimaryButton(title: "Back to Menu", icon: "house",
                                   accent: BorderBlitzStyle.accent) {
                    viewModel.returnToMenu()
                }
            }
            .padding(AppTheme.Spacing.md)
        }
    }

    // MARK: - Feedback overlay

    private var feedbackOverlay: some View {
        VStack {
            Spacer()
            // Cream display type on a saturated fill is allowed at ≥17pt
            // Lilita (§8); the panel carries the ink outline + hard shadow.
            Text(viewModel.feedbackMessage)
                .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                .foregroundColor(AppTheme.Retro.cream)
                .padding(AppTheme.Spacing.md)
                .retroPanel(viewModel.feedbackIsCorrect
                            ? BorderBlitzStyle.successColor
                            : BorderBlitzStyle.dangerColor)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                        .fill(AppTheme.Retro.ink)
                        .offset(x: AppTheme.Retro.shadowOffset,
                                y: AppTheme.Retro.shadowOffset)
                )
                .rotationEffect(.degrees(-1))
                .padding(AppTheme.Spacing.md)
            Spacer()
        }
        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
        .animation(reduceMotion ? nil : .spring(), value: viewModel.showFeedback)
    }
}
