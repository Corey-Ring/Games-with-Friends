import SwiftUI

/// Setup view for configuring Casting Director game
struct CastingDirectorSetupView: View {
    @ObservedObject var viewModel: CastingDirectorViewModel
    @State private var playerCount: Int = 2
    @State private var showingPlayerNames = false

    var body: some View {
        ZStack {
            WarmLinenBackground()

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
            Image(systemName: "person.crop.rectangle.stack")
                .font(.system(size: 60))
                .foregroundStyle(GameTheme.castingDirector.accentColor)

            Text("Guess the actor from clues!")
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(AppTheme.mediumGray)
        }
        .padding(.top)
    }

    // MARK: - Decompression

    private var decompressionSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            GameSpinner(color: GameTheme.castingDirector.accentColor)

            Text("Preparing Movie Database...")
                .font(AppTheme.Typography.cardTitle)

            ProgressView(value: viewModel.decompressionProgress)
                .progressViewStyle(.linear)
                .tint(GameTheme.castingDirector.accentColor)
                .frame(maxWidth: 200)

            Text("\(Int(viewModel.decompressionProgress * 100))%")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.mediumGray)

            Text("This only happens once on first launch.")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.mediumGray)
        }
        .gameCard()
    }

    // MARK: - Database Error

    private var databaseErrorSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(AppTheme.Typography.hero)
                .foregroundStyle(.yellow)

            Text("Database Not Loaded")
                .font(AppTheme.Typography.cardTitle)

            if let error = viewModel.databaseError {
                Text(error)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.mediumGray)
                    .multilineTextAlignment(.center)
            }
        }
        .gameCard()
    }

    // MARK: - Game Mode

    private var gameModeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Game Mode")
                .font(AppTheme.Typography.cardTitle)

            ForEach(CastingDirectorMode.allCases, id: \.rawValue) { mode in
                Button {
                    viewModel.gameMode = mode
                } label: {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: mode == .solo ? "person.fill" : "person.3.fill")
                            .font(AppTheme.Typography.sectionHeader)
                            .foregroundStyle(viewModel.gameMode == mode ? .white : GameTheme.castingDirector.accentColor)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(mode.rawValue)
                                .font(AppTheme.Typography.cardTitle)
                                .foregroundStyle(viewModel.gameMode == mode ? .white : AppTheme.deepCharcoal)

                            Text(mode.description)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(viewModel.gameMode == mode ? .white.opacity(0.8) : AppTheme.mediumGray)
                        }

                        Spacer()

                        if viewModel.gameMode == mode {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white)
                        }
                    }
                    .padding()
                    .background(viewModel.gameMode == mode ? GameTheme.castingDirector.accentColor : AppTheme.pureWhite)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .stroke(viewModel.gameMode == mode ? Color.clear : AppTheme.mediumGray.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: viewModel.gameMode == mode ? Color.black.opacity(0.1) : Color.clear, radius: 4, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Difficulty

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Difficulty")
                .font(AppTheme.Typography.cardTitle)

            HStack(spacing: AppTheme.Spacing.md) {
                ForEach(CastingDirectorDifficulty.allCases, id: \.rawValue) { diff in
                    Button {
                        viewModel.difficulty = diff
                    } label: {
                        VStack(spacing: 6) {
                            Text(diff.rawValue)
                                .font(AppTheme.Typography.cardTitle)
                                .foregroundStyle(viewModel.difficulty == diff ? .white : AppTheme.deepCharcoal)

                            Text("\(Int(diff.clueInterval))s per clue")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(viewModel.difficulty == diff ? .white.opacity(0.8) : AppTheme.mediumGray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(viewModel.difficulty == diff ? GameTheme.castingDirector.accentColor : AppTheme.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(viewModel.difficulty == diff ? Color.clear : AppTheme.mediumGray.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: viewModel.difficulty == diff ? Color.black.opacity(0.1) : Color.clear, radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Era
    
    private var eraSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Era")
                .font(AppTheme.Typography.cardTitle)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(CastingDirectorEra.allCases, id: \.rawValue) { era in
                        Button {
                            viewModel.era = era
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: era.icon)
                                    .font(AppTheme.Typography.sectionHeader)
                                    .foregroundStyle(viewModel.era == era ? .white : GameTheme.castingDirector.accentColor)
                                
                                Text(era.rawValue)
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(viewModel.era == era ? .white : AppTheme.deepCharcoal)
                            }
                            .frame(width: 80)
                            .padding(.vertical, 12)
                            .background(viewModel.era == era ? GameTheme.castingDirector.accentColor : AppTheme.pureWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(viewModel.era == era ? Color.clear : AppTheme.mediumGray.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: viewModel.era == era ? Color.black.opacity(0.1) : Color.clear, radius: 4, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xs)
            }
        }
    }

    // MARK: - Player Count

    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Players")
                .font(AppTheme.Typography.cardTitle)

            HStack {
                Text("\(playerCount) Players")
                    .font(AppTheme.Typography.sectionHeader)
                    .fontWeight(.semibold)

                Spacer()

                HStack(spacing: AppTheme.Spacing.md) {
                    Button {
                        if playerCount > 2 { playerCount -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(AppTheme.Typography.screenTitle)
                            .foregroundStyle(playerCount > 2 ? GameTheme.castingDirector.accentColor : AppTheme.mediumGray)
                    }
                    .disabled(playerCount <= 2)

                    Button {
                        if playerCount < 8 { playerCount += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(AppTheme.Typography.screenTitle)
                            .foregroundStyle(playerCount < 8 ? GameTheme.castingDirector.accentColor : AppTheme.mediumGray)
                    }
                    .disabled(playerCount >= 8)
                }
            }
            .gameCard()
        }
    }

    // MARK: - Player Names

    private var playerNamesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Player Names")
                    .font(AppTheme.Typography.cardTitle)

                Spacer()

                Button {
                    withAnimation { showingPlayerNames.toggle() }
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

    // MARK: - Rounds

    private var roundsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Rounds")
                .font(AppTheme.Typography.cardTitle)

            HStack {
                Text("\(viewModel.numberOfRounds) rounds")
                    .font(AppTheme.Typography.subsectionHeader)

                Spacer()

                Picker("Rounds", selection: $viewModel.numberOfRounds) {
                    Text("3").tag(3)
                    Text("5").tag(5)
                    Text("10").tag(10)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            .gameCard()
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        PrimaryButton(title: "Start Game", icon: "play.fill") {
            viewModel.startGame()
        }
        .disabled(!viewModel.isDatabaseReady)
        .opacity(viewModel.isDatabaseReady ? 1.0 : 0.6)
        .padding(.top)
    }
}
