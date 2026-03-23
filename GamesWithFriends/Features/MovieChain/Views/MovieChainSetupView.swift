import SwiftUI

/// Setup view for configuring Movie Chain game
struct MovieChainSetupView: View {
    @ObservedObject var viewModel: MovieChainViewModel
    @State private var playerCount: Int = 2
    @State private var showingPlayerNames = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
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
                    .padding(.bottom, AppTheme.Spacing.lg)
            }
            .padding(AppTheme.Spacing.md)
        }
        .scrollIndicators(.hidden)
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
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "film.stack")
                .font(.system(size: 60))
                .foregroundStyle(GameTheme.movieChain.accentColor)

            Text("Connect movies through actors!")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.mediumGray)
        }
        .padding(.top)
    }

    // MARK: - Decompression Progress Section

    private var decompressionProgressSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            GameSpinner(color: GameTheme.movieChain.accentColor)

            Text("Preparing Movie Database...")
                .font(AppTheme.Typography.cardTitle)
                .foregroundColor(AppTheme.deepCharcoal)

            ProgressView(value: viewModel.decompressionProgress)
                .progressViewStyle(.linear)
                .tint(GameTheme.movieChain.accentColor)
                .frame(maxWidth: 200)

            Text("\(Int(viewModel.decompressionProgress * 100))%")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.mediumGray)

            Text("This only happens once on first launch.")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.mediumGray)
                .multilineTextAlignment(.center)
        }
        .gameCard()
    }

    // MARK: - Database Error Section

    private var databaseErrorSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(AppTheme.Typography.hero)
                .foregroundStyle(.yellow)

            Text("Database Not Loaded")
                .font(AppTheme.Typography.cardTitle)
                .foregroundColor(AppTheme.deepCharcoal)

            if let error = viewModel.databaseError {
                Text(error)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.mediumGray)
                    .multilineTextAlignment(.center)
            }

            Text("The movie database needs to be added to the app bundle.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.mediumGray)
                .multilineTextAlignment(.center)
        }
        .gameCard()
    }

    // MARK: - Game Mode Section

    private var gameModeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Game Mode")
                .font(AppTheme.Typography.sectionHeader)
                .foregroundColor(AppTheme.deepCharcoal)

            ForEach(MovieChainGameMode.allCases) { mode in
                GameModeCard(
                    mode: mode,
                    isSelected: viewModel.gameMode == mode,
                    action: {
                        HapticManager.selection()
                        viewModel.gameMode = mode
                    }
                )
            }
        }
    }

    // MARK: - Player Count Section

    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Players")
                .font(AppTheme.Typography.sectionHeader)
                .foregroundColor(AppTheme.deepCharcoal)

            HStack {
                Text("\(playerCount) Players")
                    .font(AppTheme.Typography.sectionHeader)
                    .foregroundColor(AppTheme.deepCharcoal)

                Spacer()

                HStack(spacing: AppTheme.Spacing.md) {
                    Button {
                        if playerCount > 2 {
                            HapticManager.light()
                            playerCount -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(AppTheme.Typography.screenTitle)
                            .foregroundStyle(playerCount > 2 ? GameTheme.movieChain.accentColor : AppTheme.mediumGray)
                    }
                    .disabled(playerCount <= 2)

                    Button {
                        if playerCount < 8 {
                            HapticManager.light()
                            playerCount += 1
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(AppTheme.Typography.screenTitle)
                            .foregroundStyle(playerCount < 8 ? GameTheme.movieChain.accentColor : AppTheme.mediumGray)
                    }
                    .disabled(playerCount >= 8)
                }
            }
            .gameCard()
        }
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Timer")
                .font(AppTheme.Typography.sectionHeader)
                .foregroundColor(AppTheme.deepCharcoal)

            HStack {
                Text("\(viewModel.timerDuration) seconds per turn")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.deepCharcoal)

                Spacer()

                Picker("Timer", selection: $viewModel.timerDuration) {
                    ForEach(TimerDuration.allCases) { duration in
                        Text("\(duration.rawValue)s").tag(duration.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .tint(GameTheme.movieChain.accentColor)
            }
            .gameCard()
        }
    }

    // MARK: - Player Names Section

    private var playerNamesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Player Names")
                    .font(AppTheme.Typography.sectionHeader)
                    .foregroundColor(AppTheme.deepCharcoal)

                Spacer()

                Button {
                    withAnimation {
                        showingPlayerNames.toggle()
                    }
                } label: {
                    Image(systemName: showingPlayerNames ? "chevron.up" : "chevron.down")
                        .foregroundStyle(AppTheme.mediumGray)
                }
            }

            if showingPlayerNames {
                VStack(spacing: AppTheme.Spacing.sm) {
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
                .gameCard()
            }
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        PrimaryButton(title: "Start Game", icon: "play.fill") {
            viewModel.startGame()
        }
        .disabled(!viewModel.isDatabaseReady)
        .opacity(viewModel.isDatabaseReady ? 1.0 : 0.5)
        .padding(.top, AppTheme.Spacing.md)
    }
}

// MARK: - Game Mode Card

struct GameModeCard: View {
    let mode: MovieChainGameMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: mode.iconName)
                    .font(AppTheme.Typography.sectionHeader)
                    .foregroundStyle(isSelected ? .white : GameTheme.movieChain.accentColor)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(mode.name)
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundStyle(isSelected ? .white : AppTheme.deepCharcoal)

                    Text(mode.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : AppTheme.mediumGray)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(isSelected ? GameTheme.movieChain.accentColor : AppTheme.pureWhite)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            .shadow(color: AppTheme.Shadow.cardColor, radius: AppTheme.Shadow.cardRadius, x: AppTheme.Shadow.cardX, y: AppTheme.Shadow.cardY)
        }
        .buttonStyle(.plain)
        .pressable()
    }
}

#Preview {
    NavigationStack {
        MovieChainSetupView(viewModel: MovieChainViewModel())
    }
}
