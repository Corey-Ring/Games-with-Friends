//
//  FinishTheLineResultsView.swift
//  GamesWithFriends
//

import SwiftUI

struct FinishTheLineResultsView: View {
    @Bindable var viewModel: FinishTheLineViewModel
    @Environment(\.dismiss) private var dismiss

    private var isNewBest: Bool {
        viewModel.score > 0 && viewModel.score >= viewModel.personalBest
    }

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Scrolling result column runs the full width; motifs keep to
                // the nav strip and the outer gutters (§7).
                MotifGroundView(seed: 0xFA11_0E03,
                                exclusions: [CGRect(x: 8, y: 56,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 56)])
            }
            .ignoresSafeArea()

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
                            systemImage: "checkmark",
                            tint: FinishTheLineStyle.correctColor,
                            quotes: viewModel.correctQuotes
                        )
                        .staggeredAppear(index: 3)
                    }

                    if !viewModel.skippedQuotes.isEmpty {
                        playedSection(
                            title: "Skipped",
                            systemImage: "forward.fill",
                            tint: FinishTheLineStyle.skippedColor,
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
                .font(AppTheme.Retro.Typography.pillLabel)
                // Mustard metal, ink label (§8 — ink passes on mustard); the
                // gold gradient is retired (§9).
                .foregroundColor(FinishTheLineStyle.chipTextColor(on: FinishTheLineStyle.bestColor))
                .retroLozenge(FinishTheLineStyle.bestColor)
                .transition(.scale.combined(with: .opacity))
            }

            FinishTheLineSpotPlate()

            FinishTheLineTitlePanel(text: headline)

            Text(subhead)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Retro.panelText)
                .multilineTextAlignment(.center)
                .retroLozenge()
                .rotationEffect(.degrees(0.8))
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
                .font(AppTheme.Retro.Typography.pillLabel)
                .tracking(2)
                .foregroundColor(AppTheme.Retro.cocoa)

            // Big Lilita numeral, ink on cream — the count is reading matter,
            // so it stays on the panel rather than a saturated fill (§8).
            AnimatedScoreText(
                targetScore: viewModel.score,
                color: AppTheme.Retro.panelText,
                font: AppTheme.Retro.Typography.heading(72, relativeTo: .largeTitle)
            )
            .accessibilityLabel("Final score: \(viewModel.score) points")

            Text(multiplierLabel)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.cocoa)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
        .retroCard()
    }

    private var multiplierLabel: String {
        let points = FinishTheLineViewModel.pointsPerCorrect(for: viewModel.difficulty)
        return "\(viewModel.difficulty.displayName) quotes · \(points) pts each, scored live"
    }

    // MARK: - Stats

    private var statsGrid: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            StatTile(
                icon: "checkmark",
                iconColor: FinishTheLineStyle.correctColor,
                value: "\(viewModel.correctQuotes.count)",
                label: "Correct"
            )

            StatTile(
                icon: "flame.fill",
                iconColor: FinishTheLineStyle.streakOnFireColor,
                value: "\(viewModel.bestStreak)",
                label: "Best streak"
            )

            StatTile(
                icon: "forward.fill",
                iconColor: FinishTheLineStyle.skippedColor,
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
                FinishTheLineStatusDisc(systemImage: systemImage, color: tint, diameter: 24)
                Text(title)
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText)
                Text("• \(quotes.count)")
                    .font(AppTheme.Typography.detail)
                    .foregroundColor(AppTheme.Retro.cocoa)
            }

            VStack(spacing: AppTheme.Spacing.xs) {
                ForEach(quotes) { quote in
                    playedRow(quote: quote, accent: tint)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
    }

    private func playedRow(quote: Quote, accent: Color) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            // Outlined rule instead of a 60%-opacity tint bar (Rule 1).
            Capsule()
                .fill(accent)
                .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                .frame(width: 5)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("\u{201C}\(quote.fullLine)\u{201D}")
                    .font(AppTheme.Typography.body.weight(.medium))
                    .foregroundColor(AppTheme.Retro.panelText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(quote.source)
                    .font(AppTheme.Typography.caption.italic())
                    .foregroundColor(AppTheme.Retro.cocoa)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            RetroPrimaryButton(
                title: "Play Again",
                icon: "arrow.clockwise",
                accent: FinishTheLineStyle.accent,
                textColor: FinishTheLineStyle.chipTextColor(on: FinishTheLineStyle.accent)
            ) {
                viewModel.playAgain()
            }

            RetroPrimaryButton(
                title: "Pass the Phone",
                icon: "person.2.fill",
                accent: AppTheme.Retro.panel,
                textColor: AppTheme.Retro.panelText
            ) {
                viewModel.passPhone()
            }

            if viewModel.score > 0 {
                Text(verbatim: "Pass the phone and \(viewModel.score) becomes the score to beat.")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .multilineTextAlignment(.center)
                    .retroLozenge()
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
            FinishTheLineStatusDisc(systemImage: icon, color: iconColor)

            Text(value)
                .font(AppTheme.Retro.Typography.heading(26, relativeTo: .title2))
                .foregroundColor(AppTheme.Retro.panelText)
                .monospacedDigit()

            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.cocoa)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.sm)
        .retroCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
