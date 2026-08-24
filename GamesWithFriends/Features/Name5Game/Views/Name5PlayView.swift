import SwiftUI

struct Name5PlayView: View {
    var viewModel: Name5ViewModel

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // The timer dial, prompt card and action buttons own the
                // whole column, so motifs keep to the nav strip and the outer
                // edges (§7 — no motifs within 12pt of a timer).
                MotifGroundView(seed: 0x4A5E_0F06,
                                exclusions: [CGRect(x: 8, y: 56,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 56)])
            }
            .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                // Player indicator (if multiplayer)
                if viewModel.playerCount > 1, let player = viewModel.currentPlayer {
                    PlayerIndicator(player: player)
                        .padding(.top)
                }

                // Timer (if ready or playing)
                if viewModel.gamePhase == .ready || viewModel.gamePhase == .playing || viewModel.gamePhase == .paused {
                    if viewModel.timerEnabled {
                        TimerView(
                            timeRemaining: viewModel.timeRemaining,
                            progress: viewModel.timerProgress,
                            color: viewModel.timerColor,
                            isRunning: viewModel.isTimerRunning
                        )
                        .padding(.horizontal)
                    }
                }

                // Prompt Card
                if let prompt = viewModel.currentPrompt {
                    PromptCard(prompt: prompt, phase: viewModel.gamePhase)
                        .padding(.horizontal)
                }

                Spacer()

                // Action Buttons based on phase
                if viewModel.gamePhase == .ready {
                    ReadyButtons(viewModel: viewModel)
                        .padding()
                } else if viewModel.gamePhase == .playing {
                    PlayingButtons(viewModel: viewModel)
                        .padding()
                } else if viewModel.gamePhase == .paused {
                    PausedButtons(viewModel: viewModel)
                        .padding()
                }
            }
        }
    }
}

// MARK: - Player Indicator
struct PlayerIndicator: View {
    let player: PlayerTurn

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "person.fill")
                .font(AppTheme.Typography.caption)
            Text("Player \(player.playerNumber)")
                .font(AppTheme.Retro.Typography.heading(17))
        }
        // §8: ink on lilac — the whole-turn banner is the one place the
        // screen accent shows up as a fill.
        .foregroundColor(Name5Style.chipTextColor(on: Name5Style.accent))
        .padding(.vertical, AppTheme.Spacing.xs)
        .retroLozenge(Name5Style.accent)
        .background(
            Capsule()
                .fill(AppTheme.Retro.ink)
                .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
        )
    }
}

// MARK: - Timer View
struct TimerView: View {
    let timeRemaining: Int
    let progress: Double
    let color: Color
    let isRunning: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                // Cream dial plate with an ink rule — the countdown reads
                // ink-on-cream (§3 recipe) instead of floating on the ground.
                Circle()
                    .fill(AppTheme.Retro.panel)
                Circle()
                    .stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)

                // Unfilled track: ink at 15% + a hairline rule (§4 gotcha 6).
                Circle()
                    .inset(by: 10)
                    .stroke(AppTheme.Retro.ink.opacity(0.15), lineWidth: 12)

                // Progress arc — re-tinted to the candy ramp; the trim math
                // and the linear animation are untouched.
                Circle()
                    .inset(by: 10)
                    .trim(from: 0, to: progress)
                    .stroke(Name5Style.timerRingColor(color), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: progress)

                VStack(spacing: AppTheme.Spacing.xs) {
                    // Urgent state turns tomato on the view model's existing
                    // three-stop trigger — no new condition here.
                    Text("\(timeRemaining)")
                        .font(AppTheme.Retro.Typography.heading(44, relativeTo: .largeTitle))
                        .monospacedDigit()
                        .foregroundColor(Name5Style.timerTextColor(color))

                    Text("seconds")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Retro.cocoa)
                }
            }
            .frame(width: 140, height: 140)
        }
    }
}

// MARK: - Prompt Card
struct PromptCard: View {
    let prompt: Name5Prompt
    let phase: GamePhase

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Category & difficulty badges
            HStack(spacing: AppTheme.Spacing.sm) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: prompt.category.icon)
                        .font(AppTheme.Typography.caption)
                    Text(prompt.category.rawValue)
                        .font(AppTheme.Retro.Typography.pillLabel)
                }
                .foregroundColor(Name5Style.chipTextColor(on: Name5Style.accent))
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(Capsule().fill(Name5Style.accent))
                .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))

                Name5DifficultyChip(difficulty: prompt.difficulty)
            }

            // Prompt text — the card's hero. Lilita One display (§4) so the
            // content pops as loud as the chrome around it.
            Text(prompt.text)
                .font(AppTheme.Retro.Typography.heading(24, relativeTo: .title))
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.Retro.panelText)
                .lineSpacing(4)
                .padding(.horizontal)
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .retroPanel(AppTheme.Retro.panel)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                .fill(AppTheme.Retro.ink)
                .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
        )
        .scaleEffect(phase == .playing ? 1.0 : 0.95)
        .animation(.spring(response: 0.3), value: phase)
    }
}

// MARK: - Ready Buttons
struct ReadyButtons: View {
    var viewModel: Name5ViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            RetroPrimaryButton(title: "Start", icon: "play.fill",
                               accent: Name5Style.accent) {
                viewModel.startRound()
            }

            // Tangerine is this app's utility action next to the game accent
            // (same split the pilot uses for "Pass").
            RetroPrimaryButton(title: "Skip", icon: "forward.fill",
                               accent: AppTheme.Retro.tangerine) {
                viewModel.skipPrompt()
            }
        }
    }
}

// MARK: - Playing Buttons
struct PlayingButtons: View {
    var viewModel: Name5ViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                RetroPrimaryButton(title: "Got It!", icon: "checkmark",
                                   accent: Name5Style.successColor) {
                    viewModel.markSuccess()
                }

                RetroPrimaryButton(title: "Failed", icon: "xmark",
                                   accent: Name5Style.dangerColor) {
                    viewModel.markFailure()
                }
            }

            if viewModel.timerEnabled {
                RetroPrimaryButton(title: "Pause", icon: "pause.fill",
                                   accent: AppTheme.Retro.panel) {
                    viewModel.pauseTimer()
                }
            }
        }
    }
}

// MARK: - Paused Buttons
struct PausedButtons: View {
    var viewModel: Name5ViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Paused")
                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)
                .retroLozenge()

            RetroPrimaryButton(title: "Resume", icon: "play.fill",
                               accent: Name5Style.accent) {
                viewModel.resumeTimer()
            }

            // Destructive but secondary: cream panel with tomato label
            // (tomato on cream passes at body size, §8).
            RetroPrimaryButton(title: "Give Up", icon: "stop.fill",
                               accent: AppTheme.Retro.panel,
                               textColor: Name5Style.dangerColor) {
                viewModel.markFailure()
            }
        }
    }
}
