import SwiftUI

struct ScoreboardView: View {
    var viewModel: VibeCheckViewModel

    var body: some View {
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
        .background {
            LinearGradient(
                colors: [GameTheme.vibeCheck.accentColor.opacity(0.1), GameTheme.vibeCheck.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 36))
                .foregroundStyle(.yellow)

            Text("SCOREBOARD")
                .font(AppTheme.Typography.sectionHeader)

            Text("Target: \(viewModel.settings.targetScore) pts")
                .font(AppTheme.Typography.secondary)
                .foregroundStyle(.secondary)
        }
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
                    Divider()
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
    }

    private var nextRoundInfo: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("Round \(viewModel.rounds.count + 1)")
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(.purple)

            if let nextSetter = viewModel.promptSetterTeam {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill.questionmark")
                    Text("\(nextSetter.name) is the Prompt Setter")
                }
                .font(AppTheme.Typography.secondary)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(GameTheme.vibeCheck.lightBackground)
        }
    }

    private var continueButton: some View {
        Button {
            viewModel.continueToNextRound()
        } label: {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                Text("NEXT ROUND")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background {
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
        .buttonStyle(.plain)
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
                // Rank indicator
                ZStack {
                    if rank == 1 {
                        Circle()
                            .fill(AppTheme.medalGold)
                            .frame(width: 32, height: 32)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    } else {
                        Circle()
                            .fill(AppTheme.warmLinen)
                            .frame(width: 32, height: 32)

                        Text("\(rank)")
                            .font(AppTheme.Typography.secondary.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }

                // Team info
                VStack(alignment: .leading, spacing: 2) {
                    Text(team.name)
                        .font(AppTheme.Typography.cardTitle)

                    Text(team.playerNames.joined(separator: ", "))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Score
                Text("\(team.score)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isLeading ? .purple : .primary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
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
