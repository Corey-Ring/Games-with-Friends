import SwiftUI

/// Setup view for configuring Movie Chain game
struct MovieChainSetupView: View {
    @ObservedObject var viewModel: MovieChainViewModel
    @State private var playerCount: Int = 2
    @State private var showingPlayerNames = false

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // The card column owns most of the screen; motifs keep to the
                // gutters and the nav strip (§7 — generator adds clearance).
                MotifGroundView(seed: 0xF11_A0501,
                                exclusions: [CGRect(x: 8, y: 60,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 60)])
            }
            .ignoresSafeArea()

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
        VStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle().fill(AppTheme.Retro.panel)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                RetroSpotIllustration(kind: .filmFrame)
                    .frame(width: 64, height: 64)
            }
            .frame(width: 84, height: 84)

            Text("Movie Chain")
                .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                .foregroundColor(AppTheme.Retro.ink)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .retroPanel(MovieChainStyle.accent)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                        .fill(AppTheme.Retro.ink)
                        .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
                )
                .rotationEffect(.degrees(-1))

            Text("Connect movies through actors!")
                .font(AppTheme.Typography.secondary)
                .foregroundColor(AppTheme.Retro.panelText)
                .retroLozenge()
                .rotationEffect(.degrees(0.8))
        }
        .padding(.top)
    }

    // MARK: - Decompression Progress Section

    private var decompressionProgressSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            GameSpinner(color: MovieChainStyle.accent)

            Text("Preparing Movie Database...")
                .font(AppTheme.Retro.Typography.cardTitle)
                .foregroundColor(AppTheme.Retro.panelText)

            ProgressView(value: viewModel.decompressionProgress)
                .progressViewStyle(.linear)
                .tint(MovieChainStyle.accent)
                .frame(maxWidth: 200)

            Text("\(Int(viewModel.decompressionProgress * 100))%")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))

            Text("This only happens once on first launch.")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .retroCard()
    }

    // MARK: - Database Error Section

    private var databaseErrorSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ChainNodeDisc(systemImage: "exclamationmark.triangle.fill",
                          color: AppTheme.Retro.tangerine,
                          diameter: 56)

            Text("Database Not Loaded")
                .font(AppTheme.Retro.Typography.cardTitle)
                .foregroundColor(AppTheme.Retro.panelText)

            if let error = viewModel.databaseError {
                Text(error)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            Text("The movie database needs to be added to the app bundle.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Retro.panelText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .retroCard()
    }

    // MARK: - Game Mode Section

    private var gameModeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionLabel("Game Mode")

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
            sectionLabel("Players")

            HStack {
                Text("\(playerCount) Players")
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText)

                Spacer()

                HStack(spacing: AppTheme.Spacing.md) {
                    stepperButton(systemName: "minus", enabled: playerCount > 2) {
                        if playerCount > 2 {
                            HapticManager.light()
                            playerCount -= 1
                        }
                    }
                    .disabled(playerCount <= 2)

                    stepperButton(systemName: "plus", enabled: playerCount < 8) {
                        if playerCount < 8 {
                            HapticManager.light()
                            playerCount += 1
                        }
                    }
                    .disabled(playerCount >= 8)
                }
            }
            .retroCard()
        }
    }

    private func stepperButton(systemName: String, enabled: Bool,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.Retro.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(enabled ? MovieChainStyle.accent : AppTheme.Retro.panel))
                .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth))
        }
        .opacity(enabled ? 1 : 0.35)
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionLabel("Timer")

            HStack {
                Text("\(viewModel.timerDuration) seconds per turn")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Retro.panelText)

                Spacer()

                Picker("Timer", selection: $viewModel.timerDuration) {
                    ForEach(TimerDuration.allCases) { duration in
                        Text("\(duration.rawValue)s").tag(duration.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppTheme.Retro.ink)
            }
            .retroCard()
        }
    }

    // MARK: - Player Names Section

    private var playerNamesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                sectionLabel("Player Names")

                Spacer()

                Button {
                    withAnimation {
                        showingPlayerNames.toggle()
                    }
                } label: {
                    Image(systemName: showingPlayerNames ? "chevron.up" : "chevron.down")
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.Retro.ink)
                }
            }

            if showingPlayerNames {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, player in
                        HStack {
                            Circle()
                                .fill(player.color)
                                .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                                .frame(width: 24, height: 24)

                            TextField("Player \(index + 1)", text: Binding(
                                get: { player.name },
                                set: { viewModel.updatePlayerName(at: index, to: $0) }
                            ))
                            .textFieldStyle(.plain)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Retro.panelText)
                            .padding(AppTheme.Spacing.sm)
                            .retroPanel(AppTheme.Retro.panel,
                                        cornerRadius: AppTheme.Retro.Radius.inner)
                        }
                    }
                }
                .retroCard()
            }
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
            .foregroundColor(AppTheme.Retro.panelText)
            .retroLozenge()
    }

    // MARK: - Start Button

    private var startButton: some View {
        RetroPrimaryButton(title: "Start Game", icon: "play.fill",
                           accent: MovieChainStyle.accent) {
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
                    .foregroundStyle(isSelected ? AppTheme.Retro.ink : AppTheme.Retro.panelText)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(mode.name)
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .foregroundStyle(isSelected ? AppTheme.Retro.ink : AppTheme.Retro.panelText)

                    Text(mode.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(isSelected ? AppTheme.Retro.ink.opacity(0.8)
                                                    : AppTheme.Retro.panelText.opacity(0.7))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.Retro.ink)
                }
            }
            .padding(AppTheme.Spacing.md)
            // Selected mode fills with the accent; unselected stays a cream
            // panel — same selection language as RetroCategoryPill (§5).
            .retroPanel(isSelected ? MovieChainStyle.accent : AppTheme.Retro.panel)
        }
        .buttonStyle(RetroRaisedButtonStyle())
    }
}

#Preview {
    NavigationStack {
        MovieChainSetupView(viewModel: MovieChainViewModel())
    }
}
