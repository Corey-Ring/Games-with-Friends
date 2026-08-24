import SwiftUI

struct CompetitionHomeView: View {
    var viewModel: CompetitionVibeCheckViewModel
    @State private var showHowToPlay = false

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Whole scrolling column is interactive (steppers, score
                // pills, CTA) — motifs keep to the outer edges (§7).
                MotifGroundView(seed: 0x71BE_0C0C,
                                exclusions: [CGRect(x: 8, y: 8,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 16)])
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
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
                            .font(AppTheme.Retro.Typography.pillLabel)
                            .foregroundColor(AppTheme.Retro.panelText)
                            .retroLozenge()
                    }
                    .buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))
                    .padding(.top, AppTheme.Spacing.sm)
                    .padding(.bottom, AppTheme.Spacing.lg)
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showHowToPlay) {
            CompetitionHowToPlayView()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VibeCheckHeader(title: "Competition Mode",
                        subtitle: "Every player for themselves")
            .padding(.vertical)
    }

    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Players")
                .font(AppTheme.Retro.Typography.cardTitle)
                .foregroundColor(AppTheme.Retro.panelText)

            HStack {
                Button {
                    if viewModel.settings.playerCount > 2 {
                        viewModel.settings.playerCount -= 1
                    }
                } label: {
                    stepperGlyph("minus", enabled: viewModel.settings.playerCount > 2)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.settings.playerCount <= 2)

                Spacer()

                Text("\(viewModel.settings.playerCount)")
                    .font(AppTheme.Retro.Typography.heading(48, relativeTo: .largeTitle))
                    .monospacedDigit()
                    .foregroundColor(AppTheme.Retro.panelText)

                Spacer()

                Button {
                    if viewModel.settings.playerCount < 10 {
                        viewModel.settings.playerCount += 1
                    }
                } label: {
                    stepperGlyph("plus", enabled: viewModel.settings.playerCount < 10)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.settings.playerCount >= 10)
            }
            .padding(.horizontal)

            Text("Minimum 2 players")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.cocoa)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
    }

    private var targetScoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target Score")
                .font(AppTheme.Retro.Typography.cardTitle)
                .foregroundColor(AppTheme.Retro.panelText)

            // One game accent per screen (§3.2); flow layout so the four
            // Lilita pills wrap at large Dynamic Type sizes.
            FlowLayout(spacing: AppTheme.Spacing.sm) {
                ForEach([300, 500, 750, 1000], id: \.self) { score in
                    RetroCategoryPill(
                        title: "\(score)",
                        color: VibeCheckStyle.accent,
                        isSelected: viewModel.settings.targetScore == score
                    ) {
                        viewModel.settings.targetScore = score
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
    }

    private var continueButton: some View {
        RetroPrimaryButton(title: "Set Up Players", icon: "arrow.right",
                           accent: VibeCheckStyle.accent) {
            viewModel.proceedToPlayerSetup()
        }
    }

    private func stepperGlyph(_ systemImage: String, enabled: Bool) -> some View {
        Image(systemName: systemImage)
            .font(AppTheme.Typography.cardTitle.weight(.black))
            .foregroundColor(AppTheme.Retro.ink)
            .frame(width: 44, height: 44)
            .background(Circle().fill(enabled ? VibeCheckStyle.accent : AppTheme.Retro.panel))
            .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth))
            .opacity(enabled ? 1 : 0.4)
    }
}

// MARK: - Player Setup View

struct CompetitionPlayerSetupView: View {
    var viewModel: CompetitionVibeCheckViewModel

    var body: some View {
        ZStack {
            // Name entry: plain ground, no motifs behind the keyboard (§7).
            AppTheme.Retro.ground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header — framed Lilita title, never naked on the ground
                    // (Rule 4).
                    Text("Enter Player Names")
                        .font(AppTheme.Retro.Typography.heading(24, relativeTo: .title))
                        .foregroundColor(VibeCheckStyle.chipTextColor(on: VibeCheckStyle.accent))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .retroPanel(VibeCheckStyle.accent)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                                .fill(AppTheme.Retro.ink)
                                .offset(x: AppTheme.Retro.shadowOffset,
                                        y: AppTheme.Retro.shadowOffset)
                        )
                        .rotationEffect(.degrees(-1))

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
                        .padding(.bottom, AppTheme.Spacing.lg)
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
    }

    private var startButton: some View {
        RetroPrimaryButton(title: "Start Game", icon: "play.fill",
                           accent: VibeCheckStyle.accent) {
            viewModel.startGame()
        }
    }
}

struct PlayerNameCard: View {
    let playerIndex: Int
    let player: CompetitionPlayer
    var viewModel: CompetitionVibeCheckViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Player number badge — flat accent disc with an ink outline and
            // ink numeral (§2 rule 1, §8).
            ZStack {
                Circle().fill(VibeCheckStyle.accent)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth)

                Text("\(playerIndex + 1)")
                    .font(AppTheme.Retro.Typography.heading(17))
                    .foregroundColor(VibeCheckStyle.chipTextColor(on: VibeCheckStyle.accent))
            }
            .frame(width: 36, height: 36)

            TextField("Player \(playerIndex + 1)", text: Binding(
                get: { player.name },
                set: { viewModel.updatePlayerName(at: playerIndex, name: $0) }
            ))
            .textFieldStyle(.roundedBorder)
            .font(AppTheme.Typography.body)
            .tint(VibeCheckStyle.accent)
        }
        .retroCard()
    }
}

// MARK: - How To Play

struct CompetitionHowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { geo in
                    MotifGroundView(seed: 0x71BE_0C0E,
                                    exclusions: [CGRect(x: 8, y: 8,
                                                        width: geo.size.width - 16,
                                                        height: geo.size.height - 16)])
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        // Overview
                        section(title: "Overview", icon: "info.circle.fill") {
                            Text("Competition Mode is a free-for-all version of Vibe Check where every player competes individually. Pass the device around and try to match the Vibe Setter's target position!")
                        }

                        // Vibe Setter
                        section(title: "Vibe Setter", icon: "person.fill.questionmark") {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                Text("1. A random player becomes the Vibe Setter each round")
                                Text("2. They see the spectrum and target position")
                                Text("3. They create a prompt that matches the target")
                                Text("4. The Vibe Setter does NOT earn points")
                            }
                        }

                        // Guessing
                        section(title: "Guessing", icon: "hand.tap.fill") {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
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
                .scrollIndicators(.hidden)
            }
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Retro.ground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(AppTheme.Retro.Typography.pillLabel)
                        .tint(AppTheme.Retro.ink)
                }
            }
        }
    }

    private func section<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(AppTheme.Retro.Typography.cardTitle)
                .foregroundColor(AppTheme.Retro.panelText)

            content()
                .font(AppTheme.Typography.secondary)
                .foregroundColor(AppTheme.Retro.panelText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
    }

    private func scoringRow(_ zone: ScoringZone) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(VibeCheckStyle.zoneColor(zone))
                .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 2))
                .frame(width: 16, height: 16)

            Text("\(zone.points) points")
                .font(AppTheme.Retro.Typography.cardTitle)
                .foregroundColor(AppTheme.Retro.panelText)

            Text("(within \(Int(zone.threshold * 100))%)")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.cocoa)
        }
    }
}

#Preview {
    CompetitionHomeView(viewModel: CompetitionVibeCheckViewModel())
}
