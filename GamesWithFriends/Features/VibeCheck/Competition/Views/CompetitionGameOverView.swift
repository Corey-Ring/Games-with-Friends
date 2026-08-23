import SwiftUI

struct CompetitionGameOverView: View {
    var viewModel: CompetitionVibeCheckViewModel
    @State private var showConfetti = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            GeometryReader { geo in
                MotifGroundView(seed: 0x71BE_0C0B,
                                exclusions: [CGRect(x: 8, y: 8,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 16)])
            }
            .ignoresSafeArea()

            if showConfetti {
                CompetitionConfettiView()
            }

            VStack(spacing: AppTheme.Spacing.lg) {
                // Header with winner
                winnerSection

                // Final standings
                standingsSection

                Spacer()

                // Play again button
                playAgainButton
            }
            .padding()
        }
        .onAppear {
            // Skip confetti entirely under Reduce Motion; keep the celebratory haptic
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                    showConfetti = true
                }
            }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    // MARK: - Sections

    private var winnerSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Celebration spot plate (§9 — no naked SF hero, no gradient fill).
            ZStack {
                Circle().fill(AppTheme.Retro.panel)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(AppTheme.Retro.mustard)
                    .shadow(color: AppTheme.Retro.ink, radius: 0, x: 2, y: 2)
            }
            .frame(width: 110, height: 110)

            // Celebration accent is grass (§3 recipe); cream display type
            // ≥17pt is sanctioned on grass.
            Text("Game Over!")
                .font(AppTheme.Retro.Typography.heading(28, relativeTo: .title))
                .foregroundColor(AppTheme.Retro.cream)
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

            if let winner = viewModel.winner {
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("\(winner.name) Wins!")
                        .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                        .foregroundColor(AppTheme.Retro.panelText)
                        .retroLozenge()
                        .rotationEffect(.degrees(0.8))

                    Text("\(winner.score) points")
                        .font(AppTheme.Typography.secondary)
                        .foregroundColor(AppTheme.Retro.panelText)
                        .retroLozenge()
                }
            }
        }
        .padding(.top, AppTheme.Spacing.md)
    }

    private var standingsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Final Standings")
                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)

            ForEach(Array(viewModel.sortedPlayersByScore.enumerated()), id: \.element.id) { index, player in
                CompetitionFinalPlayerRow(
                    rank: index + 1,
                    player: player,
                    isWinner: index == 0
                )
            }
        }
        .frame(maxWidth: .infinity)
        .retroCard()
    }

    private var playAgainButton: some View {
        VStack(spacing: 12) {
            RetroPrimaryButton(title: "Play Again", icon: "arrow.counterclockwise",
                               accent: VibeCheckStyle.accent) {
                viewModel.resetGame()
            }

            // Cream panel + ink text is this language's secondary button;
            // §3.2's one-accent rule keeps berry alone.
            RetroPrimaryButton(title: "Back to Setup", icon: "gearshape",
                               accent: AppTheme.Retro.panel) {
                viewModel.returnToSetup()
            }
        }
    }
}

// MARK: - Final Player Row

struct CompetitionFinalPlayerRow: View {
    let rank: Int
    let player: CompetitionPlayer
    let isWinner: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Rank with medal for top 3
            VibeCheckRankBadge(rank: rank, diameter: 36)

            // Player info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(player.name)
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .foregroundColor(AppTheme.Retro.panelText)

                    if isWinner {
                        Text("WINNER")
                            .font(AppTheme.Retro.Typography.pillLabel)
                            .foregroundColor(VibeCheckStyle.chipTextColor(on: VibeCheckStyle.accent))
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(VibeCheckStyle.accent))
                            .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))
                    }
                }
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(player.score)")
                    .font(AppTheme.Retro.Typography.heading(24, relativeTo: .title2))
                    .monospacedDigit()
                    .foregroundColor(AppTheme.Retro.panelText)

                Text("points")
                    .font(AppTheme.Typography.tabLabel)
                    .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .padding(.horizontal, AppTheme.Spacing.sm)
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
}

// MARK: - Confetti Effect

struct CompetitionConfettiView: View {
    @State private var particles: [CompetitionConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    // Rule 1: outlines on everything, confetti included.
                    Circle()
                        .fill(particle.color)
                        .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles()
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        let colors: [Color] = VibeCheckStyle.confettiColors
        particles = (0..<50).map { _ in
            CompetitionConfettiParticle(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...10),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -20
                ),
                velocity: CGPoint(
                    x: CGFloat.random(in: -50...50),
                    y: CGFloat.random(in: 200...400)
                ),
                opacity: 1.0
            )
        }
    }

    private func animateParticles() {
        withAnimation(.linear(duration: 3)) {
            for i in particles.indices {
                particles[i].position.y += particles[i].velocity.y
                particles[i].position.x += particles[i].velocity.x
                particles[i].opacity = 0
            }
        }
    }
}

struct CompetitionConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
    let velocity: CGPoint
    var opacity: Double
}

#Preview {
    let viewModel = CompetitionVibeCheckViewModel()
    viewModel.settings.playerCount = 4
    viewModel.proceedToPlayerSetup()
    viewModel.players[0].name = "Alice"
    viewModel.players[1].name = "Bob"
    viewModel.players[2].name = "Charlie"
    viewModel.players[3].name = "Diana"
    viewModel.players[0].score = 520
    viewModel.players[1].score = 380
    viewModel.players[2].score = 275
    viewModel.players[3].score = 150
    return CompetitionGameOverView(viewModel: viewModel)
}
