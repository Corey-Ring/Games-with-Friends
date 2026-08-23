import SwiftUI

/// Setup view for configuring Casting Director game
struct CastingDirectorSetupView: View {
    @ObservedObject var viewModel: CastingDirectorViewModel
    @State private var playerCount: Int = 2
    @State private var showingPlayerNames = false

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Card column owns the screen; motifs keep to the gutters and
                // the nav strip (§7 — the generator adds the clearance).
                MotifGroundView(seed: 0xCA57_0D01,
                                exclusions: [CGRect(x: 8, y: 60,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 60)])
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    headerSection

                    if viewModel.isDatabaseDecompressing {
                        decompressionSection
                    } else if !viewModel.isDatabaseReady {
                        databaseErrorSection
                    }

                    gameModeSection
                    difficultySection
                    eraSection

                    if viewModel.gameMode == .passAndPlay {
                        playerCountSection
                        playerNamesSection
                    }

                    roundsSection
                    startButton
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Casting Director")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: playerCount) { _, newValue in
            viewModel.setPlayerCount(newValue)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle().fill(AppTheme.Retro.panel)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                RetroSpotIllustration(kind: .starFace)
                    .frame(width: 64, height: 64)
            }
            .frame(width: 84, height: 84)

            Text("Casting Director")
                .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                .foregroundColor(AppTheme.Retro.ink)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .retroPanel(CastingDirectorStyle.accent)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                        .fill(AppTheme.Retro.ink)
                        .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
                )
                .rotationEffect(.degrees(-1))

            Text("Guess the actor from clues!")
                .font(AppTheme.Typography.secondary)
                .foregroundColor(AppTheme.Retro.panelText)
                .retroLozenge()
                .rotationEffect(.degrees(0.8))
        }
        .padding(.top)
    }

    // MARK: - Decompression

    private var decompressionSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            GameSpinner(color: CastingDirectorStyle.accent)

            Text("Preparing Movie Database...")
                .font(AppTheme.Retro.Typography.cardTitle)
                .foregroundColor(AppTheme.Retro.panelText)

            ProgressView(value: viewModel.decompressionProgress)
                .progressViewStyle(.linear)
                .tint(CastingDirectorStyle.accent)
                .frame(maxWidth: 200)

            Text("\(Int(viewModel.decompressionProgress * 100))%")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))

            Text("This only happens once on first launch.")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .retroCard()
    }

    // MARK: - Database Error

    private var databaseErrorSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle().fill(CastingDirectorStyle.warningColor)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppTheme.Retro.ink)
            }
            .frame(width: 56, height: 56)

            Text("Database Not Loaded")
                .font(AppTheme.Retro.Typography.cardTitle)
                .foregroundColor(AppTheme.Retro.panelText)

            if let error = viewModel.databaseError {
                Text(error)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .retroCard()
    }

    // MARK: - Game Mode

    private var gameModeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionLabel("Game Mode")

            ForEach(CastingDirectorMode.allCases, id: \.rawValue) { mode in
                Button {
                    viewModel.gameMode = mode
                } label: {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: mode == .solo ? "person.fill" : "person.3.fill")
                            .font(AppTheme.Typography.sectionHeader)
                            .foregroundStyle(viewModel.gameMode == mode ? AppTheme.Retro.ink : AppTheme.Retro.panelText)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(mode.rawValue)
                                .font(AppTheme.Retro.Typography.cardTitle)
                                .foregroundStyle(viewModel.gameMode == mode ? AppTheme.Retro.ink : AppTheme.Retro.panelText)

                            Text(mode.description)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(viewModel.gameMode == mode
                                                 ? AppTheme.Retro.ink.opacity(0.8)
                                                 : AppTheme.Retro.panelText.opacity(0.7))
                        }

                        Spacer()

                        if viewModel.gameMode == mode {
                            Image(systemName: "checkmark.circle.fill")
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.Retro.ink)
                        }
                    }
                    .padding()
                    // Same selection language as the Movie Chain mode cards:
                    // accent fill when chosen, cream panel otherwise (§5).
                    .retroPanel(viewModel.gameMode == mode ? CastingDirectorStyle.accent : AppTheme.Retro.panel)
                }
                .buttonStyle(RetroRaisedButtonStyle())
            }
        }
    }

    // MARK: - Difficulty

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionLabel("Difficulty")

            HStack(spacing: AppTheme.Spacing.md) {
                ForEach(CastingDirectorDifficulty.allCases, id: \.rawValue) { diff in
                    Button {
                        viewModel.difficulty = diff
                    } label: {
                        VStack(spacing: 6) {
                            Text(diff.rawValue)
                                .font(AppTheme.Retro.Typography.cardTitle)
                                .foregroundStyle(viewModel.difficulty == diff ? AppTheme.Retro.ink : AppTheme.Retro.panelText)

                            Text("\(Int(diff.clueInterval))s per clue")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(viewModel.difficulty == diff
                                                 ? AppTheme.Retro.ink.opacity(0.8)
                                                 : AppTheme.Retro.panelText.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .retroPanel(viewModel.difficulty == diff ? CastingDirectorStyle.accent : AppTheme.Retro.panel,
                                    cornerRadius: AppTheme.Retro.Radius.inner)
                    }
                    .buttonStyle(RetroRaisedButtonStyle(cornerRadius: AppTheme.Retro.Radius.inner))
                }
            }
        }
    }

    // MARK: - Era

    private var eraSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionLabel("Era")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(CastingDirectorEra.allCases, id: \.rawValue) { era in
                        Button {
                            viewModel.era = era
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: era.icon)
                                    .font(AppTheme.Typography.sectionHeader)
                                    .foregroundStyle(viewModel.era == era ? AppTheme.Retro.ink : AppTheme.Retro.panelText)

                                Text(era.rawValue)
                                    .font(AppTheme.Retro.Typography.pillLabel)
                                    .foregroundStyle(viewModel.era == era ? AppTheme.Retro.ink : AppTheme.Retro.panelText)
                            }
                            .frame(width: 80)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .retroPanel(viewModel.era == era ? CastingDirectorStyle.accent : AppTheme.Retro.panel,
                                        cornerRadius: AppTheme.Retro.Radius.inner)
                        }
                        .buttonStyle(RetroRaisedButtonStyle(cornerRadius: AppTheme.Retro.Radius.inner))
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xs)
                .padding(.vertical, AppTheme.Retro.shadowOffset + 1)
            }

            Text(viewModel.era.subtitle)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.panelText)
                .retroLozenge()
        }
    }

    // MARK: - Player Count

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
                        if playerCount > 2 { playerCount -= 1 }
                    }
                    .disabled(playerCount <= 2)

                    stepperButton(systemName: "plus", enabled: playerCount < 8) {
                        if playerCount < 8 { playerCount += 1 }
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
                .background(Circle().fill(enabled ? CastingDirectorStyle.accent : AppTheme.Retro.panel))
                .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth))
        }
        .opacity(enabled ? 1 : 0.35)
    }

    // MARK: - Player Names

    private var playerNamesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                sectionLabel("Player Names")

                Spacer()

                Button {
                    withAnimation { showingPlayerNames.toggle() }
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

    // MARK: - Rounds

    private var roundsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionLabel("Rounds")

            HStack {
                Text("\(viewModel.numberOfRounds) rounds")
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText)

                Spacer()

                // Keep the system control, tint it (§3 recipe).
                Picker("Rounds", selection: $viewModel.numberOfRounds) {
                    Text("3").tag(3)
                    Text("5").tag(5)
                    Text("10").tag(10)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            .retroCard()
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
                           accent: CastingDirectorStyle.accent) {
            viewModel.startGame()
        }
        .disabled(!viewModel.isDatabaseReady)
        .opacity(viewModel.isDatabaseReady ? 1.0 : 0.6)
        .padding(.top)
    }
}
