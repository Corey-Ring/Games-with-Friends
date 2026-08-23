import SwiftUI

struct BorderHopGameView: View {
    var viewModel: BorderHopViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("borderHopHasSeenCoach") private var hasSeenCoach = false

    private var showCoachOverlay: Bool {
        !hasSeenCoach && !viewModel.isQuizActive && !viewModel.hasArrived
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Layer 0: Map (no motif ground behind the live map — §7)
            BorderHopMapView(viewModel: viewModel)
                .ignoresSafeArea()

            // Layer 1: Top HUD
            topHUD
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.sm)

            // Layer 2: Bottom destination bar
            VStack {
                Spacer()
                destinationBar
            }

            // Backtrack confirmation banner
            if viewModel.showBacktrackConfirm, let targetId = viewModel.backtrackTargetId {
                backtrackBanner(targetId: targetId)
            }

            // Quiz overlay
            if viewModel.isQuizActive, let question = viewModel.currentQuizQuestion {
                BorderHopStyle.scrim
                    .ignoresSafeArea()
                    .onTapGesture { } // prevent tap-through

                BorderHopQuizView(
                    question: question,
                    eliminatedChoices: viewModel.eliminatedChoices,
                    strikeCount: viewModel.strikeCount,
                    resolved: viewModel.quizResolved,
                    revealed: viewModel.quizRevealedAnswer,
                    takeaway: viewModel.currentTakeaway,
                    onAnswer: { viewModel.submitQuizAnswer($0) },
                    countryName: viewModel.graph.country(for: question.countryId)?.name ?? "",
                    graph: viewModel.graph
                )
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }

            // First-run coach overlay — one screen that explains the objective
            if showCoachOverlay {
                coachOverlay
            }

            // Victory overlay
            if viewModel.hasArrived {
                victoryOverlay
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: viewModel.isQuizActive)
        .navigationBarHidden(true)
    }

    // MARK: - Top HUD

    private var topHUD: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Close button — functional SF glyph on an ink-outlined plate (§6)
            Button {
                viewModel.quitGame()
            } label: {
                BorderHopGlyphPlate(systemImage: "xmark", diameter: 44, glyphSize: 18)
            }
            .buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))

            Spacer()

            // Streak badge (when > 1)
            if viewModel.currentStreak > 1 {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "flame.fill")
                    Text(verbatim: "\(viewModel.currentStreak)")
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .monospacedDigit()
                }
                // Tangerine takes ink (§8) — the 15%-alpha capsule is retired.
                .foregroundColor(BorderHopStyle.chipTextColor(on: BorderHopStyle.reviewColor))
                .retroLozenge(BorderHopStyle.reviewColor)
            }

            // Stopwatch — informational pace stat; time doesn't affect the score
            StopwatchView(
                elapsed: viewModel.elapsedTime,
                color: AppTheme.Retro.panelText
            )

            Spacer()

            // Hop counter
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "figure.walk")
                Text(verbatim: "\(viewModel.hopCount)")
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .foregroundColor(AppTheme.Retro.panelText)
            .retroLozenge()
        }
    }

    // MARK: - Bottom Bar

    private var destinationBar: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "flag.checkered")
                .foregroundColor(AppTheme.Retro.panelText)

            Text(viewModel.destinationCountry?.name ?? "")
                .font(AppTheme.Retro.Typography.cardTitle)
                .foregroundColor(AppTheme.Retro.panelText)
                .lineLimit(1)

            Spacer()

            bordersRemainingBadge
        }
        .padding(AppTheme.Spacing.md)
        // §9: the material bar becomes a cream panel with a hard ink top rule.
        .background(AppTheme.Retro.panel)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.Retro.ink)
                .frame(height: AppTheme.Retro.strokeHeavy)
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    /// "Am I winning?" — live distance to the goal, colored by whether the last hop helped.
    /// §8: grass/tomato can't be small *text* on cream, so the colored state is a
    /// candy-filled chip with ink glyphs; the neutral state stays plain panelText.
    private var bordersRemainingBadge: some View {
        let delta = viewModel.bordersRemainingDelta
        let isColored = viewModel.hopCount > 0 && delta != 0
        let chipFill: Color = delta < 0 ? BorderHopStyle.correctColor : BorderHopStyle.wrongColor

        return HStack(spacing: AppTheme.Spacing.xs) {
            if isColored {
                Image(systemName: delta < 0 ? "arrow.down.right" : "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(AppTheme.Retro.ink)
            }
            Text(viewModel.bordersRemaining == 1
                 ? "1 border away"
                 : "\(viewModel.bordersRemaining) borders away")
                .font(AppTheme.Typography.detail)
                .foregroundColor(isColored ? AppTheme.Retro.ink : AppTheme.Retro.panelText)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(Capsule().fill(isColored ? chipFill : Color.clear))
        .overlay {
            if isColored {
                Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.bordersRemaining)
    }

    // MARK: - Backtrack Banner

    private func backtrackBanner(targetId: String) -> some View {
        VStack {
            HStack(spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Backtrack to \(viewModel.graph.country(for: targetId)?.name ?? "")?")
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .foregroundColor(AppTheme.Retro.panelText)
                    Text("Adds a hop to your route")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Retro.panelText)
                }

                Spacer()

                Button {
                    viewModel.cancelBacktrack()
                } label: {
                    Text("Cancel")
                        .font(AppTheme.Retro.Typography.pillLabel)
                        .foregroundColor(AppTheme.Retro.panelText)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .retroLozenge()
                }
                .buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))

                Button {
                    viewModel.confirmBacktrack()
                } label: {
                    Text("Confirm")
                        .font(AppTheme.Retro.Typography.pillLabel)
                        .foregroundColor(BorderHopStyle.chipTextColor(on: BorderHopStyle.accent))
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .retroLozenge(BorderHopStyle.accent)
                }
                .buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))
            }
            .retroCard()
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.top, 60) // Below HUD

            Spacer()
        }
        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showBacktrackConfirm)
    }

    // MARK: - Coach Overlay

    /// Shown once, on the first round ever — answers "what am I looking at?"
    private var coachOverlay: some View {
        ZStack {
            BorderHopStyle.scrim
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                Text("How to play")
                    .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                    .foregroundColor(AppTheme.Retro.panelText)

                coachRow(
                    icon: "mappin.and.ellipse",
                    iconColor: BorderHopStyle.accent,
                    title: "You are here",
                    detail: "The country filled in blue with the pin is you."
                )

                coachRow(
                    icon: "hand.tap.fill",
                    iconColor: BorderHopStyle.accent,
                    title: "Tap a highlighted neighbor to hop",
                    detail: "Answer one quick question to cross each border."
                )

                coachRow(
                    icon: "flag.checkered",
                    iconColor: BorderHopStyle.goalColor,
                    title: "Reach the gold country",
                    detail: "Fewest hops wins. The bar below counts the borders left."
                )

                RetroPrimaryButton(title: "Got it", icon: "checkmark",
                                   accent: BorderHopStyle.accent) {
                    HapticManager.light()
                    hasSeenCoach = true
                }
            }
            .retroCard()
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .transition(.opacity)
    }

    private func coachRow(icon: String, iconColor: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            BorderHopGlyphPlate(systemImage: icon, fill: iconColor, diameter: 40, glyphSize: 18)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText)
                Text(detail)
                    .font(AppTheme.Typography.secondary)
                    .foregroundColor(BorderHopStyle.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Victory Overlay

    private var victoryOverlay: some View {
        ZStack {
            BorderHopStyle.scrim
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                // §9: the naked SF hero (and its bounce) is replaced by the
                // game's spot plate.
                BorderHopSpotPlate(diameter: 120)

                BorderHopTitlePanel(text: "Route Complete!", size: 26, tilt: -1)

                if let result = viewModel.roundResult {
                    Text("Score: \(result.totalScoreInt)")
                        .font(AppTheme.Retro.Typography.heading(30, relativeTo: .title))
                        .foregroundColor(AppTheme.Retro.panelText)
                        .monospacedDigit()
                        .retroLozenge()
                }
            }
        }
        .transition(.opacity)
        .animation(.easeIn(duration: 0.3), value: viewModel.hasArrived)
    }
}
