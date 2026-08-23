import SwiftUI

struct GamePlayView: View {
    @Bindable var viewModel: CountryGameViewModel

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Everything below the nav strip is interactive (input field,
                // stat cards, the guessed list, the action row), so motifs
                // keep to the top band and the outer edges (§7).
                MotifGroundView(seed: 0xC1A5_0F03,
                                exclusions: [CGRect(x: 8, y: 56,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 56)])
            }
            .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                // Header with letter and change button
                HStack {
                    Button(action: {
                        viewModel.changeLetterFromGame()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(AppTheme.Typography.caption)
                            Text("Pick another letter")
                                .font(AppTheme.Retro.Typography.pillLabel)
                        }
                        .foregroundColor(AppTheme.Retro.panelText)
                        .retroLozenge()
                    }
                    .buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))

                    Spacer()

                    if let letter = viewModel.selectedLetter {
                        // The round's letter is the screen's loudest object:
                        // chunky Lilita, ink on grass, hard-shadowed (§4/§5).
                        Text(letter)
                            .font(AppTheme.Retro.Typography.heading(26, relativeTo: .title2))
                            .foregroundColor(AppTheme.Retro.ink)
                            .frame(minWidth: 30)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .retroLozenge(CountryLetterStyle.accent)
                            .background(
                                Capsule()
                                    .fill(AppTheme.Retro.ink)
                                    .offset(x: AppTheme.Retro.shadowOffset,
                                            y: AppTheme.Retro.shadowOffset)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Stats cards
                HStack(spacing: AppTheme.Spacing.md) {
                    StatCard(title: "Progress", value: "\(viewModel.foundCount)/\(viewModel.totalCountries)")
                    StatCard(title: "Remaining", value: "\(viewModel.remainingCount)")
                }
                .padding(.horizontal)

                // Guess input form
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("Country Guess")
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .foregroundColor(AppTheme.Retro.panelText)

                    HStack(spacing: AppTheme.Spacing.sm) {
                        TextField("Start typing here...", text: $viewModel.currentGuess)
                            .textFieldStyle(.plain)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Retro.panelText)
                            .padding(AppTheme.Spacing.sm + 2)
                            .retroPanel(AppTheme.Retro.panel,
                                        cornerRadius: AppTheme.Retro.Radius.inner)
                            .onSubmit {
                                viewModel.submitGuess()
                            }
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)

                        Button(action: {
                            viewModel.submitGuess()
                        }) {
                            Text("Submit")
                                .font(AppTheme.Retro.Typography.heading(17))
                                .foregroundColor(AppTheme.Retro.ink)
                                .padding(.horizontal, AppTheme.Spacing.md)
                                .padding(.vertical, AppTheme.Spacing.sm + 4)
                                .retroPanel(CountryLetterStyle.accent,
                                            cornerRadius: AppTheme.Retro.Radius.inner)
                        }
                        .buttonStyle(RetroRaisedButtonStyle(cornerRadius: AppTheme.Retro.Radius.inner))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .retroCard()
                .padding(.horizontal)

                // Feedback message — §8: the copy stays ink-on-cream and the
                // semantic color rides on the ink-outlined status badge.
                HStack(spacing: AppTheme.Spacing.sm) {
                    if !viewModel.feedbackMessage.isEmpty {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            CountryStatusBadge(systemImage: feedbackIcon, color: feedbackColor)

                            Text(viewModel.feedbackMessage)
                                .font(AppTheme.Typography.secondary)
                                .foregroundColor(AppTheme.Retro.panelText)
                        }
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .retroLozenge()
                    }
                }
                .frame(minHeight: 30)
                .padding(.horizontal)

                // Guessed countries list
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: AppTheme.Spacing.md) {
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
                    .padding(.horizontal)
                    .padding(.bottom, AppTheme.Spacing.sm)
                }
                .scrollIndicators(.hidden)

                // Action buttons
                HStack(spacing: AppTheme.Spacing.md) {
                    // Tangerine reads as the utility action next to the grass
                    // primary — same split the pilot uses for "Pass" (§3.2's
                    // one-accent rule governs the screen's identity color).
                    RetroPrimaryButton(title: "Hint", icon: "lightbulb.fill",
                                       accent: AppTheme.Retro.tangerine) {
                        viewModel.showHint()
                    }

                    RetroPrimaryButton(title: "Done", icon: "checkmark",
                                       accent: CountryLetterStyle.accent) {
                        viewModel.finishGame()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }

    private var feedbackIcon: String {
        switch viewModel.feedbackType {
        case .success: return "checkmark"
        case .error: return "xmark"
        case .info: return "info.circle"
        }
    }

    private var feedbackColor: Color {
        switch viewModel.feedbackType {
        case .success: return CountryLetterStyle.successColor
        case .error: return CountryLetterStyle.errorColor
        case .info: return CountryLetterStyle.infoColor
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))

            Text(value)
                .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                .foregroundColor(AppTheme.Retro.panelText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
    }
}
