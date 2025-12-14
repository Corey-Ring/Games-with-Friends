import SwiftUI

struct Name5GameView: View {
    @StateObject private var viewModel = Name5ViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
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
            .navigationTitle("Name 5")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }

                if viewModel.gamePhase != .setup {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive, action: {
                                viewModel.resetGame()
                            }) {
                                Label("New Game", systemImage: "arrow.counterclockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Game Over View
struct GameOverView: View {
    @ObservedObject var viewModel: Name5ViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Game Over!")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Great job playing!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                // Final Stats
                FinalStatsCard(stats: viewModel.stats)

                // Recent Rounds
                if !viewModel.roundResults.isEmpty {
                    RecentRoundsCard(results: viewModel.roundResults)
                }

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        viewModel.startGame()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Play Again")
                                .fontWeight(.bold)
                        }
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }

                    Button(action: {
                        viewModel.resetGame()
                    }) {
                        Text("Back to Setup")
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.gray.opacity(0.15))
                            )
                    }
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
    }
}

// MARK: - Final Stats Card
struct FinalStatsCard: View {
    let stats: GameStats

    var body: some View {
        VStack(spacing: 20) {
            Text("Final Stats")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                FinalStatItem(
                    icon: "target",
                    label: "Total Rounds",
                    value: "\(stats.roundsPlayed)",
                    color: .blue
                )

                FinalStatItem(
                    icon: "checkmark.circle.fill",
                    label: "Successful",
                    value: "\(stats.roundsWon)",
                    color: .green
                )

                FinalStatItem(
                    icon: "flame.fill",
                    label: "Best Streak",
                    value: "\(stats.bestStreak)",
                    color: .orange
                )

                FinalStatItem(
                    icon: "percent",
                    label: "Success Rate",
                    value: "\(Int(stats.successRate * 100))%",
                    color: .purple
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
    }
}

struct FinalStatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Recent Rounds Card
struct RecentRoundsCard: View {
    let results: [RoundResult]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Rounds")
                .font(.headline)

            ForEach(results.suffix(5).reversed()) { result in
                HStack {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.success ? .green : .orange)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.promptText)
                            .font(.subheadline)
                            .lineLimit(1)

                        if let time = result.timeUsed {
                            Text("\(time)s")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if let playerNum = result.playerNumber {
                        Text("P\(playerNum)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.gray.opacity(0.15))
                            )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}
