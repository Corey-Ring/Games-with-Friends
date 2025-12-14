import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: CountryGameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Round Results")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(resultsSummary)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Guessed countries
                if !viewModel.guessedCountries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Correct Guesses ✓")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 12) {
                            ForEach(viewModel.guessedCountries) { country in
                                Text(country.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.green.opacity(0.1))
                                    )
                            }
                        }
                    }
                }

                // Missed countries
                let missedCountries = viewModel.remainingCountries
                if !missedCountries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Missed Countries")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 12) {
                            ForEach(missedCountries) { country in
                                Text(country.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.gray.opacity(0.1))
                                    )
                            }
                        }
                    }
                }

                // Give ups
                if !viewModel.giveUpCountries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Give Ups (Fully Revealed via Hints)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 12) {
                            ForEach(viewModel.giveUpCountries) { country in
                                Text(country.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.orange.opacity(0.1))
                                    )
                            }
                        }
                    }
                }

                // Play again button
                Button(action: {
                    viewModel.resetGame()
                }) {
                    Text("Play Again")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
            .padding()
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
