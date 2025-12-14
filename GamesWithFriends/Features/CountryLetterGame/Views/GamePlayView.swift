import SwiftUI

struct GamePlayView: View {
    @ObservedObject var viewModel: CountryGameViewModel

    var body: some View {
        VStack(spacing: 20) {
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
                    .foregroundColor(.secondary)
                }

                Spacer()

                if let letter = viewModel.selectedLetter {
                    Text(letter)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.12))
                        )
                }
            }
            .padding(.horizontal)
            .padding(.top)

            // Stats cards
            HStack(spacing: 16) {
                StatCard(title: "Progress", value: "\(viewModel.foundCount)/\(viewModel.totalCountries)")
                StatCard(title: "Remaining", value: "\(viewModel.remainingCount)")
            }
            .padding(.horizontal)

            // Guess input form
            VStack(alignment: .leading, spacing: 12) {
                Text("Country Guess")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    TextField("Start typing here...", text: $viewModel.currentGuess)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
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
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue)
                            )
                    }
                }
            }
            .padding(.horizontal)

            // Feedback message
            HStack(spacing: 8) {
                if !viewModel.feedbackMessage.isEmpty {
                    Image(systemName: feedbackIcon)
                        .foregroundColor(feedbackColor)
                    Text(viewModel.feedbackMessage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(feedbackColor)
                }
            }
            .frame(minHeight: 30)
            .padding(.horizontal)

            // Guessed countries list
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 12) {
                    ForEach(viewModel.guessedCountries) { country in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 18))

                            Text(country.name)
                                .font(.system(size: 16, weight: .semibold))

                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                }
                .padding(.horizontal)
            }

            // Action buttons
            HStack(spacing: 16) {
                Button(action: {
                    viewModel.showHint()
                }) {
                    Text("💡 Hint")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.15))
                        )
                }

                Button(action: {
                    viewModel.finishGame()
                }) {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.15))
                        )
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
        case .info: return .secondary
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 24, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )
        )
    }
}
