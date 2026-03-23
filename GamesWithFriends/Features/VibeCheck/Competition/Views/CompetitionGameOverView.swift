import SwiftUI

struct CompetitionGameOverView: View {
    var viewModel: CompetitionVibeCheckViewModel
    @State private var showConfetti = false

    var body: some View {
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
        .background {
            ZStack {
                LinearGradient(
                    colors: [GameTheme.vibeCheck.accentColor.opacity(0.15), GameTheme.vibeCheck.accentColor.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if showConfetti {
                    CompetitionConfettiView()
                }
            }
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
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.medalGold, AppTheme.warning],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: AppTheme.medalGold.opacity(0.5), radius: 10)

            Text("GAME OVER!")
                .font(AppTheme.Typography.hero)

            if let winner = viewModel.winner {
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("\(winner.name) Wins!")
                        .font(AppTheme.Typography.sectionHeader.weight(.semibold))
                        .foregroundStyle(GameTheme.vibeCheck.accentColor)

                    Text("\(winner.score) points")
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    private var standingsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("FINAL STANDINGS")
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(.secondary)

            ForEach(Array(viewModel.sortedPlayersByScore.enumerated()), id: \.element.id) { index, player in
                CompetitionFinalPlayerRow(
                    rank: index + 1,
                    player: player,
                    isWinner: index == 0
                )
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(AppTheme.pureWhite)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
    }

    private var playAgainButton: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.resetGame()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("PLAY AGAIN")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    GameTheme.vibeCheck.accentColor
                }
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            }
            .buttonStyle(.plain)

            Button {
                viewModel.returnToSetup()
            } label: {
                Text("Back to Setup")
                    .font(AppTheme.Typography.secondary)
                    .foregroundStyle(.secondary)
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
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(medalColor)
                        .frame(width: 36, height: 36)

                    if rank == 1 {
                        Image(systemName: "crown.fill")
                            .font(AppTheme.Typography.detail)
                            .foregroundStyle(.white)
                    } else {
                        Text("\(rank)")
                            .font(AppTheme.Typography.cardTitle.weight(.bold))
                            .foregroundStyle(.white)
                    }
                } else {
                    Text("\(rank).")
                        .font(AppTheme.Typography.cardTitle.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 36)
                }
            }

            // Player info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(player.name)
                        .font(AppTheme.Typography.cardTitle)

                    if isWinner {
                        Text("WINNER")
                            .font(AppTheme.Typography.tabLabel.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, 2)
                            .background {
                                Capsule()
                                    .fill(GameTheme.vibeCheck.accentColor)
                            }
                    }
                }
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(player.score)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text("points")
                    .font(AppTheme.Typography.tabLabel)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private var medalColor: Color {
        switch rank {
        case 1: return AppTheme.medalGold
        case 2: return AppTheme.medalSilver
        case 3: return AppTheme.medalBronze
        default: return .clear
        }
    }
}

// MARK: - Confetti Effect

struct CompetitionConfettiView: View {
    @State private var particles: [CompetitionConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
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
        let colors: [Color] = [GameTheme.vibeCheck.accentColor, AppTheme.warning, AppTheme.medalGold, AppTheme.success, .blue, .pink]
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
