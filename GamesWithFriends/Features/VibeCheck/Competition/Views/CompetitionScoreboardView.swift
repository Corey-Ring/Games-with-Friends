import SwiftUI

struct CompetitionScoreboardView: View {
    var viewModel: CompetitionVibeCheckViewModel

    var body: some View {
        ZStack {
            GeometryReader { geo in
                MotifGroundView(seed: 0x71BE_0C09,
                                exclusions: [CGRect(x: 8, y: 8,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 16)])
            }
            .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                headerSection

                // Player standings
                standingsSection

                Spacer()

                // Next round info
                nextRoundInfo

                // Continue button
                continueButton
            }
            .padding()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VibeCheckHeader(title: "Scoreboard",
                        subtitle: "Target: \(viewModel.settings.targetScore) pts")
            .padding(.top, AppTheme.Spacing.sm)
    }

    private var standingsSection: some View {
        VStack(spacing: 12) {
            ForEach(Array(viewModel.sortedPlayersByScore.enumerated()), id: \.element.id) { index, player in
                CompetitionPlayerScoreRow(
                    rank: index + 1,
                    player: player,
                    targetScore: viewModel.settings.targetScore,
                    isLeading: index == 0
                )
            }
        }
        .frame(maxWidth: .infinity)
        .retroCard()
    }

    private var nextRoundInfo: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("Round \(viewModel.rounds.count + 1)")
                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                .foregroundColor(VibeCheckStyle.chipTextColor(on: VibeCheckStyle.accent))
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, 2)
                .retroLozenge(VibeCheckStyle.accent)

            HStack(spacing: 6) {
                Image(systemName: "shuffle")
                Text("Vibe Setter will be randomly selected")
            }
            .font(AppTheme.Typography.secondary)
            .foregroundColor(AppTheme.Retro.panelText)
        }
        .frame(maxWidth: .infinity)
        .retroCard()
    }

    private var continueButton: some View {
        RetroPrimaryButton(title: "Next Round", icon: "arrow.right",
                           accent: VibeCheckStyle.accent) {
            viewModel.continueToNextRound()
        }
    }
}

// MARK: - Player Score Row

struct CompetitionPlayerScoreRow: View {
    let rank: Int
    let player: CompetitionPlayer
    let targetScore: Int
    let isLeading: Bool

    private var progress: Double {
        min(1.0, Double(player.score) / Double(targetScore))
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Rank indicator — candy medal disc, ink outline (§2 rule 1).
                VibeCheckRankBadge(rank: rank)

                // Player name
                Text(player.name)
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText)

                Spacer()

                // Score
                Text("\(player.score)")
                    .font(AppTheme.Retro.Typography.heading(24, relativeTo: .title2))
                    .monospacedDigit()
                    .foregroundColor(isLeading ? VibeCheckStyle.leaderColor : AppTheme.Retro.panelText)
            }

            // Progress bar (§4 gotcha 6 — outlined meter, flat candy fill).
            VibeCheckProgressBar(progress: progress, height: 8)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

#Preview {
    let viewModel = CompetitionVibeCheckViewModel()
    viewModel.settings.playerCount = 4
    viewModel.proceedToPlayerSetup()
    viewModel.players[0].name = "Alice"
    viewModel.players[1].name = "Bob"
    viewModel.players[2].name = "Charlie"
    viewModel.players[3].name = "Diana"
    viewModel.players[0].score = 175
    viewModel.players[1].score = 125
    viewModel.players[2].score = 100
    viewModel.players[3].score = 50
    return CompetitionScoreboardView(viewModel: viewModel)
}
