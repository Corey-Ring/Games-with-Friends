import SwiftUI

struct Name5ResultsView: View {
    var viewModel: Name5ViewModel

    var body: some View {
        ZStack {
            GameBackground(gameTheme: .name5)
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Success/Failure Animation
                    if let result = viewModel.lastResult {
                        ResultHeader(success: result.success)
                            .padding(.top, AppTheme.Spacing.lg)
                    }

                    // Prompt that was just completed
                    if let prompt = viewModel.currentPrompt {
                        CompletedPromptCard(prompt: prompt, result: viewModel.lastResult)
                    }

                    // Follow-up Question
                    if viewModel.showFollowUpQuestion, let question = viewModel.currentPrompt?.followUpQuestion {
                        FollowUpQuestionCard(question: question)
                    }

                    // Stats Summary
                    StatsCard(stats: viewModel.stats)

                    // Continue Buttons
                    ContinueButtons(viewModel: viewModel)

                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
    }
}

// MARK: - Result Header
struct ResultHeader: View {
    let success: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(success ? AppTheme.success.opacity(0.2) : AppTheme.warning.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(success ? AppTheme.success : AppTheme.warning)
            }

            Text(success ? "Nice Work!" : "So Close!")
                .font(AppTheme.Typography.hero)
                .fontWeight(.bold)

            Text(success ? "You got all 5!" : "Better luck next time")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.mediumGray)
        }
    }
}

// MARK: - Completed Prompt Card
struct CompletedPromptCard: View {
    let prompt: Name5Prompt
    let result: RoundResult?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text(prompt.text)
                    .font(AppTheme.Typography.cardTitle)
                Spacer()
                Image(systemName: result?.success == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result?.success == true ? .green : .orange)
            }

            if let time = result?.timeUsed {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(AppTheme.Typography.caption)
                    Text("Completed in \(time)s")
                        .font(AppTheme.Typography.caption)
                    Spacer()
                }
                .foregroundColor(AppTheme.mediumGray)
            }

            HStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: prompt.category.icon)
                        .font(AppTheme.Typography.tabLabel)
                    Text(prompt.category.rawValue)
                        .font(AppTheme.Typography.caption)
                }
                .foregroundColor(AppTheme.mediumGray)

                HStack(spacing: 2) {
                    ForEach(0..<difficultyStars(prompt.difficulty), id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(AppTheme.Typography.tabLabel)
                            .foregroundColor(difficultyColor(prompt.difficulty))
                    }
                    Text(prompt.difficulty.rawValue)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(difficultyColor(prompt.difficulty))
                }

                Spacer()
            }
        }
        .gameCard()
    }

    private func difficultyStars(_ difficulty: Difficulty) -> Int {
        switch difficulty {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }

    private func difficultyColor(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - Follow-up Question Card
struct FollowUpQuestionCard: View {
    let question: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(GameTheme.name5.accentColor)
                Text("Conversation Starter")
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(GameTheme.name5.accentColor)
            }

            Text(question)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.deepCharcoal)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(GameTheme.name5.accentColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .stroke(GameTheme.name5.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    let stats: GameStats

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Session Stats")
                .font(AppTheme.Typography.sectionHeader)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: AppTheme.Spacing.md) {
                StatItem(
                    icon: "target",
                    label: "Rounds",
                    value: "\(stats.roundsPlayed)"
                )

                StatItem(
                    icon: "checkmark.circle.fill",
                    label: "Success",
                    value: "\(stats.roundsWon)"
                )

                StatItem(
                    icon: "flame.fill",
                    label: "Streak",
                    value: "\(stats.currentStreak)"
                )

                StatItem(
                    icon: "chart.bar.fill",
                    label: "Best",
                    value: "\(stats.bestStreak)"
                )
            }

            if stats.roundsPlayed > 0 {
                ProgressView(value: stats.successRate)
                    .tint(GameTheme.name5.accentColor)

                Text("\(Int(stats.successRate * 100))% success rate")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.mediumGray)
            }
        }
        .gameCard()
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(AppTheme.Typography.subsectionHeader)
                .foregroundColor(GameTheme.name5.accentColor)

            Text(value)
                .font(AppTheme.Typography.sectionHeader)
                .fontWeight(.bold)

            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.mediumGray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Continue Buttons
struct ContinueButtons: View {
    var viewModel: Name5ViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Random button
            PrimaryButton(title: "Random Prompt", icon: "shuffle") {
                viewModel.continueToNextRound()
            }

            // Same Category button
            if let category = viewModel.currentPrompt?.category {
                Button(action: {
                    viewModel.playAgainSameCategory()
                }) {
                    HStack {
                        Image(systemName: category.icon)
                        Text("More \(category.rawValue)")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(GameTheme.name5.accentColor)
                    )
                }
                .pressable()
            }

            // End Game button
            SecondaryButton(title: "End Game", icon: "stop.fill") {
                viewModel.endGame()
            }
        }
    }
}
