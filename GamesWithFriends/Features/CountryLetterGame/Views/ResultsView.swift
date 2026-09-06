import SwiftUI

struct ResultsView: View {
    var viewModel: CountryGameViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.systemChromeInsets) private var chrome

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Scrolling result column runs the full width; motifs keep to
                // the top band right of the "Main menu" lozenge and the outer
                // edges (§7).
                MotifGroundView(seed: 0xC1A5_0F04,
                                exclusions: CountryLetterStyle.groundExclusions(in: geo, chrome: chrome))
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    HStack {
                        CountryLetterNavButton(title: "Main menu") {
                            dismiss()
                        }
                        Spacer()
                    }

                    // Header: spot plate + framed Lilita title (§3 recipe /
                    // §9 — no naked SF hero on a celebration screen).
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ZStack {
                            Circle().fill(AppTheme.Retro.panel)
                            Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                            RetroSpotIllustration(kind: .globe)
                                .frame(width: 64, height: 64)
                        }
                        .frame(width: 84, height: 84)

                        Text("Round Results")
                            .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                            .foregroundColor(AppTheme.Retro.ink)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .retroPanel(CountryLetterStyle.accent)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                                    .fill(AppTheme.Retro.ink)
                                    .offset(x: AppTheme.Retro.shadowOffset,
                                            y: AppTheme.Retro.shadowOffset)
                            )
                            .rotationEffect(.degrees(-1))

                        Text(resultsSummary)
                            .font(AppTheme.Typography.secondary)
                            .foregroundColor(AppTheme.Retro.panelText)
                            .multilineTextAlignment(.center)
                            .retroLozenge()
                            .rotationEffect(.degrees(0.8))
                    }

                    // Score display — big Lilita numeral on cream (§8: the
                    // count is body-adjacent reading, so it stays on a panel).
                    VStack(spacing: AppTheme.Spacing.sm) {
                        AnimatedScoreText(
                            targetScore: viewModel.foundCount,
                            color: AppTheme.Retro.panelText,
                            font: AppTheme.Retro.Typography.heading(52, relativeTo: .largeTitle)
                        )

                        Text("of \(viewModel.totalCountries) countries found")
                            .font(AppTheme.Typography.secondary)
                            .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .retroCard()

                    // Guessed countries
                    if !viewModel.guessedCountries.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            sectionHeader("Correct Guesses")

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: AppTheme.Spacing.md) {
                                ForEach(Array(viewModel.guessedCountries.enumerated()), id: \.element.id) { index, country in
                                    HStack(spacing: AppTheme.Spacing.sm) {
                                        CountryStatusBadge(systemImage: "checkmark",
                                                           color: CountryLetterStyle.correctColor)
                                        Text(country.name)
                                            .font(AppTheme.Retro.Typography.cardTitle)
                                            .foregroundColor(AppTheme.Retro.panelText)
                                        Spacer()
                                    }
                                    .retroCard()
                                    .staggeredAppear(index: index)
                                }
                            }
                        }
                    }

                    // Missed countries
                    let missedCountries = viewModel.remainingCountries
                    if !missedCountries.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            sectionHeader("Missed Countries")

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: AppTheme.Spacing.md) {
                                ForEach(Array(missedCountries.enumerated()), id: \.element.id) { index, country in
                                    HStack(spacing: AppTheme.Spacing.sm) {
                                        CountryStatusBadge(systemImage: "xmark",
                                                           color: CountryLetterStyle.missedColor)
                                        Text(country.name)
                                            .font(AppTheme.Retro.Typography.cardTitle)
                                            .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                                        Spacer()
                                    }
                                    .retroCard()
                                    .staggeredAppear(index: viewModel.guessedCountries.count + index)
                                }
                            }
                        }
                    }

                    // Give ups
                    if !viewModel.giveUpCountries.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            sectionHeader("Give Ups (Fully Revealed via Hints)")

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: AppTheme.Spacing.md) {
                                ForEach(Array(viewModel.giveUpCountries.enumerated()), id: \.element.id) { index, country in
                                    HStack(spacing: AppTheme.Spacing.sm) {
                                        CountryStatusBadge(systemImage: "hand.raised.fill",
                                                           color: CountryLetterStyle.giveUpColor)
                                        Text(country.name)
                                            .font(AppTheme.Retro.Typography.cardTitle)
                                            .foregroundColor(AppTheme.Retro.panelText)
                                        Spacer()
                                    }
                                    .retroCard()
                                    .staggeredAppear(index: viewModel.guessedCountries.count + missedCountries.count + index)
                                }
                            }
                        }
                    }

                    // Action buttons
                    VStack(spacing: AppTheme.Spacing.md) {
                        RetroPrimaryButton(title: "Play Again", icon: "arrow.counterclockwise",
                                           accent: CountryLetterStyle.accent) {
                            viewModel.resetGame()
                        }

                        // Cream panel + ink text is this language's secondary
                        // button; §3.2's one-accent rule keeps grass alone.
                        RetroPrimaryButton(title: "Back to Home", icon: "house",
                                           accent: AppTheme.Retro.panel) {
                            dismiss()
                        }
                    }
                    .padding(.top, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.xl)
                }
                .padding(AppTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
        }
    }

    /// Section labels sit on the ground, so they ride a cream lozenge rather
    /// than floating naked over the motif field (§9).
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
            .foregroundColor(AppTheme.Retro.panelText)
            .retroLozenge()
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var resultsSummary: String {
        let total = viewModel.totalCountries
        let found = viewModel.foundCount
        let missedCount = viewModel.remainingCountries.count

        if missedCount == 0 && viewModel.giveUpCountries.isEmpty && total > 0 {
            return "Perfect round — you got all \(total) countries starting with \(viewModel.selectedLetter ?? "")!"
        } else {
            var summary = "You found \(found) of \(total) countries starting with \(viewModel.selectedLetter ?? "")."
            if !viewModel.giveUpCountries.isEmpty {
                summary += " \(viewModel.giveUpCountries.count) gave up via hints."
            }
            if viewModel.hintCount > 0 {
                summary += " (\(viewModel.hintCount) hint\(viewModel.hintCount == 1 ? "" : "s") used)"
            }
            return summary
        }
    }
}
