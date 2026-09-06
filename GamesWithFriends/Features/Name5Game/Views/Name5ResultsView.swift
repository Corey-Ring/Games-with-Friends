import SwiftUI

struct Name5ResultsView: View {
    var viewModel: Name5ViewModel

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Scrolling result column runs the full width; motifs keep to
                // the nav strip and the outer edges (§7).
                MotifGroundView(seed: 0x4A5E_0F07,
                                exclusions: [CGRect(x: 8, y: 56,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 56)])
            }
            .ignoresSafeArea()

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
        VStack(spacing: AppTheme.Spacing.sm) {
            // §9: no naked SF hero — the round verdict gets the game's spot
            // plate and a framed Lilita banner.
            ZStack {
                Circle().fill(AppTheme.Retro.panel)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                RetroSpotIllustration(kind: .bubbleFive)
                    .frame(width: 64, height: 64)
                    .opacity(success ? 1 : 0.6)
            }
            .frame(width: 84, height: 84)

            // Celebration accent is grass (cream display text ≥17pt is OK
            // there, §8); the near-miss banner uses tangerine, where ink is
            // the passing color.
            Text(success ? "Nice Work!" : "So Close!")
                .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                .foregroundColor(success ? AppTheme.Retro.cream : AppTheme.Retro.ink)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .retroPanel(success ? Name5Style.successColor : Name5Style.missColor)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                        .fill(AppTheme.Retro.ink)
                        .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
                )
                .rotationEffect(.degrees(-1))

            Text(success ? "You got all 5!" : "Better luck next time")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Retro.panelText)
                .retroLozenge()
                .rotationEffect(.degrees(0.8))
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
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText)
                Spacer()
                Name5StatusBadge(systemImage: result?.success == true ? "checkmark" : "xmark",
                                 color: result?.success == true ? Name5Style.successColor : Name5Style.missColor)
            }

            if let time = result?.timeUsed {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(AppTheme.Typography.caption)
                    Text("Completed in \(time)s")
                        .font(AppTheme.Typography.caption)
                    Spacer()
                }
                .foregroundColor(AppTheme.Retro.cocoa)
            }

            HStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: prompt.category.icon)
                        .font(AppTheme.Typography.tabLabel)
                    Text(prompt.category.rawValue)
                        .font(AppTheme.Retro.Typography.pillLabel)
                }
                .foregroundColor(Name5Style.chipTextColor(on: Name5Style.accent))
                .padding(.horizontal, AppTheme.Spacing.sm + 2)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(Capsule().fill(Name5Style.accent))
                .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))

                Name5DifficultyChip(difficulty: prompt.difficulty)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
    }
}

// MARK: - Follow-up Question Card
struct FollowUpQuestionCard: View {
    let question: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // §9: the 10%-tint panel + hairline accent stroke are retired —
            // the accent now rides on an ink-outlined chip and the copy stays
            // ink-on-cream (§8).
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(AppTheme.Typography.caption)
                Text("Conversation Starter")
                    .font(AppTheme.Retro.Typography.pillLabel)
            }
            .foregroundColor(Name5Style.chipTextColor(on: Name5Style.accent))
            .padding(.horizontal, AppTheme.Spacing.sm + 2)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(Capsule().fill(Name5Style.accent))
            .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))

            Text(question)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Retro.panelText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    let stats: GameStats

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Session Stats")
                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: AppTheme.Spacing.sm) {
                StatItem(
                    icon: "target",
                    label: "Rounds",
                    value: "\(stats.roundsPlayed)"
                )

                StatItem(
                    icon: "checkmark",
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
                // Keep the system control, tint it with the game accent (§3).
                ProgressView(value: stats.successRate)
                    .tint(Name5Style.accent)

                Text("\(Int(stats.successRate * 100))% success rate")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Retro.cocoa)
            }
        }
        .retroCard()
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Name5StatusBadge(systemImage: icon, color: Name5Style.accent, diameter: 28)

            Text(value)
                .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title2))
                .foregroundColor(AppTheme.Retro.panelText)

            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.cocoa)
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .frame(maxWidth: .infinity)
        .retroPanel(AppTheme.Retro.panel, cornerRadius: AppTheme.Retro.Radius.inner)
    }
}

// MARK: - Continue Buttons
struct ContinueButtons: View {
    var viewModel: Name5ViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Random button
            RetroPrimaryButton(title: "Random Prompt", icon: "shuffle",
                               accent: Name5Style.accent) {
                viewModel.continueToNextRound()
            }

            // Same Category button — tangerine is the utility action beside
            // the lilac primary (§3.2's one-accent rule keeps lilac alone).
            if let category = viewModel.currentPrompt?.category {
                RetroPrimaryButton(title: "More \(category.rawValue)", icon: category.icon,
                                   accent: AppTheme.Retro.tangerine) {
                    viewModel.playAgainSameCategory()
                }
            }

            // End Game button
            RetroPrimaryButton(title: "End Game", icon: "stop.fill",
                               accent: AppTheme.Retro.panel) {
                viewModel.endGame()
            }
        }
    }
}
