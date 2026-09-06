import SwiftUI

struct Name5GameView: View {
    @State private var viewModel = Name5ViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ZStack {
                // Plain retro ground behind the phase switch; each phase view
                // paints its own motif field with a distinct seed (§3, §7).
                AppTheme.Retro.ground
                    .ignoresSafeArea()

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
                            // §6: SF glyphs survive only as functional chrome.
                            Image(systemName: "ellipsis.circle")
                                .font(AppTheme.Typography.subsectionHeader)
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
            .tint(AppTheme.Retro.ink)
        }
    }
}

// MARK: - Game Over View
struct GameOverView: View {
    var viewModel: Name5ViewModel

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // The results column runs the full width; motifs keep to the
                // nav strip and the outer edges (§7 — the generator adds the
                // 12pt clearance itself).
                MotifGroundView(seed: 0x4A5E_0F08,
                                exclusions: [CGRect(x: 8, y: 56,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 56)])
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header: spot plate + framed Lilita title (§3 recipe /
                    // §9 — no naked SF hero on a celebration screen).
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ZStack {
                            Circle().fill(AppTheme.Retro.panel)
                            Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                            RetroSpotIllustration(kind: .bubbleFive)
                                .frame(width: 64, height: 64)
                        }
                        .frame(width: 84, height: 84)

                        // Celebration accent is grass (§3 recipe); cream
                        // display text ≥17pt Lilita is sanctioned there (§8).
                        Text("Game Over!")
                            .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                            .foregroundColor(AppTheme.Retro.cream)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .retroPanel(AppTheme.Retro.grass)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                                    .fill(AppTheme.Retro.ink)
                                    .offset(x: AppTheme.Retro.shadowOffset,
                                            y: AppTheme.Retro.shadowOffset)
                            )
                            .rotationEffect(.degrees(-1))

                        Text(winnerText)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Retro.panelText)
                            .multilineTextAlignment(.center)
                            .retroLozenge()
                            .rotationEffect(.degrees(0.8))
                    }
                    .padding(.top, AppTheme.Spacing.lg)

                    // Standings (pass-and-play only)
                    if !viewModel.playerStandings.isEmpty {
                        StandingsCard(
                            standings: viewModel.playerStandings,
                            winners: viewModel.winningPlayerNumbers
                        )
                    }

                    // Final Stats
                    FinalStatsCard(stats: viewModel.stats)

                    // Recent Rounds
                    if !viewModel.roundResults.isEmpty {
                        RecentRoundsCard(results: viewModel.roundResults)
                    }

                    // Buttons
                    VStack(spacing: AppTheme.Spacing.md) {
                        RetroPrimaryButton(title: "Play Again", icon: "play.fill",
                                           accent: Name5Style.accent) {
                            viewModel.startGame()
                        }

                        // Cream panel + ink text is this language's secondary
                        // button; §3.2's one-accent rule keeps lilac alone.
                        RetroPrimaryButton(title: "Back to Setup", icon: "gearshape",
                                           accent: AppTheme.Retro.panel) {
                            viewModel.resetGame()
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
    }

    private var winnerText: String {
        let winners = viewModel.winningPlayerNumbers
        if winners.isEmpty {
            return "Great job playing!"
        } else if winners.count == 1 {
            return "Player \(winners[0]) wins!"
        } else {
            let names = winners.map { "Player \($0)" }.joined(separator: " & ")
            return "It's a tie — \(names)!"
        }
    }
}

// MARK: - Standings Card
struct StandingsCard: View {
    let standings: [Name5PlayerStanding]
    let winners: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Standings")
                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)

            ForEach(standings) { standing in
                HStack(spacing: AppTheme.Spacing.md) {
                    // §8: the semantic color rides on the ink-outlined badge
                    // so the row copy stays ink-on-cream.
                    Name5StatusBadge(
                        systemImage: winners.contains(standing.playerNumber) ? "crown.fill" : "person.fill",
                        color: winners.contains(standing.playerNumber) ? Name5Style.winnerColor : Name5Style.infoColor
                    )

                    Text("Player \(standing.playerNumber)")
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .foregroundColor(AppTheme.Retro.panelText)

                    Spacer()

                    Text("\(standing.successes) of \(standing.attempts)")
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .monospacedDigit()
                        .foregroundColor(AppTheme.Retro.panelText)
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Final Stats Card
struct FinalStatsCard: View {
    let stats: GameStats

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Final Stats")
                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
                FinalStatItem(
                    icon: "target",
                    label: "Total Rounds",
                    value: "\(stats.roundsPlayed)",
                    color: Name5Style.accent
                )

                FinalStatItem(
                    icon: "checkmark",
                    label: "Successful",
                    value: "\(stats.roundsWon)",
                    color: Name5Style.successColor
                )

                FinalStatItem(
                    icon: "flame.fill",
                    label: "Best Streak",
                    value: "\(stats.bestStreak)",
                    color: Name5Style.missColor
                )

                FinalStatItem(
                    icon: "percent",
                    label: "Success Rate",
                    value: "\(Int(stats.successRate * 100))%",
                    color: Name5Style.accent
                )
            }
        }
        .retroCard()
    }
}

struct FinalStatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // §9: the 10%-opacity tint circle is retired — the stat color now
            // rides on an ink-outlined badge inside a double-ruled tile (§5).
            Name5StatusBadge(systemImage: icon, color: color, diameter: 32)

            Text(value)
                .font(AppTheme.Retro.Typography.heading(24, relativeTo: .title))
                .foregroundColor(AppTheme.Retro.panelText)

            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.cocoa)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.sm)
        .frame(maxWidth: .infinity)
        .retroPanel(AppTheme.Retro.panel, cornerRadius: AppTheme.Retro.Radius.inner)
    }
}

// MARK: - Recent Rounds Card
struct RecentRoundsCard: View {
    let results: [RoundResult]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Recent Rounds")
                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)

            ForEach(results.suffix(5).reversed()) { result in
                HStack {
                    Name5StatusBadge(systemImage: result.success ? "checkmark" : "xmark",
                                     color: result.success ? Name5Style.successColor : Name5Style.missColor)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(result.promptText)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Retro.panelText)
                            .lineLimit(1)

                        if let time = result.timeUsed {
                            Text("\(time)s")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Retro.cocoa)
                        }
                    }

                    Spacer()

                    if let playerNum = result.playerNumber {
                        Text("P\(playerNum)")
                            .font(AppTheme.Retro.Typography.pillLabel)
                            .foregroundColor(Name5Style.chipTextColor(on: Name5Style.accent))
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .background(Capsule().fill(Name5Style.accent))
                            .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))
                    }
                }
                .padding(AppTheme.Spacing.sm)
                .retroPanel(AppTheme.Retro.panel, cornerRadius: AppTheme.Retro.Radius.inner)
            }
        }
        .retroCard()
    }
}
