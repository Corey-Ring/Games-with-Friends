import SwiftUI

struct Name5PlayView: View {
    var viewModel: Name5ViewModel

    var body: some View {
        ZStack {
            // Background
            GameBackground(gameTheme: .name5)

            VStack(spacing: AppTheme.Spacing.lg) {
                // Player indicator (if multiplayer)
                if viewModel.playerCount > 1, let player = viewModel.currentPlayer {
                    PlayerIndicator(player: player)
                        .padding(.top)
                }

                // Timer (if ready or playing)
                if viewModel.gamePhase == .ready || viewModel.gamePhase == .playing || viewModel.gamePhase == .paused {
                    if viewModel.timerEnabled {
                        TimerView(
                            timeRemaining: viewModel.timeRemaining,
                            progress: viewModel.timerProgress,
                            color: viewModel.timerColor,
                            isRunning: viewModel.isTimerRunning
                        )
                        .padding(.horizontal)
                    }
                }

                // Prompt Card
                if let prompt = viewModel.currentPrompt {
                    PromptCard(prompt: prompt, phase: viewModel.gamePhase)
                        .padding(.horizontal)
                }

                Spacer()

                // Action Buttons based on phase
                if viewModel.gamePhase == .ready {
                    ReadyButtons(viewModel: viewModel)
                        .padding()
                } else if viewModel.gamePhase == .playing {
                    PlayingButtons(viewModel: viewModel)
                        .padding()
                } else if viewModel.gamePhase == .paused {
                    PausedButtons(viewModel: viewModel)
                        .padding()
                }
            }
        }
    }
}

// MARK: - Player Indicator
struct PlayerIndicator: View {
    let player: PlayerTurn

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.title2)
            Text("Player \(player.playerNumber)")
                .font(.title3)
                .fontWeight(.bold)
        }
        .foregroundColor(GameTheme.name5.accentColor)
        .padding()
        .background(
            Capsule()
                .fill(GameTheme.name5.accentColor.opacity(0.15))
        )
    }
}

// MARK: - Timer View
struct TimerView: View {
    let timeRemaining: Int
    let progress: Double
    let color: Color
    let isRunning: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .stroke(AppTheme.mediumGray.opacity(0.2), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: progress)

                VStack(spacing: 4) {
                    Text("\(timeRemaining)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(color)

                    Text("seconds")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.mediumGray)
                }
            }
            .frame(width: 140, height: 140)
        }
    }
}

// MARK: - Prompt Card
struct PromptCard: View {
    let prompt: Name5Prompt
    let phase: GamePhase

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Category & difficulty badges
            HStack(spacing: AppTheme.Spacing.sm) {
                HStack(spacing: 4) {
                    Image(systemName: prompt.category.icon)
                        .font(.caption)
                    Text(prompt.category.rawValue)
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, 6)
                .background(Capsule().fill(GameTheme.name5.accentColor))

                HStack(spacing: 3) {
                    ForEach(0..<difficultyStars, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    Text(prompt.difficulty.rawValue)
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, 6)
                .background(Capsule().fill(difficultyColor))
            }

            // Prompt text
            Text(prompt.text)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.deepCharcoal)
                .padding(.horizontal)
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .gameCard()
        .scaleEffect(phase == .playing ? 1.0 : 0.95)
        .animation(.spring(response: 0.3), value: phase)
    }

    private var difficultyStars: Int {
        switch prompt.difficulty {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }

    private var difficultyColor: Color {
        switch prompt.difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - Ready Buttons
struct ReadyButtons: View {
    var viewModel: Name5ViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            PrimaryButton(title: "Start", icon: "play.fill") {
                viewModel.startRound()
            }

            SecondaryButton(title: "Skip", icon: "forward.fill") {
                viewModel.skipPrompt()
            }
        }
    }
}

// MARK: - Playing Buttons
struct PlayingButtons: View {
    var viewModel: Name5ViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                Button(action: {
                    viewModel.markSuccess()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Got It!")
                            .fontWeight(.bold)
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                            .fill(Color.green)
                    )
                }
                .pressable()

                Button(action: {
                    viewModel.markFailure()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Failed")
                            .fontWeight(.bold)
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                            .fill(Color.red)
                    )
                }
                .pressable()
            }

            if viewModel.timerEnabled {
                SecondaryButton(title: "Pause", icon: "pause.fill") {
                    viewModel.pauseTimer()
                }
            }
        }
    }
}

// MARK: - Paused Buttons
struct PausedButtons: View {
    var viewModel: Name5ViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Paused")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.mediumGray)

            PrimaryButton(title: "Resume", icon: "play.fill") {
                viewModel.resumeTimer()
            }

            Button(action: {
                viewModel.markFailure()
            }) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Give Up")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .fill(Color.red.opacity(0.15))
                )
            }
            .pressable()
        }
    }
}
