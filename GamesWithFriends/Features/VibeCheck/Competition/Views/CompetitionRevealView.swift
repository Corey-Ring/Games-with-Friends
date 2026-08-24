import SwiftUI

struct CompetitionRevealView: View {
    var viewModel: CompetitionVibeCheckViewModel
    @State private var showResults = false
    @State private var revealedPositions = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            GeometryReader { geo in
                MotifGroundView(seed: 0x71BE_0C07,
                                exclusions: [CGRect(x: 8, y: 8,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 16)])
            }
            .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.md) {
                // Header
                headerSection

                ScrollView {
                    VStack(spacing: 20) {
                        // The prompt
                        promptCard

                        // Spectrum with all positions revealed
                        if let round = viewModel.currentRound {
                            multiGuessRevealSection(round: round)
                        }

                        // Leaderboard results
                        if showResults {
                            leaderboardSection
                        }
                    }
                }
                .scrollIndicators(.hidden)

                // Continue button
                continueButton
            }
            .padding()
        }
        .onAppear {
            if reduceMotion {
                // Reduce Motion: reveal everything immediately (opacity end state), keep haptic
                revealedPositions = true
                showResults = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } else {
                // Animate the reveal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        revealedPositions = true
                    }
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showResults = true
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            if let round = viewModel.currentRound {
                Text("Round \(round.roundNumber)")
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .retroLozenge()
            }

            // Framed Lilita title on the game accent (Rule 4).
            Text("Results")
                .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                .foregroundColor(VibeCheckStyle.chipTextColor(on: VibeCheckStyle.accent))
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
        }
    }

    private var promptCard: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("THE PROMPT")
                .font(AppTheme.Retro.Typography.pillLabel)
                .foregroundColor(AppTheme.Retro.cocoa)
                .tracking(2)

            if let round = viewModel.currentRound {
                Text("\"\(round.prompt)\"")
                    .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title3))
                    .foregroundColor(AppTheme.Retro.panelText)
                    .multilineTextAlignment(.center)
            }

            if let setter = viewModel.vibeSetter {
                Text("Set by \(setter.name)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Retro.cocoa)
            }
        }
        .frame(maxWidth: .infinity)
        .retroCard()
    }

    @ViewBuilder
    private func multiGuessRevealSection(round: CompetitionRound) -> some View {
        let results = viewModel.getRoundResults()

        VStack(spacing: AppTheme.Spacing.md) {
            CompetitionRevealSliderView(
                spectrum: round.spectrum,
                targetPosition: round.targetPosition,
                results: results
            )
            .opacity(revealedPositions ? 1 : 0)
            .scaleEffect(revealedPositions ? 1 : 0.9)

            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(VibeCheckStyle.targetMarker)
                        .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                        .frame(width: 12, height: 12)
                    Text("Target")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Retro.panelText)
                }

                HStack(spacing: 6) {
                    Circle()
                        .strokeBorder(AppTheme.Retro.ink, lineWidth: 2)
                        .frame(width: 12, height: 12)
                    Text("Guesses")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Retro.panelText)
                }
            }
            .padding(.vertical, AppTheme.Spacing.xs)
            .retroLozenge()
        }
    }

    private var leaderboardSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("LEADERBOARD")
                .font(AppTheme.Retro.Typography.pillLabel)
                .foregroundColor(AppTheme.Retro.cocoa)
                .tracking(2)

            ForEach(viewModel.getRoundResults()) { result in
                CompetitionResultRow(
                    result: result,
                    isWorst: result.id == viewModel.worstGuesser?.id,
                    totalPlayers: viewModel.guessingPlayers.count
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .frame(maxWidth: .infinity)
        .retroCard()
    }

    private var continueButton: some View {
        RetroPrimaryButton(title: viewModel.isGameOver ? "See Final Results" : "Continue",
                           icon: viewModel.isGameOver ? "trophy.fill" : "arrow.right",
                           accent: VibeCheckStyle.accent) {
            viewModel.proceedFromReveal()
        }
        .opacity(showResults ? 1 : 0.5)
        .disabled(!showResults)
    }
}

// MARK: - Multi-Guess Reveal Slider

/// Retro-migrated: fills, strokes and label typography only — every
/// `targetY` / `zoneHalfHeight` / `position` expression below is unchanged
/// from the pre-migration file.
struct CompetitionRevealSliderView: View {
    let spectrum: VibeCheckSpectrum
    let targetPosition: Double
    let results: [CompetitionRoundResult]

    private let sliderHeight: CGFloat = 300
    private let trackWidth: CGFloat = 60

    // Player colors for differentiation — candy accents, one per seat, from
    // the shared style so both modes agree on seat identity.
    private var playerColors: [Color] { VibeCheckStyle.playerColors }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Top label
            SpectrumPoleLabel(text: spectrum.topLabel, fill: VibeCheckStyle.poleTop)

            // Slider with all positions
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // Background track
                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                        .fill(AppTheme.Retro.panel)
                        .frame(width: trackWidth)
                        .frame(maxWidth: .infinity)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                                .stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth)
                                .frame(width: trackWidth)
                        }

                    // Scoring zones
                    scoringZonesView(height: geometry.size.height)

                    // Target line (grass)
                    targetLine(height: geometry.size.height, width: geometry.size.width)

                    // All guess lines
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                        guessLine(
                            result: result,
                            height: geometry.size.height,
                            width: geometry.size.width,
                            color: playerColors[index % playerColors.count],
                            index: index
                        )
                    }
                }
            }
            .frame(height: sliderHeight)

            // Bottom label
            SpectrumPoleLabel(text: spectrum.bottomLabel, fill: VibeCheckStyle.poleBottom)
        }
        .padding(.horizontal)
    }

    private func scoringZonesView(height: CGFloat) -> some View {
        let targetY = targetPosition * height

        return Canvas { context, size in
            let centerX = size.width / 2

            for zone in ScoringZone.allCases.reversed() {
                let zoneHalfHeight = zone.threshold * height
                let topY = max(0, targetY - zoneHalfHeight)
                let bottomY = min(height, targetY + zoneHalfHeight)
                let zoneHeight = bottomY - topY

                let rect = CGRect(
                    x: centerX - trackWidth / 2 + CGFloat(4),
                    y: topY,
                    width: trackWidth - 8,
                    height: zoneHeight
                )

                context.fill(
                    Path(roundedRect: rect, cornerRadius: 6),
                    with: .color(VibeCheckStyle.zoneColor(zone))
                )
            }
        }
    }

    private func targetLine(height: CGFloat, width: CGFloat) -> some View {
        let y = targetPosition * height

        return HStack(spacing: AppTheme.Spacing.xs) {
            Text("Target")
                .font(AppTheme.Retro.Typography.pillLabel)
                .foregroundColor(VibeCheckStyle.chipTextColor(on: VibeCheckStyle.targetMarker))
                .padding(.horizontal, AppTheme.Spacing.xs)
                .padding(.vertical, 1)
                .background(Capsule().fill(VibeCheckStyle.targetMarker))
                .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                .frame(width: 45, alignment: .trailing)

            Rectangle()
                .fill(VibeCheckStyle.targetMarker)
                .frame(width: trackWidth + 20, height: 4)
                .overlay(Rectangle().stroke(AppTheme.Retro.ink, lineWidth: 1))

            Circle()
                .fill(VibeCheckStyle.targetMarker)
                .frame(width: 14, height: 14)
                .overlay {
                    Circle()
                        .stroke(AppTheme.Retro.ink, lineWidth: 2)
                }
        }
        .position(x: width / 2, y: y)
    }

    private func guessLine(result: CompetitionRoundResult, height: CGFloat, width: CGFloat, color: Color, index: Int) -> some View {
        let y = result.guessedPosition * height
        // Slight offset to prevent exact overlapping
        let xOffset = CGFloat(index % 2 == 0 ? -2 : 2)

        return HStack(spacing: AppTheme.Spacing.xs) {
            Text(result.playerName)
                .font(AppTheme.Retro.Typography.pillLabel)
                .foregroundColor(VibeCheckStyle.chipTextColor(on: color))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, AppTheme.Spacing.xs)
                .padding(.vertical, 1)
                .background(Capsule().fill(color))
                .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                .frame(width: 45, alignment: .trailing)

            Rectangle()
                .fill(color)
                .frame(width: trackWidth + 20, height: 3)
                .overlay(Rectangle().stroke(AppTheme.Retro.ink, lineWidth: 1))

            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay {
                    Circle()
                        .stroke(AppTheme.Retro.ink, lineWidth: 1.5)
                }
        }
        .position(x: width / 2 + xOffset, y: y)
    }
}

// MARK: - Result Row

struct CompetitionResultRow: View {
    let result: CompetitionRoundResult
    let isWorst: Bool
    let totalPlayers: Int

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack(spacing: 12) {
                // Rank indicator — candy medal disc, ink outline (§2 rule 1).
                VibeCheckRankBadge(rank: result.rank)

                // Player info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(result.playerName)
                            .font(AppTheme.Retro.Typography.cardTitle)
                            .foregroundColor(AppTheme.Retro.panelText)

                        if result.rank == 1 {
                            Text("CLOSEST")
                                .font(AppTheme.Retro.Typography.pillLabel)
                                .foregroundColor(VibeCheckStyle.chipTextColor(on: VibeCheckStyle.closestColor))
                                .padding(.horizontal, AppTheme.Spacing.xs)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(VibeCheckStyle.closestColor))
                                .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))
                        }
                    }

                    Text("\(result.distancePercentage)% away")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                }

                Spacer()

                // Points badge — flat zone fill, ink outline, ink numeral (§8).
                VibeCheckPointsChip(zone: result.zone, points: result.pointsEarned)
            }

            // Worst guesser tease
            if isWorst && totalPlayers > 1 {
                HStack(spacing: 6) {
                    VibeCheckStatusBadge(systemImage: "face.smiling",
                                         color: VibeCheckStyle.teaseColor,
                                         diameter: 20)
                    Text(WorstGuesserTease.randomMessage())
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Retro.panelText)
                        .italic()
                }
                .padding(.vertical, AppTheme.Spacing.xs)
                .frame(maxWidth: .infinity)
                .retroLozenge()
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .padding(.horizontal, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                .fill(AppTheme.Retro.ground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                .stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth)
        )
    }
}

#Preview {
    let viewModel = CompetitionVibeCheckViewModel()
    viewModel.settings.playerCount = 4
    viewModel.proceedToPlayerSetup()
    viewModel.players[0].name = "Alice"
    viewModel.players[1].name = "Bob"
    viewModel.players[2].name = "Charlie"
    viewModel.players[3].name = "Diana"
    viewModel.startGame()
    viewModel.confirmVibeSetterReady()
    viewModel.currentPrompt = "Clipping your nails in a movie theater"
    viewModel.submitPrompt()
    // Simulate some guesses
    viewModel.confirmGuessingPlayerReady()
    viewModel.currentGuessPosition = 0.18
    viewModel.submitGuess()
    viewModel.confirmGuessingPlayerReady()
    viewModel.currentGuessPosition = 0.25
    viewModel.submitGuess()
    viewModel.confirmGuessingPlayerReady()
    viewModel.currentGuessPosition = 0.45
    viewModel.submitGuess()
    return CompetitionRevealView(viewModel: viewModel)
}
