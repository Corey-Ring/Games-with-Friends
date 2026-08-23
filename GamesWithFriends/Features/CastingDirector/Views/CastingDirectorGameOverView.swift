import SwiftUI

/// Final results screen after all rounds are complete
struct CastingDirectorGameOverView: View {
    @ObservedObject var viewModel: CastingDirectorViewModel

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Celebration screen — motifs in the gutters and top band (§7).
                MotifGroundView(seed: 0xCA57_0D03,
                                exclusions: [CGRect(x: 8, y: 70,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 70)])
            }
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
            .scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden()
    }

    // MARK: - Trophy Header

    private var trophyHeader: some View {
        VStack(spacing: 12) {
            // Trophy on a spot plate (§9 — no naked SF hero).
            ZStack {
                Circle().fill(AppTheme.Retro.panel)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(CastingDirectorStyle.medalColor)
                    .shadow(color: AppTheme.Retro.ink, radius: 0, x: 2, y: 2)
            }
            .frame(width: 110, height: 110)

            Text("Game Over!")
                .font(AppTheme.Retro.Typography.heading(24, relativeTo: .title))
                .foregroundColor(AppTheme.Retro.ink)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .retroPanel(CastingDirectorStyle.accent)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                        .fill(AppTheme.Retro.ink)
                        .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
                )
                .rotationEffect(.degrees(-1))

            if viewModel.gameMode == .passAndPlay, let winner = viewModel.winner {
                HStack(spacing: 6) {
                    Circle()
                        .fill(winner.color)
                        .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                        .frame(width: 14, height: 14)
                    Text("\(winner.name) wins!")
                        .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                        .foregroundColor(AppTheme.Retro.panelText)
                }
                .retroLozenge()
                .rotationEffect(.degrees(0.8))
            }
        }
        .padding(.top)
    }

    // MARK: - Standings

    private var standingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Final Standings")
                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)

            ForEach(Array(viewModel.standings.enumerated()), id: \.element.id) { index, player in
                HStack(spacing: 12) {
                    // Rank medal — candy disc with ink outline (§2 rule 1).
                    ZStack {
                        Circle().fill(index == 0 ? CastingDirectorStyle.medalColor : AppTheme.Retro.ground)
                        Circle().stroke(AppTheme.Retro.ink, lineWidth: 2)
                        Text("#\(index + 1)")
                            .font(AppTheme.Typography.tabLabel)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.Retro.ink)
                    }
                    .frame(width: 32, height: 32)

                    Circle()
                        .fill(player.color)
                        .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                        .frame(width: 20, height: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.name)
                            .font(AppTheme.Retro.Typography.cardTitle)
                            .foregroundColor(AppTheme.Retro.panelText)
                        Text("\(player.correctGuesses) correct, \(player.wrongGuesses) wrong")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                    }

                    Spacer()

                    Text("\(player.score)")
                        .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                        .monospacedDigit()
                        .foregroundColor(AppTheme.Retro.panelText)
                }
                .padding(.vertical, AppTheme.Spacing.sm)
                .padding(.horizontal, AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                        .fill(index == 0 ? CastingDirectorStyle.medalColor.opacity(0.35) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                        .stroke(index == 0 ? AppTheme.Retro.ink : Color.clear,
                                lineWidth: AppTheme.Retro.strokeWidth)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
    }

    // MARK: - Solo Score

    private var soloScoreSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            let player = viewModel.players.first ?? CastingDirectorPlayer(name: "Player")

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Total Score")
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                Text("\(player.score)")
                    .font(AppTheme.Retro.Typography.heading(48, relativeTo: .largeTitle))
                    .monospacedDigit()
                    .foregroundColor(AppTheme.Retro.panelText)
            }

            HStack(spacing: AppTheme.Spacing.lg) {
                StatBubble(label: "Correct", value: "\(player.correctGuesses)", icon: "checkmark", color: CastingDirectorStyle.successColor)
                StatBubble(label: "Wrong", value: "\(player.wrongGuesses)", icon: "xmark", color: CastingDirectorStyle.errorColor)
                StatBubble(label: "Streak", value: "\(viewModel.bestStreak)", icon: "flame.fill", color: CastingDirectorStyle.warningColor)
            }

            // High score comparison
            if player.score >= viewModel.highScore && player.score > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(CastingDirectorStyle.medalColor)
                    Text("New High Score!")
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .foregroundColor(AppTheme.Retro.ink)
                    Image(systemName: "star.fill")
                        .foregroundStyle(CastingDirectorStyle.medalColor)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(Capsule().fill(CastingDirectorStyle.medalColor.opacity(0.4)))
                .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))
                .padding(.top, AppTheme.Spacing.xs)
            } else if viewModel.highScore > 0 {
                Text("High Score: \(viewModel.highScore)")
                    .font(AppTheme.Typography.secondary)
                    .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .retroCard()
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Stats")
                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)
                .retroLozenge()

            HStack(spacing: 12) {
                CastingDirectorStatCard(label: "Rounds", value: "\(viewModel.numberOfRounds)", icon: "number.circle.fill")
                CastingDirectorStatCard(label: "Difficulty", value: viewModel.difficulty.rawValue, icon: "slider.horizontal.3")
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            RetroPrimaryButton(title: "Play Again", icon: "arrow.counterclockwise",
                               accent: CastingDirectorStyle.accent) {
                viewModel.playAgain()
            }

            RetroPrimaryButton(title: "Back to Setup", icon: "gearshape",
                               accent: AppTheme.Retro.panel) {
                viewModel.returnToSetup()
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
            ZStack {
                Circle().fill(color)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: 2)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(CastingDirectorStyle.chipTextColor(on: color))
            }
            .frame(width: 28, height: 28)

            Text(value)
                .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title3))
                .monospacedDigit()
                .foregroundColor(AppTheme.Retro.panelText)
            Text(label)
                .font(AppTheme.Typography.tabLabel)
                .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
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
                .foregroundStyle(CastingDirectorStyle.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                Text(value)
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
    }
}
