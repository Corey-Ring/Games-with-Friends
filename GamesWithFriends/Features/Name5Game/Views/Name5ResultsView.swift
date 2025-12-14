import SwiftUI

struct Name5ResultsView: View {
    @ObservedObject var viewModel: Name5ViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success/Failure Animation
                if let result = viewModel.lastResult {
                    ResultHeader(success: result.success)
                        .padding(.top, 20)
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

// MARK: - Result Header
struct ResultHeader: View {
    let success: Bool

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(success ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(success ? .green : .orange)
            }

            Text(success ? "Nice Work!" : "So Close!")
                .font(.title)
                .fontWeight(.bold)

            Text(success ? "You got all 5!" : "Better luck next time")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Completed Prompt Card
struct CompletedPromptCard: View {
    let prompt: Name5Prompt
    let result: RoundResult?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(prompt.text)
                    .font(.headline)
                Spacer()
                Image(systemName: result?.success == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result?.success == true ? .green : .orange)
            }

            if let time = result?.timeUsed {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                    Text("Completed in \(time)s")
                        .font(.caption)
                    Spacer()
                }
                .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                Image(systemName: prompt.category.icon)
                    .font(.caption2)
                Text(prompt.category.rawValue)
                    .font(.caption)
                Spacer()
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Follow-up Question Card
struct FollowUpQuestionCard: View {
    let question: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.purple)
                Text("Conversation Starter")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)
            }

            Text(question)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    let stats: GameStats

    var body: some View {
        VStack(spacing: 16) {
            Text("Session Stats")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
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
                    .tint(.green)

                Text("\(Int(stats.successRate * 100))% success rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Continue Buttons
struct ContinueButtons: View {
    @ObservedObject var viewModel: Name5ViewModel

    var body: some View {
        VStack(spacing: 12) {
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
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.purple)
                    )
                }
            }

            // Random button
            Button(action: {
                viewModel.continueToNextRound()
            }) {
                HStack {
                    Image(systemName: "shuffle")
                    Text("Random Prompt")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }

            // End Game button
            Button(action: {
                viewModel.endGame()
            }) {
                Text("End Game")
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.gray.opacity(0.15))
                    )
            }
        }
    }
}
