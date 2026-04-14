//
//  FinishTheLineGameView.swift
//  GamesWithFriends
//

import SwiftUI

struct FinishTheLineGameView: View {
    @Bindable var viewModel: FinishTheLineViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let theme = GameTheme.finishTheLine

    var body: some View {
        ZStack {
            GameBackground(gameTheme: theme)

            VStack(spacing: AppTheme.Spacing.md) {
                topHUD
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.sm)

                quoteStage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, AppTheme.Spacing.md)

                bottomControls
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.md)
            }
        }
    }

    // MARK: - Top HUD

    private var topHUD: some View {
        HStack(alignment: .center) {
            Button {
                viewModel.quitRound()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.deepCharcoal)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(AppTheme.pureWhite.opacity(0.85))
                    )
                    .overlay(
                        Circle()
                            .stroke(theme.accentColor.opacity(0.25), lineWidth: 1)
                    )
            }
            .pressable()
            .accessibilityLabel("Quit round")

            Spacer()

            SpotlightTimerView(
                timeRemaining: viewModel.timeRemaining,
                totalDuration: FinishTheLineViewModel.roundDuration,
                accentColor: theme.accentColor
            )

            Spacer()

            scorePill
        }
    }

    private var scorePill: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "star.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)

            Text("\(viewModel.score)")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(theme.accentColor)
        )
        .shadow(color: theme.accentColor.opacity(0.35), radius: 6, x: 0, y: 3)
        .accessibilityLabel("Score: \(viewModel.score) points")
    }

    // MARK: - Stage

    private var quoteStage: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Streak badge — only once you're on a roll
            if viewModel.currentStreak >= 2 {
                StreakBadge(streak: viewModel.currentStreak)
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer(minLength: 0)

            if let quote = viewModel.currentQuote {
                QuoteCardView(
                    quote: quote,
                    accentColor: theme.accentColor,
                    isFlashing: viewModel.showCorrectFlash
                )
                .id(quote.id)
                .transition(reduceMotion ? .opacity : quoteTransition)
            }

            Spacer(minLength: 0)

            FinishTheLineWaveformView(
                audioLevel: viewModel.speechManager.audioLevel,
                isListening: viewModel.speechManager.isListening,
                accentColor: theme.accentColor
            )
            .padding(.bottom, AppTheme.Spacing.sm)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.currentStreak)
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: viewModel.currentQuote?.id)
    }

    private var quoteTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    // MARK: - Bottom controls

    private var bottomControls: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Button {
                viewModel.skipCurrentQuote()
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "forward.fill")
                    Text("Skip")
                }
                .font(AppTheme.Typography.buttonLabel)
                .foregroundColor(theme.accentColor)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.accentColor.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.accentColor.opacity(0.3), lineWidth: 1)
                )
            }
            .pressable()
            .accessibilityLabel("Skip this quote. Costs \(FinishTheLineViewModel.skipPenalty) points.")
        }
    }
}
