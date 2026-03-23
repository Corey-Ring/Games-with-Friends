//
//  BorderBlitzGameView.swift
//  BorderBlitz
//

import SwiftUI

struct BorderBlitzGameView: View {
    @Bindable var viewModel: BorderBlitzViewModel
    @FocusState private var isInputFocused: Bool
    private let theme = GameTheme.borderBlitz

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
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Timer
                    HStack {
                        Spacer()
                        timerView
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)

                    // Country silhouette
                    if let country = viewModel.currentCountry {
                        BorderBlitzCountrySilhouetteView(
                            country: country,
                            size: CGSize(width: 250, height: 250)
                        )
                        .padding(AppTheme.Spacing.md)
                    }

                    // Letter tiles
                    BorderBlitzLetterTilesView(tiles: viewModel.letterRevealManager.tiles)

                    // Score display
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("Score: \(viewModel.totalScore)")
                                .font(AppTheme.Typography.cardTitle)
                                .foregroundColor(AppTheme.deepCharcoal)
                                .accessibilityLabel("Score: \(viewModel.totalScore) points")
                            if viewModel.currentStreak > 1 {
                                Text("Streak: \(viewModel.currentStreak) 🔥")
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(.orange)
                                    .accessibilityLabel("Current streak: \(viewModel.currentStreak)")
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)

                    // Input field
                    VStack(spacing: AppTheme.Spacing.sm) {
                        TextField("Enter country name", text: $viewModel.currentGuess)
                            .font(AppTheme.Typography.body)
                            .padding(AppTheme.Spacing.sm)
                            .background(AppTheme.pureWhite)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                    .stroke(theme.accentColor.opacity(0.3), lineWidth: 1)
                            )
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                            .focused($isInputFocused)
                            .onSubmit {
                                viewModel.submitGuess()
                            }

                        HStack(spacing: AppTheme.Spacing.md) {
                            PrimaryButton(title: "Submit") {
                                viewModel.submitGuess()
                            }
                            .disabled(viewModel.currentGuess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            SecondaryButton(title: "Skip") {
                                viewModel.skipRound()
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.md)
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
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "clock.fill")
                .foregroundColor(timeColor)
            Text(timeString)
                .font(AppTheme.Typography.sectionHeader)
                .foregroundColor(timeColor)
                .monospacedDigit()
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
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
        VStack(spacing: AppTheme.Spacing.lg) {
            if let result = viewModel.roundResults.last {
                // Result icon
                Image(systemName: result.guessedCorrectly ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(result.guessedCorrectly ? .green : .red)

                // Country name
                Text(result.countryName)
                    .font(AppTheme.Typography.hero)

                // Score breakdown
                if result.guessedCorrectly {
                    VStack(spacing: AppTheme.Spacing.md) {
                        if result.isPerfect {
                            Text("PERFECT! 🎉")
                                .font(AppTheme.Typography.sectionHeader)
                                .foregroundColor(.orange)
                        }

                        Text("+\(result.score) points")
                            .font(AppTheme.Typography.hero)
                            .foregroundColor(theme.accentColor)

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("• Hidden letters: \(result.hiddenLettersCount)")
                            Text("• Time remaining: \(Int(result.timeRemaining))s")
                            if result.streak > 1 {
                                Text("• Streak bonus: \(result.streak)x 🔥")
                            }
                        }
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.mediumGray)
                    }
                    .gameCard()
                }

                // Total score
                Text("Total Score: \(viewModel.totalScore)")
                    .font(AppTheme.Typography.sectionHeader)
                    .padding(.top, AppTheme.Spacing.sm)

                // Buttons
                HStack(spacing: AppTheme.Spacing.md) {
                    PrimaryButton(title: "Continue") {
                        viewModel.continueToNextRound()
                    }

                    SecondaryButton(title: "Menu") {
                        viewModel.returnToMenu()
                    }
                }
                .padding(.top, AppTheme.Spacing.sm)
            }
        }
        .padding(AppTheme.Spacing.md)
    }

    private var gameOverView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Game Complete!")
                .font(AppTheme.Typography.hero)
                .foregroundColor(AppTheme.deepCharcoal)

            Text("Final Score")
                .font(AppTheme.Typography.sectionHeader)
                .foregroundColor(AppTheme.mediumGray)

            Text("\(viewModel.totalScore)")
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundColor(theme.accentColor)

            // Stats
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Rounds Played: \(viewModel.roundResults.count)")
                Text("Correct: \(viewModel.roundResults.filter { $0.guessedCorrectly }.count)")
                Text("Best Streak: \(viewModel.roundResults.map { $0.streak }.max() ?? 0)")
            }
            .font(AppTheme.Typography.cardTitle)
            .foregroundColor(AppTheme.deepCharcoal)
            .gameCard()

            PrimaryButton(title: "Back to Menu") {
                viewModel.returnToMenu()
            }
        }
        .padding(AppTheme.Spacing.md)
    }

    private var feedbackOverlay: some View {
        VStack {
            Spacer()
            Text(viewModel.feedbackMessage)
                .font(AppTheme.Typography.sectionHeader)
                .foregroundColor(.white)
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .fill(viewModel.feedbackIsCorrect ? AppTheme.success : AppTheme.error)
                )
                .padding(AppTheme.Spacing.md)
            Spacer()
        }
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(), value: viewModel.showFeedback)
    }
}
