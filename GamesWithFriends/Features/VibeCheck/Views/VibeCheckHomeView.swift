import SwiftUI

struct VibeCheckHomeView: View {
    var viewModel: CompetitionVibeCheckViewModel
    @State private var showHowToPlay = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.md) {
                // Compact header with back button
                compactHeaderRow

                // Classic mode is hidden for 1.0 (see DECISIONS.md) — no mode picker;
                // the flow is Competition only.
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
                        .font(AppTheme.Typography.secondary)
                        .foregroundStyle(GameTheme.vibeCheck.accentColor)
                }
                .padding(.top, AppTheme.Spacing.sm)
                .padding(.bottom, AppTheme.Spacing.lg)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background {
            LinearGradient(
                colors: [GameTheme.vibeCheck.accentColor.opacity(0.1), GameTheme.vibeCheck.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showHowToPlay) {
            HowToPlayView(gameMode: .competition)
        }
    }

    // MARK: - Sections

    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Label("Players", systemImage: "person.fill")
                .font(AppTheme.Typography.cardTitle)

            HStack {
                Button {
                    if viewModel.settings.playerCount > 2 {
                        viewModel.settings.playerCount -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(AppTheme.Typography.sectionHeader)
                        .foregroundStyle(viewModel.settings.playerCount > 2 ? GameTheme.vibeCheck.accentColor : AppTheme.mediumGray)
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
                        .font(AppTheme.Typography.sectionHeader)
                        .foregroundStyle(viewModel.settings.playerCount < 10 ? GameTheme.vibeCheck.accentColor : AppTheme.mediumGray)
                }
                .disabled(viewModel.settings.playerCount >= 10)
            }
            .padding(.horizontal)

            Text("Minimum 2 players")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .gameCard()
    }

    private var compactHeaderRow: some View {
        HStack(alignment: .center) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.cardSurface)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.Shadow.cardColor, radius: AppTheme.Shadow.cardRadius, x: AppTheme.Shadow.cardX, y: AppTheme.Shadow.cardY)
            }

            Spacer()

            VStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 24))
                    .foregroundStyle(GameTheme.vibeCheck.accentColor)

                Text("Vibe Check")
                    .font(AppTheme.Typography.sectionHeader)
            }

            Spacer()

            // Balance spacer — keeps title visually centered
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.top, AppTheme.Spacing.xs)
    }

    private var targetScoreSection: some View {
        let currentScore = viewModel.settings.targetScore

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Label("Target Score", systemImage: "flag.checkered")
                .font(AppTheme.Typography.cardTitle)

            HStack(spacing: AppTheme.Spacing.md) {
                ForEach([300, 500, 750, 1000], id: \.self) { score in
                    Button {
                        viewModel.settings.targetScore = score
                    } label: {
                        Text("\(score)")
                            .font(AppTheme.Typography.secondary.weight(.medium))
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background {
                                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                    .fill(currentScore == score
                                          ? GameTheme.vibeCheck.accentColor
                                          : AppTheme.elevatedSurface)
                            }
                            .foregroundStyle(currentScore == score ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gameCard()
    }

    private var continueButton: some View {
        Button {
            viewModel.proceedToPlayerSetup()
        } label: {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                Text("Set Up Players")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(GameTheme.vibeCheck.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
        .buttonStyle(.plain)
    }
}

// Classic-mode setup UI (mode picker, team setup) was removed for 1.0 —
// restore from git history when Classic returns. See DECISIONS.md.

// MARK: - How To Play

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    var gameMode: VibeCheckGameMode = .competition

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    // Overview
                    section(title: "Overview", icon: "info.circle.fill") {
                        if gameMode == .classic {
                            Text("A spectrum with polar opposites is shown (e.g., Trashy ↔ Classy). One player sees a target position and creates a prompt that matches it. The team then tries to guess where the prompt falls on the spectrum.")
                        } else {
                            Text("Competition Mode is a free-for-all version where every player competes individually. Pass the device around and try to match the Vibe Setter's target position!")
                        }
                    }

                    // Vibe Setter
                    section(title: "Vibe Setter", icon: "person.fill.questionmark") {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            if gameMode == .competition {
                                Text("1. A random player becomes the Vibe Setter each round")
                            }
                            Text(gameMode == .competition ? "2. They see the spectrum and target position" : "1. See the spectrum and target position")
                            Text(gameMode == .competition ? "3. They create a prompt that matches the target" : "2. Think of something that matches that position")
                            Text(gameMode == .competition ? "4. The Vibe Setter does NOT earn points" : "3. Example: Target is near 'Trashy' → 'Clipping your nails in a movie theater'")
                        }
                    }

                    // Guessing
                    section(title: gameMode == .classic ? "Guessing Team" : "Guessing", icon: "hand.tap.fill") {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            if gameMode == .classic {
                                Text("1. See the spectrum and the prompt")
                                Text("2. Discuss as a team")
                                Text("3. Slide to where you think it belongs")
                                Text("4. Lock in your guess!")
                            } else {
                                Text("1. Each player takes a turn with the device")
                                Text("2. See the spectrum and prompt")
                                Text("3. Slide to where YOU think it belongs")
                                Text("4. Pass to the next player (no peeking!)")
                            }
                        }
                    }

                    // Scoring
                    section(title: "Scoring Zones", icon: "target") {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            scoringRow(.perfect)
                            scoringRow(.great)
                            scoringRow(.good)
                            scoringRow(.okay)
                            scoringRow(.miss)
                        }
                    }

                    // Winning (competition mode only)
                    if gameMode == .competition {
                        section(title: "Winning", icon: "trophy.fill") {
                            Text("First player to reach the target score wins! The player with the worst guess each round gets a fun tease.")
                        }
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Label(title, systemImage: icon)
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(GameTheme.vibeCheck.accentColor)

            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(colorScheme == .dark ? AppTheme.darkCard : AppTheme.warmLinen)
        }
    }

    private func scoringRow(_ zone: ScoringZone) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(zone.color)
                .frame(width: 16, height: 16)

            Text("\(zone.points) points")
                .font(AppTheme.Typography.secondary.weight(.medium))

            Text("(within \(Int(zone.threshold * 100))%)")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VibeCheckHomeView(viewModel: CompetitionVibeCheckViewModel())
}
