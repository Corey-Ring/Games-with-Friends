import SwiftUI

/// Final results screen after all rounds are complete
struct CastingDirectorGameOverView: View {
    @ObservedObject var viewModel: CastingDirectorViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [GameTheme.castingDirector.accentColor.opacity(0.3), GameTheme.castingDirector.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Trophy header
                    trophyHeader

                    // Standings or solo score
                    if viewModel.gameMode == .passAndPlay {
                        standingsSection
                    } else {
                        soloScoreSection
                    }

                    // Stats
                    statsSection

                    // Actions
                    actionButtons
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden()
    }

    // MARK: - Trophy Header

    private var trophyHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 70))
                .foregroundStyle(.yellow)

            Text("Game Over!")
                .font(AppTheme.Typography.hero)
                .fontWeight(.bold)

            if viewModel.gameMode == .passAndPlay, let winner = viewModel.winner {
                HStack(spacing: 6) {
                    Circle()
                        .fill(winner.color)
                        .frame(width: 14, height: 14)
                    Text("\(winner.name) wins!")
                        .font(AppTheme.Typography.sectionHeader)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(.top)
    }

    // MARK: - Standings

    private var standingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Final Standings")
                .font(AppTheme.Typography.cardTitle)

            ForEach(Array(viewModel.standings.enumerated()), id: \.element.id) { index, player in
                HStack(spacing: 12) {
                    // Rank
                    Text("#\(index + 1)")
                        .font(AppTheme.Typography.subsectionHeader.weight(.bold))
                        .foregroundStyle(index == 0 ? AppTheme.medalGold : .secondary)
                        .frame(width: 40)

                    Circle()
                        .fill(player.color)
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.name)
                            .font(AppTheme.Typography.cardTitle)
                        Text("\(player.correctGuesses) correct, \(player.wrongGuesses) wrong")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(player.score)")
                        .font(AppTheme.Typography.subsectionHeader.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(GameTheme.castingDirector.accentColor)
                }
                .padding()
                .background(index == 0 ? AppTheme.medalGold.opacity(0.1) : Color.clear)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
            }
        }
    }

    // MARK: - Solo Score

    private var soloScoreSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            let player = viewModel.players.first ?? CastingDirectorPlayer(name: "Player")

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Total Score")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(.secondary)
                Text("\(player.score)")
                    .font(.system(size: 48))
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(GameTheme.castingDirector.accentColor)
            }

            HStack(spacing: AppTheme.Spacing.lg) {
                StatBubble(label: "Correct", value: "\(player.correctGuesses)", icon: "checkmark.circle.fill", color: AppTheme.success)
                StatBubble(label: "Wrong", value: "\(player.wrongGuesses)", icon: "xmark.circle.fill", color: AppTheme.error)
                StatBubble(label: "Streak", value: "\(viewModel.bestStreak)", icon: "flame.fill", color: .orange)
            }

            // High score comparison
            if player.score >= viewModel.highScore && player.score > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("New High Score!")
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundStyle(.yellow)
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
                .padding(.top, AppTheme.Spacing.xs)
            } else if viewModel.highScore > 0 {
                Text("High Score: \(viewModel.highScore)")
                    .font(AppTheme.Typography.secondary)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Stats")
                .font(AppTheme.Typography.cardTitle)

            HStack(spacing: 12) {
                CastingDirectorStatCard(label: "Rounds", value: "\(viewModel.numberOfRounds)", icon: "number.circle.fill")
                CastingDirectorStatCard(label: "Difficulty", value: viewModel.difficulty.rawValue, icon: "slider.horizontal.3")
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.playAgain()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                    Text("Play Again")
                }
                .font(AppTheme.Typography.subsectionHeader)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(GameTheme.castingDirector.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button {
                viewModel.returnToSetup()
            } label: {
                Text("Back to Setup")
                    .font(AppTheme.Typography.secondary)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top)
    }
}

// MARK: - Stat Bubble

struct StatBubble: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(AppTheme.Typography.subsectionHeader)
                .foregroundStyle(color)
            Text(value)
                .font(AppTheme.Typography.sectionHeader)
                .fontWeight(.bold)
                .monospacedDigit()
            Text(label)
                .font(AppTheme.Typography.tabLabel)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Stat Card

struct CastingDirectorStatCard: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(AppTheme.Typography.subsectionHeader)
                .foregroundStyle(GameTheme.castingDirector.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(AppTheme.Typography.cardTitle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
    }
}
