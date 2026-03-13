import SwiftUI

struct GamePlayView: View {
    @Bindable var viewModel: CountryGameViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Header with letter and change button
            HStack {
                Button(action: {
                    viewModel.changeLetterFromGame()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Pick another letter")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.mediumGray)
                }

                Spacer()

                if let letter = viewModel.selectedLetter {
                    Text(letter)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(GameTheme.countryLetter.accentColor)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(GameTheme.countryLetter.mediumBackground)
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
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(AppTheme.mediumGray)

                HStack(spacing: AppTheme.Spacing.md) {
                    TextField("Start typing here...", text: $viewModel.currentGuess)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                .stroke(AppTheme.mediumGray.opacity(0.3), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                        .fill(Color(.systemBackground))
                                )
                        )
                        .onSubmit {
                            viewModel.submitGuess()
                        }
                        .autocapitalization(.words)
                        .disableAutocorrection(true)

                    Button(action: {
                        viewModel.submitGuess()
                    }) {
                        Text("Submit")
                            .font(AppTheme.Typography.buttonLabel)
                            .foregroundColor(.white)
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                    .fill(GameTheme.countryLetter.accentColor)
                            )
                    }
                    .pressable()
                }
            }
            .padding(.horizontal)

            // Feedback message
            HStack(spacing: AppTheme.Spacing.sm) {
                if !viewModel.feedbackMessage.isEmpty {
                    Image(systemName: feedbackIcon)
                        .foregroundColor(feedbackColor)
                    Text(viewModel.feedbackMessage)
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(feedbackColor)
                }
            }
            .frame(minHeight: 30)
            .padding(.horizontal)

            // Guessed countries list
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: AppTheme.Spacing.md) {
                    ForEach(Array(viewModel.guessedCountries.enumerated()), id: \.element.id) { index, country in
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(GameTheme.countryLetter.accentColor)
                                .font(.system(size: 18))

                            Text(country.name)
                                .font(AppTheme.Typography.cardTitle)

                            Spacer()
                        }
                        .gameCard()
                        .staggeredAppear(index: index)
                    }
                }
                .padding(.horizontal)
            }

            // Action buttons
            HStack(spacing: AppTheme.Spacing.md) {
                SecondaryButton(title: "Hint", icon: "lightbulb.fill") {
                    viewModel.showHint()
                }

                SecondaryButton(title: "Done", icon: "checkmark") {
                    viewModel.finishGame()
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
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
        case .success: return .green
        case .error: return .red
        case .info: return AppTheme.mediumGray
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
                .foregroundColor(AppTheme.mediumGray)

            Text(value)
                .font(AppTheme.Typography.sectionHeader)
                .foregroundColor(AppTheme.deepCharcoal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gameCard()
    }
}
