import SwiftUI

struct Name5PlayView: View {
    @ObservedObject var viewModel: Name5ViewModel

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
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
        .foregroundColor(.blue)
        .padding()
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.15))
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
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)

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
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        VStack(spacing: 20) {
            // Category badge
            HStack {
                Image(systemName: prompt.category.icon)
                    .font(.caption)
                Text(prompt.category.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.blue)
            )

            // Prompt text
            Text(prompt.text)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal)

            // Difficulty indicator
            HStack(spacing: 4) {
                ForEach(0..<difficultyStars, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
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
}

// MARK: - Ready Buttons
struct ReadyButtons: View {
    @ObservedObject var viewModel: Name5ViewModel

    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                viewModel.startRound()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start")
                        .fontWeight(.bold)
                }
                .font(.title2)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
            }

            Button(action: {
                viewModel.skipPrompt()
            }) {
                HStack {
                    Image(systemName: "forward.fill")
                    Text("Skip")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.15))
                )
            }
        }
    }
}

// MARK: - Playing Buttons
struct PlayingButtons: View {
    @ObservedObject var viewModel: Name5ViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
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
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green)
                    )
                }

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
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red)
                    )
                }
            }

            if viewModel.timerEnabled {
                Button(action: {
                    viewModel.pauseTimer()
                }) {
                    HStack {
                        Image(systemName: "pause.fill")
                        Text("Pause")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.15))
                    )
                }
            }
        }
    }
}

// MARK: - Paused Buttons
struct PausedButtons: View {
    @ObservedObject var viewModel: Name5ViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Paused")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            Button(action: {
                viewModel.resumeTimer()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Resume")
                        .fontWeight(.bold)
                }
                .font(.title3)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue)
                )
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
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.15))
                )
            }
        }
    }
}
