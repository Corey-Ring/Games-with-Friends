import SwiftUI

/// View shown when the Movie Chain game ends
struct MovieChainGameOverView: View {
    @ObservedObject var viewModel: MovieChainViewModel
    let winner: MovieChainPlayer?

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Trophy/Winner section
                winnerSection

                // Final standings
                standingsSection

                // Game stats
                gameStatsSection

                // Action buttons
                actionButtons
            }
            .padding(AppTheme.Spacing.md)
        }
    }

    // MARK: - Winner Section

    private var winnerSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Trophy icon
            ZStack {
                Circle()
                    .fill(AppTheme.medalGold.opacity(0.3))
                    .frame(width: 120, height: 120)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppTheme.medalGold)
            }

            if let winner = winner {
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Winner!")
                        .font(AppTheme.Typography.sectionHeader)
                        .foregroundColor(AppTheme.mediumGray)

                    HStack(spacing: AppTheme.Spacing.md) {
                        Circle()
                            .fill(winner.color)
                            .frame(width: 24, height: 24)

                        Text(winner.name)
                            .font(AppTheme.Typography.hero)
                            .foregroundColor(AppTheme.deepCharcoal)
                    }
                }
            } else {
                Text("Game Over!")
                    .font(AppTheme.Typography.hero)
                    .foregroundColor(AppTheme.deepCharcoal)
            }
        }
        .padding(.top, AppTheme.Spacing.lg)
    }

    // MARK: - Standings Section

    private var standingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Final Standings")
                .font(AppTheme.Typography.sectionHeader)
                .foregroundColor(AppTheme.deepCharcoal)

            ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { index, player in
                PlayerStandingRow(
                    rank: index + 1,
                    player: player,
                    gameMode: viewModel.gameMode,
                    isWinner: player.id == winner?.id
                )
                .staggeredAppear(index: index)
            }
        }
        .gameCard()
    }

    private var sortedPlayers: [MovieChainPlayer] {
        switch viewModel.gameMode {
        case .classic:
            return viewModel.players.sorted {
                if $0.lives != $1.lives {
                    return $0.lives > $1.lives
                }
                return $0.linksContributed > $1.linksContributed
            }
        case .timed:
            return viewModel.players.sorted { $0.score > $1.score }
        case .endless:
            return viewModel.players.sorted { $0.linksContributed > $1.linksContributed }
        }
    }

    // MARK: - Game Stats Section

    private var gameStatsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Game Statistics")
                .font(AppTheme.Typography.sectionHeader)
                .foregroundColor(AppTheme.deepCharcoal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.md) {
                GameStatCard(
                    icon: "link",
                    title: "Longest Chain",
                    value: "\(viewModel.longestChainThisGame)"
                )

                GameStatCard(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Total Chains",
                    value: "\(viewModel.totalChainsCompleted)"
                )

                GameStatCard(
                    icon: "film",
                    title: "Movies Named",
                    value: "\(countMovies)"
                )

                GameStatCard(
                    icon: "person.2",
                    title: "Actors Named",
                    value: "\(countActors)"
                )
            }
        }
        .gameCard()
    }

    private var countMovies: Int {
        viewModel.players.reduce(0) { total, player in
            total + (player.linksContributed / 2)
        }
    }

    private var countActors: Int {
        viewModel.players.reduce(0) { total, player in
            total + ((player.linksContributed + 1) / 2)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            PrimaryButton(title: "Play Again", icon: "arrow.clockwise") {
                viewModel.startGame()
            }

            SecondaryButton(title: "Back to Setup", icon: "gearshape") {
                viewModel.returnToSetup()
            }
        }
        .padding(.top, AppTheme.Spacing.md)
    }
}

// MARK: - Player Standing Row

struct PlayerStandingRow: View {
    let rank: Int
    let player: MovieChainPlayer
    let gameMode: MovieChainGameMode
    let isWinner: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 32, height: 32)

                if rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.white)
                } else {
                    Text("\(rank)")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }

            // Player info
            Circle()
                .fill(player.color)
                .frame(width: 16, height: 16)

            Text(player.name)
                .font(AppTheme.Typography.cardTitle)
                .foregroundColor(isWinner ? AppTheme.deepCharcoal : AppTheme.deepCharcoal)

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                switch gameMode {
                case .classic:
                    HStack(spacing: 2) {
                        ForEach(0..<gameMode.defaultLives, id: \.self) { index in
                            Image(systemName: index < player.lives ? "heart.fill" : "heart")
                                .font(AppTheme.Typography.tabLabel)
                                .foregroundStyle(.red)
                        }
                    }
                case .timed:
                    Text("\(player.score) pts")
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(GameTheme.movieChain.accentColor)
                case .endless:
                    Text("\(player.linksContributed) links")
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(GameTheme.movieChain.accentColor)
                }

                Text("\(player.linksContributed) contributed")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.mediumGray)
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .padding(.horizontal, AppTheme.Spacing.md)
        .background(isWinner ? player.color.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return AppTheme.mediumGray
        }
    }

    private var rankIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "star.fill"
        default: return ""
        }
    }
}

// MARK: - Game Stat Card

struct GameStatCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(AppTheme.Typography.sectionHeader)
                .foregroundStyle(GameTheme.movieChain.accentColor)

            Text(value)
                .font(AppTheme.Typography.sectionHeader)
                .foregroundColor(AppTheme.deepCharcoal)

            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.mediumGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .background(GameTheme.movieChain.lightBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
    }
}

#Preview {
    MovieChainGameOverView(
        viewModel: {
            let vm = MovieChainViewModel()
            vm.setPlayerCount(3)
            return vm
        }(),
        winner: MovieChainPlayer(name: "Alice", color: .blue, lives: 2)
    )
}
