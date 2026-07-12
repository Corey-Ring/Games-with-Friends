import SwiftUI

struct BorderHopGameView: View {
    var viewModel: BorderHopViewModel
    private let theme = GameTheme.borderHop
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("borderHopHasSeenCoach") private var hasSeenCoach = false

    private var showCoachOverlay: Bool {
        !hasSeenCoach && !viewModel.isQuizActive && !viewModel.hasArrived
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Layer 0: Map
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
                AppTheme.overlay
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
            // Close button
            Button {
                viewModel.quitGame()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Streak badge (when > 1)
            if viewModel.currentStreak > 1 {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(AppTheme.warning)
                    Text(verbatim: "\(viewModel.currentStreak)")
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(AppTheme.warning)
                        .monospacedDigit()
                }
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(Capsule().fill(AppTheme.warning.opacity(0.15)))
            }

            // Stopwatch — informational pace stat; time doesn't affect the score
            StopwatchView(
                elapsed: viewModel.elapsedTime,
                color: .white
            )

            Spacer()

            // Hop counter
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "figure.walk")
                    .foregroundColor(.white)
                Text(verbatim: "\(viewModel.hopCount)")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(Capsule().fill(.ultraThinMaterial))
        }
    }

    // MARK: - Bottom Bar

    private var destinationBar: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "flag.checkered")
                .foregroundColor(AppTheme.medalGold)

            Text(viewModel.destinationCountry?.name ?? "")
                .font(AppTheme.Typography.cardTitle)
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            bordersRemainingBadge
        }
        .padding(AppTheme.Spacing.md)
        .background(.ultraThinMaterial)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    /// "Am I winning?" — live distance to the goal, colored by whether the last hop helped
    private var bordersRemainingBadge: some View {
        let delta = viewModel.bordersRemainingDelta
        let deltaColor: Color = delta < 0 ? AppTheme.success : (delta > 0 ? AppTheme.error : .white.opacity(0.8))

        return HStack(spacing: AppTheme.Spacing.xs) {
            if viewModel.hopCount > 0 && delta != 0 {
                Image(systemName: delta < 0 ? "arrow.down.right" : "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(deltaColor)
            }
            Text(viewModel.bordersRemaining == 1
                 ? "1 border away"
                 : "\(viewModel.bordersRemaining) borders away")
                .font(AppTheme.Typography.detail)
                .foregroundColor(deltaColor)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.bordersRemaining)
    }

    // MARK: - Backtrack Banner

    private func backtrackBanner(targetId: String) -> some View {
        VStack {
            HStack(spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Backtrack to \(viewModel.graph.country(for: targetId)?.name ?? "")?")
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(.white)
                    Text("Adds a hop to your route")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.warning)
                }

                Spacer()

                Button("Cancel") {
                    viewModel.cancelBacktrack()
                }
                .font(AppTheme.Typography.pillLabel)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(Capsule().fill(.white.opacity(0.15)))

                Button("Confirm") {
                    viewModel.confirmBacktrack()
                }
                .font(AppTheme.Typography.pillLabel)
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(Capsule().fill(theme.accentColor))
            }
            .padding(AppTheme.Spacing.md)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
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
            AppTheme.overlay
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                Text("How to play")
                    .font(AppTheme.Typography.sectionHeader)
                    .foregroundColor(coachTextColor)

                coachRow(
                    icon: "mappin.circle.fill",
                    iconColor: theme.accentColor,
                    title: "You are here",
                    detail: "The bright country with the pin is you."
                )

                coachRow(
                    icon: "hand.tap.fill",
                    iconColor: theme.accentColor,
                    title: "Tap a glowing neighbor to hop",
                    detail: "Answer one quick question to cross each border."
                )

                coachRow(
                    icon: "flag.checkered",
                    iconColor: AppTheme.medalGold,
                    title: "Reach the gold country",
                    detail: "Fewest hops wins. The bar below counts the borders left."
                )

                PrimaryButton(title: "Got it", icon: "checkmark") {
                    HapticManager.light()
                    hasSeenCoach = true
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .fill(colorScheme == .dark ? AppTheme.darkElevated : AppTheme.pureWhite)
            )
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .transition(.opacity)
    }

    private var coachTextColor: Color {
        colorScheme == .dark ? .white : AppTheme.deepCharcoal
    }

    private func coachRow(icon: String, iconColor: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(coachTextColor)
                Text(detail)
                    .font(AppTheme.Typography.secondary)
                    .foregroundColor(colorScheme == .dark ? AppTheme.darkMutedText : AppTheme.mediumGray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Victory Overlay

    private var victoryOverlay: some View {
        ZStack {
            AppTheme.overlay
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: "flag.checkered.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppTheme.medalGold)
                    .symbolEffect(.bounce, value: reduceMotion ? false : viewModel.hasArrived)

                Text("Route Complete!")
                    .font(AppTheme.Typography.hero)
                    .foregroundColor(.white)

                if let result = viewModel.roundResult {
                    Text("Score: \(result.totalScoreInt)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(theme.accentColor)
                }
            }
        }
        .transition(.opacity)
        .animation(.easeIn(duration: 0.3), value: viewModel.hasArrived)
    }
}
