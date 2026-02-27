import SwiftUI

struct CompetitionHomeView: View {
    var viewModel: CompetitionVibeCheckViewModel
    @State private var showHowToPlay = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Player count
                playerCountSection

                // Target score
                targetScoreSection

                // Continue button
                continueButton

                // How to play
                Button {
                    showHowToPlay = true
                } label: {
                    Label("How to Play", systemImage: "book.fill")
                        .font(.subheadline)
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background {
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.red.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showHowToPlay) {
            CompetitionHowToPlayView()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("COMPETITION MODE")
                .font(.largeTitle.weight(.bold))

            Text("Every player for themselves!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical)
    }

    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Players", systemImage: "person.fill")
                .font(.headline)

            HStack {
                Button {
                    if viewModel.settings.playerCount > 2 {
                        viewModel.settings.playerCount -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.settings.playerCount > 2 ? .primary : .secondary)
                }
                .disabled(viewModel.settings.playerCount <= 2)

                Spacer()

                Text("\(viewModel.settings.playerCount)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Spacer()

                Button {
                    if viewModel.settings.playerCount < 10 {
                        viewModel.settings.playerCount += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.settings.playerCount < 10 ? .primary : .secondary)
                }
                .disabled(viewModel.settings.playerCount >= 10)
            }
            .padding(.horizontal)

            Text("Minimum 2 players")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }

    private var targetScoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Target Score", systemImage: "flag.checkered")
                .font(.headline)

            HStack(spacing: 16) {
                ForEach([300, 500, 750, 1000], id: \.self) { score in
                    Button {
                        viewModel.settings.targetScore = score
                    } label: {
                        Text("\(score)")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(viewModel.settings.targetScore == score ? Color.orange : Color(.systemGray5))
                            }
                            .foregroundStyle(viewModel.settings.targetScore == score ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }

    private var continueButton: some View {
        Button {
            viewModel.proceedToPlayerSetup()
        } label: {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                Text("SET UP PLAYERS")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background {
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Player Setup View

struct CompetitionPlayerSetupView: View {
    var viewModel: CompetitionVibeCheckViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                Text("Enter Player Names")
                    .font(.title.weight(.bold))

                // Player name fields
                ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, player in
                    PlayerNameCard(
                        playerIndex: index,
                        player: player,
                        viewModel: viewModel
                    )
                }

                // Start button
                startButton
                    .padding(.bottom, 20)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background {
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.red.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private var startButton: some View {
        Button {
            viewModel.startGame()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("START GAME")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background {
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct PlayerNameCard: View {
    let playerIndex: Int
    let player: CompetitionPlayer
    var viewModel: CompetitionVibeCheckViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Player number badge
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 36, height: 36)

                Text("\(playerIndex + 1)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }

            TextField("Player \(playerIndex + 1)", text: Binding(
                get: { player.name },
                set: { viewModel.updatePlayerName(at: playerIndex, name: $0) }
            ))
            .textFieldStyle(.roundedBorder)
            .font(.body)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }
}

// MARK: - How To Play

struct CompetitionHowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Overview
                    section(title: "Overview", icon: "info.circle.fill") {
                        Text("Competition Mode is a free-for-all version of Vibe Check where every player competes individually. Pass the device around and try to match the Vibe Setter's target position!")
                    }

                    // Vibe Setter
                    section(title: "Vibe Setter", icon: "person.fill.questionmark") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. A random player becomes the Vibe Setter each round")
                            Text("2. They see the spectrum and target position")
                            Text("3. They create a prompt that matches the target")
                            Text("4. The Vibe Setter does NOT earn points")
                        }
                    }

                    // Guessing
                    section(title: "Guessing", icon: "hand.tap.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Each player takes a turn with the device")
                            Text("2. See the spectrum and prompt")
                            Text("3. Slide to where YOU think it belongs")
                            Text("4. Pass to the next player (no peeking!)")
                        }
                    }

                    // Scoring
                    section(title: "Scoring Zones", icon: "target") {
                        VStack(alignment: .leading, spacing: 12) {
                            scoringRow(.perfect)
                            scoringRow(.great)
                            scoringRow(.good)
                            scoringRow(.okay)
                            scoringRow(.miss)
                        }
                    }

                    // Winning
                    section(title: "Winning", icon: "trophy.fill") {
                        Text("First player to reach the target score wins! The player with the worst guess each round gets a fun tease.")
                    }
                }
                .padding()
            }
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func section<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.orange)

            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        }
    }

    private func scoringRow(_ zone: ScoringZone) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(zone.color)
                .frame(width: 16, height: 16)

            Text("\(zone.points) points")
                .font(.subheadline.weight(.medium))

            Text("(within \(Int(zone.threshold * 100))%)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    CompetitionHomeView(viewModel: CompetitionVibeCheckViewModel())
}
