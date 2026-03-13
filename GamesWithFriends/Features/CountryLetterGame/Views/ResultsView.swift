import SwiftUI

struct ResultsView: View {
    var viewModel: CountryGameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Round Results")
                        .font(AppTheme.Typography.hero)
                        .foregroundColor(AppTheme.deepCharcoal)

                    Text(resultsSummary)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.mediumGray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, AppTheme.Spacing.lg)

                // Score display
                VStack(spacing: AppTheme.Spacing.sm) {
                    AnimatedScoreText(
                        targetScore: viewModel.foundCount,
                        color: GameTheme.countryLetter.accentColor
                    )

                    Text("of \(viewModel.totalCountries) countries found")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.mediumGray)
                }
                .frame(maxWidth: .infinity)
                .gameCard()

                // Guessed countries
                if !viewModel.guessedCountries.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Correct Guesses")
                            .font(AppTheme.Typography.sectionHeader)
                            .foregroundColor(AppTheme.deepCharcoal)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: AppTheme.Spacing.md) {
                            ForEach(Array(viewModel.guessedCountries.enumerated()), id: \.element.id) { index, country in
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(GameTheme.countryLetter.accentColor)
                                    Text(country.name)
                                        .font(AppTheme.Typography.cardTitle)
                                    Spacer()
                                }
                                .gameCard()
                                .staggeredAppear(index: index)
                            }
                        }
                    }
                }

                // Missed countries
                let missedCountries = viewModel.remainingCountries
                if !missedCountries.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Missed Countries")
                            .font(AppTheme.Typography.sectionHeader)
                            .foregroundColor(AppTheme.deepCharcoal)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: AppTheme.Spacing.md) {
                            ForEach(Array(missedCountries.enumerated()), id: \.element.id) { index, country in
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(AppTheme.mediumGray)
                                    Text(country.name)
                                        .font(AppTheme.Typography.cardTitle)
                                        .foregroundColor(AppTheme.mediumGray)
                                    Spacer()
                                }
                                .gameCard()
                                .staggeredAppear(index: viewModel.guessedCountries.count + index)
                            }
                        }
                    }
                }

                // Give ups
                if !viewModel.giveUpCountries.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Give Ups (Fully Revealed via Hints)")
                            .font(AppTheme.Typography.sectionHeader)
                            .foregroundColor(AppTheme.deepCharcoal)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: AppTheme.Spacing.md) {
                            ForEach(Array(viewModel.giveUpCountries.enumerated()), id: \.element.id) { index, country in
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    Image(systemName: "hand.raised")
                                        .foregroundColor(.orange)
                                    Text(country.name)
                                        .font(AppTheme.Typography.cardTitle)
                                        .foregroundColor(.orange)
                                    Spacer()
                                }
                                .gameCard()
                                .staggeredAppear(index: viewModel.guessedCountries.count + missedCountries.count + index)
                            }
                        }
                    }
                }

                // Action buttons
                VStack(spacing: AppTheme.Spacing.md) {
                    PrimaryButton(title: "Play Again", icon: "arrow.counterclockwise") {
                        viewModel.resetGame()
                    }

                    SecondaryButton(title: "Back to Home", icon: "house") {
                        dismiss()
                    }
                }
                .padding(.top, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
            .padding(AppTheme.Spacing.md)
        }
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
