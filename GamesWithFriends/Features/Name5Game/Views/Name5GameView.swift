import SwiftUI

struct Name5GameView: View {
    @State private var viewModel = Name5ViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                WarmLinenBackground()

                // Content based on game phase
                switch viewModel.gamePhase {
                case .setup:
                    Name5SetupView(viewModel: viewModel)

                case .ready, .playing, .paused:
                    Name5PlayView(viewModel: viewModel)

                case .roundComplete:
                    Name5ResultsView(viewModel: viewModel)

                case .gameOver:
                    GameOverView(viewModel: viewModel)
                }
            }
            .navigationTitle(viewModel.gamePhase == .setup ? "" : "Name 5")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(viewModel.gamePhase == .setup ? .hidden : .automatic, for: .navigationBar)
            .toolbar {
                if viewModel.gamePhase != .setup {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive, action: {
                                viewModel.resetGame()
                            }) {
                                Label("New Game", systemImage: "arrow.counterclockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                        }
                    }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .inactive, .background:
                    if viewModel.gamePhase == .playing {
                        viewModel.pauseTimer()
                    }
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Game Over View
struct GameOverView: View {
    var viewModel: Name5ViewModel

    var body: some View {
        ZStack {
            GameBackground(gameTheme: .name5)
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 60))
                            .foregroundStyle(GameTheme.name5.accentColor)

                        Text("Game Over!")
                            .font(AppTheme.Typography.hero)
                            .fontWeight(.bold)

                        Text("Great job playing!")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.mediumGray)
                    }
                    .padding(.top, 40)

                    // Final Stats
                    FinalStatsCard(stats: viewModel.stats)

                    // Recent Rounds
                    if !viewModel.roundResults.isEmpty {
                        RecentRoundsCard(results: viewModel.roundResults)
                    }

                    // Buttons
                    VStack(spacing: AppTheme.Spacing.md) {
                        PrimaryButton(title: "Play Again", icon: "play.fill") {
                            viewModel.startGame()
                        }

                        SecondaryButton(title: "Back to Setup", icon: "gearshape") {
                            viewModel.resetGame()
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
    }
}

// MARK: - Final Stats Card
struct FinalStatsCard: View {
    let stats: GameStats

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Final Stats")
                .font(AppTheme.Typography.sectionHeader)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
                FinalStatItem(
                    icon: "target",
                    label: "Total Rounds",
                    value: "\(stats.roundsPlayed)",
                    color: GameTheme.name5.accentColor
                )

                FinalStatItem(
                    icon: "checkmark.circle.fill",
                    label: "Successful",
                    value: "\(stats.roundsWon)",
                    color: .green
                )

                FinalStatItem(
                    icon: "flame.fill",
                    label: "Best Streak",
                    value: "\(stats.bestStreak)",
                    color: .orange
                )

                FinalStatItem(
                    icon: "percent",
                    label: "Success Rate",
                    value: "\(Int(stats.successRate * 100))%",
                    color: GameTheme.name5.accentColor
                )
            }
        }
        .gameCard()
    }
}

struct FinalStatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.mediumGray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Recent Rounds Card
struct RecentRoundsCard: View {
    let results: [RoundResult]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Recent Rounds")
                .font(AppTheme.Typography.cardTitle)

            ForEach(results.suffix(5).reversed()) { result in
                HStack {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.success ? .green : .orange)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.promptText)
                            .font(AppTheme.Typography.body)
                            .lineLimit(1)

                        if let time = result.timeUsed {
                            Text("\(time)s")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.mediumGray)
                        }
                    }

                    Spacer()

                    if let playerNum = result.playerNumber {
                        Text("P\(playerNum)")
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.mediumGray)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(AppTheme.mediumGray.opacity(0.15))
                            )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .fill(AppTheme.mediumGray.opacity(0.05))
                )
            }
        }
        .gameCard()
    }
}
