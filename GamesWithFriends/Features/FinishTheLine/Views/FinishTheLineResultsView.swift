//
//  FinishTheLineResultsView.swift
//  GamesWithFriends
//

import SwiftUI

struct FinishTheLineResultsView: View {
    @Bindable var viewModel: FinishTheLineViewModel
    @Environment(\.dismiss) private var dismiss

    private let theme = GameTheme.finishTheLine

    private var isNewBest: Bool {
        viewModel.score > 0 && viewModel.score >= viewModel.personalBest
    }

    var body: some View {
        ZStack {
            GameBackground(gameTheme: theme)

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    headerBanner
                        .staggeredAppear(index: 0)

                    scoreCard
                        .staggeredAppear(index: 1)

                    statsGrid
                        .staggeredAppear(index: 2)

                    if !viewModel.correctQuotes.isEmpty {
                        playedSection(
                            title: "Nailed it",
                            systemImage: "checkmark.seal.fill",
                            tint: AppTheme.success,
                            quotes: viewModel.correctQuotes
                        )
                        .staggeredAppear(index: 3)
                    }

                    if !viewModel.skippedQuotes.isEmpty {
                        playedSection(
                            title: "Skipped",
                            systemImage: "forward.fill",
                            tint: AppTheme.warning,
                            quotes: viewModel.skippedQuotes
                        )
                        .staggeredAppear(index: 4)
                    }

                    actionButtons
                        .staggeredAppear(index: 5)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Header

    private var headerBanner: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            if isNewBest {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "crown.fill")
                    Text("NEW PERSONAL BEST")
                        .tracking(2)
                }
                .font(AppTheme.Typography.footnote.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: [AppTheme.medalGold, AppTheme.warmGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                )
                .transition(.scale.combined(with: .opacity))
            }

            Text(headline)
                .font(AppTheme.Typography.hero)
                .foregroundColor(AppTheme.deepCharcoal)
                .multilineTextAlignment(.center)

            Text(subhead)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.mediumGray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppTheme.Spacing.sm)
    }

    private var headline: String {
        if viewModel.correctQuotes.isEmpty {
            return "Warm-up round"
        }
        if isNewBest {
            return "You made history."
        }
        switch viewModel.bestStreak {
        case 0...2: return "That's a wrap."
        case 3...5: return "Silver screen stuff."
        case 6...9: return "Studio recall."
        default: return "Total showstopper."
        }
    }

    private var subhead: String {
        if viewModel.correctQuotes.isEmpty {
            return "The mic was listening. Shake it off and try a warmer category."
        }
        return "\(viewModel.correctQuotes.count) quote\(viewModel.correctQuotes.count == 1 ? "" : "s") delivered."
    }

    // MARK: - Score card

    private var scoreCard: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("FINAL SCORE")
                .font(AppTheme.Typography.caption.weight(.bold))
                .tracking(2)
                .foregroundColor(theme.accentColor)

            AnimatedScoreText(
                targetScore: viewModel.score,
                color: theme.accentColor,
                font: .system(size: 72, weight: .heavy, design: .rounded)
            )
            .accessibilityLabel("Final score: \(viewModel.score) points")

            Text(multiplierLabel)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.mediumGray)
        }
        .padding(.vertical, AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
        .gameCard()
    }

    private var multiplierLabel: String {
        let m = viewModel.difficulty.multiplier
        let formatted = String(format: "%.1f×", m)
        return "\(viewModel.difficulty.displayName) multiplier (\(formatted))"
    }

    // MARK: - Stats

    private var statsGrid: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            StatTile(
                icon: "checkmark.circle.fill",
                iconColor: AppTheme.success,
                value: "\(viewModel.correctQuotes.count)",
                label: "Correct"
            )

            StatTile(
                icon: "flame.fill",
                iconColor: AppTheme.brandOrange,
                value: "\(viewModel.bestStreak)",
                label: "Best streak"
            )

            StatTile(
                icon: "forward.fill",
                iconColor: AppTheme.warning,
                value: "\(viewModel.skippedQuotes.count)",
                label: "Skipped"
            )
        }
    }

    // MARK: - Quotes played

    private func playedSection(
        title: String,
        systemImage: String,
        tint: Color,
        quotes: [Quote]
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: systemImage)
                    .font(.caption)
                    .foregroundColor(tint)
                Text(title)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(AppTheme.deepCharcoal)
                Text("• \(quotes.count)")
                    .font(AppTheme.Typography.detail)
                    .foregroundColor(AppTheme.mediumGray)
            }

            VStack(spacing: AppTheme.Spacing.xs) {
                ForEach(quotes) { quote in
                    playedRow(quote: quote, accent: tint)
                }
            }
        }
        .gameCard()
    }

    private func playedRow(quote: Quote, accent: Color) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            RoundedRectangle(cornerRadius: 3)
                .fill(accent.opacity(0.6))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("\u{201C}\(quote.fullLine)\u{201D}")
                    .font(AppTheme.Typography.body.weight(.medium))
                    .foregroundColor(AppTheme.deepCharcoal)
                    .fixedSize(horizontal: false, vertical: true)

                Text(quote.source)
                    .font(AppTheme.Typography.caption.italic())
                    .foregroundColor(AppTheme.mediumGray)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            PrimaryButton(title: "Play Again", icon: "arrow.clockwise") {
                viewModel.playAgain()
            }

            SecondaryButton(title: "Back to Menu", icon: "line.3.horizontal") {
                viewModel.passPhone()
            }
        }
    }
}

// MARK: - Stat tile

private struct StatTile: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(iconColor)

            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.deepCharcoal)
                .monospacedDigit()

            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.mediumGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
        .gameCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
