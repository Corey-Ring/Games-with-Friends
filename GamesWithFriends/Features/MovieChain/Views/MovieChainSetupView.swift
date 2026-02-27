import SwiftUI

/// Setup view for configuring Movie Chain game
struct MovieChainSetupView: View {
    @ObservedObject var viewModel: MovieChainViewModel
    @State private var playerCount: Int = 2
    @State private var showingPlayerNames = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.red.opacity(0.3), Color.orange.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Database status
                    if viewModel.isDatabaseDecompressing {
                        decompressionProgressSection
                    } else if !viewModel.isDatabaseReady {
                        databaseErrorSection
                    }

                    // Game Mode Selection
                    gameModeSection

                    // Player Count
                    playerCountSection

                    // Timer Duration (for timed mode)
                    if viewModel.gameMode.hasTimer {
                        timerSection
                    }

                    // Player Names
                    playerNamesSection

                    // Start Button
                    startButton
                        .padding(.bottom, 20)
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Movie Chain")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: playerCount) { _, newValue in
            viewModel.setPlayerCount(newValue)
        }
        .onChange(of: viewModel.gameMode) { _, _ in
            viewModel.setPlayerCount(playerCount)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "film.stack")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            Text("Connect movies through actors!")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.top)
    }

    // MARK: - Decompression Progress Section

    private var decompressionProgressSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Preparing Movie Database...")
                .font(.headline)

            ProgressView(value: viewModel.decompressionProgress)
                .progressViewStyle(.linear)
                .frame(maxWidth: 200)

            Text("\(Int(viewModel.decompressionProgress * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("This only happens once on first launch.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Database Error Section

    private var databaseErrorSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)

            Text("Database Not Loaded")
                .font(.headline)

            if let error = viewModel.databaseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("The movie database needs to be added to the app bundle.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Game Mode Section

    private var gameModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Mode")
                .font(.headline)

            ForEach(MovieChainGameMode.allCases) { mode in
                GameModeCard(
                    mode: mode,
                    isSelected: viewModel.gameMode == mode,
                    action: { viewModel.gameMode = mode }
                )
            }
        }
    }

    // MARK: - Player Count Section

    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Players")
                .font(.headline)

            HStack {
                Text("\(playerCount) Players")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                HStack(spacing: 16) {
                    Button {
                        if playerCount > 2 {
                            playerCount -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundStyle(playerCount > 2 ? .red : .gray)
                    }
                    .disabled(playerCount <= 2)

                    Button {
                        if playerCount < 8 {
                            playerCount += 1
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(playerCount < 8 ? .red : .gray)
                    }
                    .disabled(playerCount >= 8)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timer")
                .font(.headline)

            HStack {
                Text("\(viewModel.timerDuration) seconds per turn")
                    .font(.title3)

                Spacer()

                Picker("Timer", selection: $viewModel.timerDuration) {
                    ForEach(TimerDuration.allCases) { duration in
                        Text("\(duration.rawValue)s").tag(duration.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Player Names Section

    private var playerNamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Player Names")
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation {
                        showingPlayerNames.toggle()
                    }
                } label: {
                    Image(systemName: showingPlayerNames ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }

            if showingPlayerNames {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, player in
                        HStack {
                            Circle()
                                .fill(player.color)
                                .frame(width: 24, height: 24)

                            TextField("Player \(index + 1)", text: Binding(
                                get: { player.name },
                                set: { viewModel.updatePlayerName(at: index, to: $0) }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            viewModel.startGame()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Game")
            }
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isDatabaseReady ? Color.red : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!viewModel.isDatabaseReady)
        .padding(.top)
    }
}

// MARK: - Game Mode Card

struct GameModeCard: View {
    let mode: MovieChainGameMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: mode.iconName)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .red)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.name)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)

                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.red : Color.clear)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MovieChainSetupView(viewModel: MovieChainViewModel())
    }
}
