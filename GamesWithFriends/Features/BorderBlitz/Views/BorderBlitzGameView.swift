//
//  BorderBlitzGameView.swift
//  BorderBlitz
//

import SwiftUI

struct BorderBlitzGameView: View {
    @Bindable var viewModel: BorderBlitzViewModel
    @FocusState private var isInputFocused: Bool

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
        .onAppear {
            isInputFocused = true
        }
    }

    private var playingView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Timer
                    HStack {
                        Spacer()
                        timerView
                    }
                    .padding(.horizontal)

                    // Country silhouette
                    if let country = viewModel.currentCountry {
                        BorderBlitzCountrySilhouetteView(
                            country: country,
                            size: CGSize(width: 250, height: 250)
                        )
                        .padding()
                    }

                    // Letter tiles
                    BorderBlitzLetterTilesView(tiles: viewModel.letterRevealManager.tiles)

                    // Score display
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Score: \(viewModel.totalScore)")
                                .font(.headline)
                                .accessibilityLabel("Score: \(viewModel.totalScore) points")
                            if viewModel.currentStreak > 1 {
                                Text("Streak: \(viewModel.currentStreak) 🔥")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                    .accessibilityLabel("Current streak: \(viewModel.currentStreak)")
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Input field
                    VStack(spacing: 10) {
                        TextField("Enter country name", text: $viewModel.currentGuess)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                            .focused($isInputFocused)
                            .onSubmit {
                                viewModel.submitGuess()
                            }

                        HStack {
                            Button("Submit") {
                                viewModel.submitGuess()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.currentGuess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            Button("Skip") {
                                viewModel.skipRound()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .id("inputField")
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        proxy.scrollTo("inputField", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var timerView: some View {
        HStack(spacing: 5) {
            Image(systemName: "clock.fill")
                .foregroundColor(timeColor)
            Text(timeString)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(timeColor)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(timeColor.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Int(viewModel.timeRemaining)) seconds remaining")
    }

    private var timeString: String {
        let seconds = Int(viewModel.timeRemaining)
        return String(format: "%02d", seconds)
    }

    private var timeColor: Color {
        if viewModel.timeRemaining <= 10 {
            return .red
        } else if viewModel.timeRemaining <= 20 {
            return .orange
        } else {
            return .green
        }
    }

    private var roundCompleteView: some View {
        VStack(spacing: 30) {
            if let result = viewModel.roundResults.last {
                // Result icon
                Image(systemName: result.guessedCorrectly ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(result.guessedCorrectly ? .green : .red)

                // Country name
                Text(result.countryName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                // Score breakdown
                if result.guessedCorrectly {
                    VStack(spacing: 15) {
                        if result.isPerfect {
                            Text("PERFECT! 🎉")
                                .font(.title)
                                .foregroundColor(.orange)
                        }

                        Text("+\(result.score) points")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.green)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Hidden letters: \(result.hiddenLettersCount)")
                            Text("• Time remaining: \(Int(result.timeRemaining))s")
                            if result.streak > 1 {
                                Text("• Streak bonus: \(result.streak)x 🔥")
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }

                // Total score
                Text("Total Score: \(viewModel.totalScore)")
                    .font(.title2)
                    .padding(.top)

                // Buttons
                HStack(spacing: 20) {
                    Button("Continue") {
                        viewModel.continueToNextRound()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Menu") {
                        viewModel.returnToMenu()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.top)
            }
        }
        .padding()
    }

    private var gameOverView: some View {
        VStack(spacing: 30) {
            Text("Game Complete!")
                .font(.system(size: 40, weight: .bold))

            Text("Final Score")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("\(viewModel.totalScore)")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.green)

            // Stats
            VStack(spacing: 10) {
                Text("Rounds Played: \(viewModel.roundResults.count)")
                Text("Correct: \(viewModel.roundResults.filter { $0.guessedCorrectly }.count)")
                Text("Best Streak: \(viewModel.roundResults.map { $0.streak }.max() ?? 0)")
            }
            .font(.headline)

            Button("Back to Menu") {
                viewModel.returnToMenu()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    private var feedbackOverlay: some View {
        VStack {
            Spacer()
            Text(viewModel.feedbackMessage)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.feedbackIsCorrect ? Color.green : Color.red)
                )
                .padding()
            Spacer()
        }
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(), value: viewModel.showFeedback)
    }
}
