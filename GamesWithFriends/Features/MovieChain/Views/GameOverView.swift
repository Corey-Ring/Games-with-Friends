import SwiftUI

/// View shown when the Movie Chain game ends
struct MovieChainGameOverView: View {
    @ObservedObject var viewModel: MovieChainViewModel
    let winner: MovieChainPlayer?

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Celebration screen: scrolling column owns the width, motifs
                // keep to gutters and the top band (§7).
                MotifGroundView(seed: 0xF11_A0503,
                                exclusions: [CGRect(x: 8, y: 70,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 70)])
            }
            .ignoresSafeArea()

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
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Winner Section

    private var winnerSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Trophy on a spot plate (§9 — no naked SF hero).
            ZStack {
                Circle().fill(AppTheme.Retro.panel)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(AppTheme.Retro.mustard)
                    .shadow(color: AppTheme.Retro.ink, radius: 0, x: 2, y: 2)
            }
            .frame(width: 110, height: 110)

            if let winner = winner {
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Winner!")
                        .font(AppTheme.Retro.Typography.heading(24, relativeTo: .title))
                        .foregroundColor(AppTheme.Retro.ink)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .retroPanel(MovieChainStyle.accent)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                                .fill(AppTheme.Retro.ink)
                                .offset(x: AppTheme.Retro.shadowOffset,
                                        y: AppTheme.Retro.shadowOffset)
                        )
                        .rotationEffect(.degrees(-1))

                    HStack(spacing: AppTheme.Spacing.md) {
                        Circle()
                            .fill(winner.color)
                            .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                            .frame(width: 24, height: 24)

                        Text(winner.name)
                            .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                            .foregroundColor(AppTheme.Retro.panelText)
                    }
                    .retroLozenge()
                    .rotationEffect(.degrees(0.8))
                }
            } else {
                Text("Game Over!")
                    .font(AppTheme.Retro.Typography.heading(24, relativeTo: .title))
                    .foregroundColor(AppTheme.Retro.ink)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .retroPanel(MovieChainStyle.accent)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                            .fill(AppTheme.Retro.ink)
                            .offset(x: AppTheme.Retro.shadowOffset,
                                    y: AppTheme.Retro.shadowOffset)
                    )
                    .rotationEffect(.degrees(-1))
            }
        }
        .padding(.top, AppTheme.Spacing.lg)
    }

    // MARK: - Standings Section

    private var standingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Final Standings")
                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)

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
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
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
                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)

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
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
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
            RetroPrimaryButton(title: "Play Again", icon: "arrow.clockwise",
                               accent: MovieChainStyle.accent) {
                viewModel.startGame()
            }

            RetroPrimaryButton(title: "Back to Setup", icon: "gearshape",
                               accent: AppTheme.Retro.panel) {
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
            // Rank medal — candy metals with ink outlines (§2 rule 1).
            ZStack {
                Circle().fill(rankColor)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth)

                if rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(rankGlyphColor)
                } else {
                    Text("\(rank)")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(rankGlyphColor)
                }
            }
            .frame(width: 32, height: 32)

            // Player info
            Circle()
                .fill(player.color)
                .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                .frame(width: 16, height: 16)

            Text(player.name)
                .font(AppTheme.Retro.Typography.cardTitle)
                .foregroundColor(AppTheme.Retro.panelText)

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                switch gameMode {
                case .classic:
                    HStack(spacing: 2) {
                        ForEach(0..<gameMode.defaultLives, id: \.self) { index in
                            Image(systemName: index < player.lives ? "heart.fill" : "heart")
                                .font(AppTheme.Typography.tabLabel)
                                .foregroundStyle(MovieChainStyle.lives)
                        }
                    }
                case .timed:
                    Text("\(player.score) pts")
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .foregroundColor(AppTheme.Retro.panelText)
                case .endless:
                    Text("\(player.linksContributed) links")
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .foregroundColor(AppTheme.Retro.panelText)
                }

                Text("\(player.linksContributed) contributed")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .padding(.horizontal, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                .fill(isWinner ? AppTheme.Retro.mustard.opacity(0.35) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                .stroke(isWinner ? AppTheme.Retro.ink : Color.clear,
                        lineWidth: AppTheme.Retro.strokeWidth)
        )
    }

    private var rankColor: Color {
        switch rank {
        case 1: return MovieChainStyle.medalFirst
        case 2: return MovieChainStyle.medalSecond
        case 3: return MovieChainStyle.medalThird
        default: return AppTheme.Retro.panel
        }
    }

    private var rankGlyphColor: Color {
        switch rank {
        case 1, 2: return AppTheme.Retro.ink
        case 3: return AppTheme.Retro.cream
        default: return AppTheme.Retro.panelText
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
                .foregroundStyle(MovieChainStyle.accent)

            Text(value)
                .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)

            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                .fill(AppTheme.Retro.ground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                .stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth)
        )
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
