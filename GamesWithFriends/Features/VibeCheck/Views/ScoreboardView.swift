import SwiftUI

struct ScoreboardView: View {
    var viewModel: VibeCheckViewModel

    var body: some View {
        ZStack {
            GeometryReader { geo in
                MotifGroundView(seed: 0x71BE_0C08,
                                exclusions: [CGRect(x: 8, y: 8,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 16)])
            }
            .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                headerSection

                // Team standings
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
        VStack(spacing: AppTheme.Spacing.md) {
            ForEach(Array(viewModel.sortedTeamsByScore.enumerated()), id: \.element.id) { index, team in
                TeamScoreRow(
                    rank: index + 1,
                    team: team,
                    targetScore: viewModel.settings.targetScore,
                    isLeading: index == 0
                )

                if index < viewModel.sortedTeamsByScore.count - 1 {
                    Divider().overlay(AppTheme.Retro.ink.opacity(0.25))
                }
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

            if let nextSetter = viewModel.promptSetterTeam {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill.questionmark")
                    Text("\(nextSetter.name) is the Prompt Setter")
                }
                .font(AppTheme.Typography.secondary)
                .foregroundColor(AppTheme.Retro.panelText)
            }
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

// MARK: - Team Score Row

struct TeamScoreRow: View {
    let rank: Int
    let team: VibeCheckTeam
    let targetScore: Int
    let isLeading: Bool

    private var progress: Double {
        min(1.0, Double(team.score) / Double(targetScore))
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Rank indicator — candy medal disc, ink outline (§2 rule 1).
                VibeCheckRankBadge(rank: rank)

                // Team info
                VStack(alignment: .leading, spacing: 2) {
                    Text(team.name)
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .foregroundColor(AppTheme.Retro.panelText)

                    Text(team.playerNames.joined(separator: ", "))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()

                // Score
                Text("\(team.score)")
                    .font(AppTheme.Retro.Typography.heading(28, relativeTo: .title))
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
    let viewModel = VibeCheckViewModel()
    viewModel.settings.teamCount = 2
    viewModel.settings.playersPerTeam = 3
    viewModel.proceedToTeamSetup()
    viewModel.teams[0].score = 175
    viewModel.teams[1].score = 125
    return ScoreboardView(viewModel: viewModel)
}
