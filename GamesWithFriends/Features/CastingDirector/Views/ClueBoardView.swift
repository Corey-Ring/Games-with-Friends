import SwiftUI

/// The main gameplay view — scattered clue board with guess button
struct ClueBoardView: View {
    @ObservedObject var viewModel: CastingDirectorViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Plain retro ground — the scattered chips are the ornament here,
            // and the guess overlay brings up the keyboard (playbook §3).
            AppTheme.Retro.ground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal)
                    .padding(.top, AppTheme.Spacing.sm)

                // Clue board area
                if viewModel.isLoadingRound {
                    Spacer()
                    VStack(spacing: AppTheme.Spacing.md) {
                        GameSpinner(color: CastingDirectorStyle.accent)
                        Text("Finding an actor...")
                            .font(AppTheme.Retro.Typography.cardTitle)
                            .foregroundColor(AppTheme.Retro.panelText)
                            .retroLozenge()
                    }
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            clueBoard
                                .padding(.horizontal, AppTheme.Spacing.sm)
                                .padding(.top, AppTheme.Spacing.sm)
                                .padding(.bottom, AppTheme.Spacing.md)
                        }
                        .onChange(of: viewModel.roundState.revealedClues.count) { _, _ in
                            // Auto-scroll to the latest clue
                            if let lastClue = viewModel.roundState.revealedClues.last {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo(lastClue.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                // Bottom bar with score and guess button
                bottomBar
                    .padding(.horizontal)
                    .padding(.bottom, AppTheme.Spacing.sm)
            }

            // Guess overlay
            if viewModel.showingGuessOverlay {
                GuessOverlayView(viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Correct guess celebration
            if viewModel.correctGuess {
                correctGuessOverlay
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showingGuessOverlay)
        .animation(reduceMotion ? nil : .spring(), value: viewModel.correctGuess)
    }

    // MARK: - Clue Board (scattered stagger layout)

    private var clueBoard: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(viewModel.roundState.revealedClues) { clue in
                let position = viewModel.cluePositions[clue.id]
                let isLatest = clue.id == viewModel.roundState.revealedClues.last?.id
                let alignment = alignmentForClue(clue)

                HStack {
                    if alignment == .trailing || alignment == .center {
                        Spacer(minLength: spacerWidth(for: clue))
                    }

                    ClueChipView(clue: clue, isLatest: isLatest)
                        .frame(maxWidth: chipMaxWidth(for: clue))
                        .rotationEffect(.degrees(position?.rotation ?? 0))
                        .id(clue.id)

                    if alignment == .leading || alignment == .center {
                        Spacer(minLength: 0)
                    }
                }
                .transition(reduceMotion
                    ? .opacity
                    : .asymmetric(
                        insertion: .scale(scale: 0.6).combined(with: .opacity).combined(with: .offset(y: 10)),
                        removal: .opacity
                    ))
                .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7), value: viewModel.roundState.revealedClues.count)
                .accessibilityAddTraits(.updatesFrequently)
            }
        }
    }

    /// Determine alignment based on clue order to create scattered feel
    private func alignmentForClue(_ clue: Clue) -> HorizontalAlignment {
        // Use a deterministic but varied pattern based on clue order
        let pattern = clue.orderNumber % 3
        switch pattern {
        case 0: return .leading
        case 1: return .trailing
        default: return .center
        }
    }

    /// Variable spacer width to add organic offset within the chosen alignment
    private func spacerWidth(for clue: Clue) -> CGFloat {
        guard let position = viewModel.cluePositions[clue.id] else { return 0 }
        // Use the xFraction from the position data to create varied indentation
        return CGFloat(position.xFraction) * 60
    }

    /// Constrain chip width so they never exceed screen width
    private func chipMaxWidth(for clue: Clue) -> CGFloat {
        // Shorter clues get a tighter max width; longer clues can use more space
        let baseWidth: CGFloat = 280
        // Tier 4 clues (movie titles) tend to be longer
        switch clue.tier {
        case .vague: return baseWidth - 20
        case .narrowing: return baseWidth
        case .strongSignal: return baseWidth + 10
        case .giveaway: return baseWidth + 20
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Round info
            VStack(alignment: .leading, spacing: 2) {
                Text("Round \(viewModel.currentRound) of \(viewModel.numberOfRounds)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Retro.panelText.opacity(0.7))

                if viewModel.gameMode == .passAndPlay {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Circle()
                            .fill(viewModel.currentPlayer.color)
                            .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1))
                            .frame(width: 10, height: 10)
                        Text(viewModel.currentPlayer.name)
                            .font(AppTheme.Retro.Typography.pillLabel)
                            .foregroundStyle(AppTheme.Retro.panelText)
                    }
                }
            }

            Spacer()

            // Clue counter
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Retro.ink)
                Text("\(viewModel.roundState.cluesRevealed)/\(viewModel.allClues.count)")
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .foregroundStyle(AppTheme.Retro.ink)
                    .monospacedDigit()
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(Capsule().fill(AppTheme.Retro.mustard))
            .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))

            // Difficulty badge
            Text(viewModel.difficulty.rawValue)
                .font(AppTheme.Retro.Typography.pillLabel)
                .foregroundStyle(AppTheme.Retro.ink)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(Capsule().fill(CastingDirectorStyle.accent))
                .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Give up button
            Button {
                viewModel.giveUp()
            } label: {
                Text("Give Up")
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .fixedSize()
                    .foregroundStyle(AppTheme.Retro.panelText)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .retroPanel(AppTheme.Retro.panel, cornerRadius: 999)
            }
            .buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))

            Spacer()

            // Score display — plain column on the ground; the lozenge device
            // can't hold three wrapping lines without ballooning.
            VStack(spacing: 2) {
                Text("Score \(viewModel.potentialScore)")
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .monospacedDigit()
                    .fixedSize()
                    .foregroundStyle(AppTheme.Retro.panelText)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .retroLozenge()
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .spring(), value: viewModel.potentialScore)

                Text("Extra clues cost 50")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Retro.ink.opacity(0.7))
                    .fixedSize()

                if viewModel.eraFallbackNotice {
                    Text("No \(viewModel.era.rawValue)-era actor — showing any era")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Retro.cocoa)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            // Guess button
            Button {
                viewModel.showingGuessOverlay = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle.fill")
                    Text("Guess")
                }
                .font(AppTheme.Retro.Typography.heading(16, relativeTo: .headline))
                .fixedSize()
                .foregroundStyle(AppTheme.Retro.ink)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .retroPanel(CastingDirectorStyle.accent, cornerRadius: AppTheme.Retro.Radius.inner)
            }
            .buttonStyle(RetroRaisedButtonStyle(cornerRadius: AppTheme.Retro.Radius.inner))
            .modifier(ShakeEffect(shakes: (reduceMotion || !viewModel.wrongGuessShake) ? 0 : 4))
            .animation(reduceMotion ? nil : .default, value: viewModel.wrongGuessShake)
        }
    }

    // MARK: - Correct Guess Overlay

    private var correctGuessOverlay: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle().fill(CastingDirectorStyle.successColor)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(AppTheme.Retro.ink)
                    .symbolEffect(.bounce, value: reduceMotion ? false : viewModel.correctGuess)
            }
            .frame(width: 84, height: 84)

            if let actor = viewModel.roundState.targetActor {
                Text(actor.name)
                    .font(AppTheme.Retro.Typography.heading(24, relativeTo: .title))
                    .foregroundColor(AppTheme.Retro.panelText)
                    .multilineTextAlignment(.center)
            }

            Text("+\(viewModel.roundState.currentScore) points!")
                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.ink)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(Capsule().fill(CastingDirectorStyle.accent))
                .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))
        }
        .padding(40)
        .retroPanel(AppTheme.Retro.panel)
    }
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var shakes: Int
    var animatableData: CGFloat {
        get { CGFloat(shakes) }
        set { shakes = Int(newValue) }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = sin(animatableData * .pi * 2) * 10
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
