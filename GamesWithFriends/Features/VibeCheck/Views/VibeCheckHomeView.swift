import SwiftUI

struct VibeCheckHomeView: View {
    var viewModel: CompetitionVibeCheckViewModel
    @State private var showHowToPlay = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // The whole scrolling column is interactive (steppers, score
                // pills, CTA), so motifs keep to the outer edges (§7 — the
                // generator adds the 12pt clearance itself).
                MotifGroundView(seed: 0x71BE_0C01,
                                exclusions: [CGRect(x: 8, y: 56,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 56)])
            }
            .ignoresSafeArea()

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
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showHowToPlay) {
            HowToPlayView(gameMode: .competition)
        }
    }

    // MARK: - Sections

    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
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

    private var compactHeaderRow: some View {
        HStack(alignment: .center) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(AppTheme.Typography.cardTitle.weight(.bold))
                    .foregroundColor(AppTheme.Retro.panelText)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(AppTheme.Retro.panel))
                    .overlay(Circle().stroke(AppTheme.Retro.ink,
                                             lineWidth: AppTheme.Retro.strokeWidth))
            }
            .buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))

            Spacer()

            // Spot plate + framed Lilita title (Rule 4 — the game name never
            // sits naked on the ground; Shrikhand is reserved for the app
            // lockup, §4).
            VibeCheckHeader(title: "Vibe Check", plateDiameter: 64, titleSize: 20)

            Spacer()

            // Balance spacer — keeps title visually centered
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.top, AppTheme.Spacing.xs)
    }

    private var targetScoreSection: some View {
        let currentScore = viewModel.settings.targetScore

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Target Score")
                .font(AppTheme.Retro.Typography.cardTitle)
                .foregroundColor(AppTheme.Retro.panelText)

            // Selection pills wear the one screen accent (§3 recipe). Flow
            // layout so four chunky Lilita pills wrap instead of squeezing at
            // large Dynamic Type sizes.
            FlowLayout(spacing: AppTheme.Spacing.sm) {
                ForEach([300, 500, 750, 1000], id: \.self) { score in
                    RetroCategoryPill(
                        title: "\(score)",
                        color: VibeCheckStyle.accent,
                        isSelected: currentScore == score
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

// Classic-mode setup UI (mode picker, team setup) was removed for 1.0 —
// restore from git history when Classic returns. See DECISIONS.md.

// MARK: - How To Play

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    var gameMode: VibeCheckGameMode = .competition

    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { geo in
                    MotifGroundView(seed: 0x71BE_0C0D,
                                    exclusions: [CGRect(x: 8, y: 8,
                                                        width: geo.size.width - 16,
                                                        height: geo.size.height - 16)])
                }
                .ignoresSafeArea()

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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
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
        HStack(spacing: AppTheme.Spacing.sm) {
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
    VibeCheckHomeView(viewModel: CompetitionVibeCheckViewModel())
}
