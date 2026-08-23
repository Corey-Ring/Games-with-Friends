import SwiftUI

struct VibeCheckGameOverView: View {
    var viewModel: VibeCheckViewModel
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            GeometryReader { geo in
                MotifGroundView(seed: 0x71BE_0C0A,
                                exclusions: [CGRect(x: 8, y: 8,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 16)])
            }
            .ignoresSafeArea()

            if showConfetti {
                ConfettiView()
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
            withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                showConfetti = true
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

            ForEach(Array(viewModel.sortedTeamsByScore.enumerated()), id: \.element.id) { index, team in
                FinalTeamRow(
                    rank: index + 1,
                    team: team,
                    isWinner: index == 0
                )

                if index < viewModel.sortedTeamsByScore.count - 1 {
                    Divider().overlay(AppTheme.Retro.ink.opacity(0.25))
                }
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

// MARK: - Final Team Row

struct FinalTeamRow: View {
    let rank: Int
    let team: VibeCheckTeam
    let isWinner: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Rank with medal for top 3
            VibeCheckRankBadge(rank: rank, diameter: 36)

            // Team info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(team.name)
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

                Text(team.playerNames.joined(separator: ", "))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(team.score)")
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

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

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
            ConfettiParticle(
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

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
    let velocity: CGPoint
    var opacity: Double
}

#Preview {
    let viewModel = VibeCheckViewModel()
    viewModel.settings.teamCount = 2
    viewModel.settings.playersPerTeam = 3
    viewModel.proceedToTeamSetup()
    viewModel.teams[0].score = 520
    viewModel.teams[1].score = 380
    return VibeCheckGameOverView(viewModel: viewModel)
}
