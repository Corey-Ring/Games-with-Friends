import SwiftUI

struct BorderHopResultsView: View {
    var viewModel: BorderHopViewModel

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Scrolling result column runs the full width; motifs keep to
                // the nav strip and the outer gutters (§7).
                MotifGroundView(seed: 0xB0B5_0E03,
                                exclusions: [CGRect(x: 8, y: 56,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 56)])
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Celebration header
                    celebrationHeader
                        .staggeredAppear(index: 0)

                    // Score breakdown
                    if let result = viewModel.roundResult {
                        scoreBreakdown(result: result)
                            .staggeredAppear(index: 1)

                        if !result.learnedFacts.isEmpty {
                            learnedFactsCard(result: result)
                                .staggeredAppear(index: 2)
                        }

                        pathComparison(result: result)
                            .staggeredAppear(index: 3)
                    }

                    // Action buttons
                    actionButtons
                        .staggeredAppear(index: 4)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
        }
    }

    // MARK: - Celebration Header

    private var celebrationHeader: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // §9: the naked SF hero is replaced by the game's spot plate; the
            // efficiency grade it used to encode moves into the medal chip.
            BorderHopSpotPlate(diameter: 112)

            BorderHopTitlePanel(text: "Route Complete!", size: 24)

            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: efficiencyIcon)
                Text(efficiencyLabel)
                    .font(AppTheme.Retro.Typography.pillLabel)
            }
            .foregroundColor(BorderHopStyle.panelAwareTextColor(on: efficiencyMedal))
            .retroLozenge(efficiencyMedal)
            .rotationEffect(.degrees(0.8))

            if let result = viewModel.roundResult {
                AnimatedScoreText(
                    targetScore: result.totalScoreInt,
                    color: AppTheme.Retro.panelText,
                    font: AppTheme.Retro.Typography.heading(38, relativeTo: .largeTitle)
                )
                .retroLozenge()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppTheme.Spacing.md)
    }

    private var efficiencyIcon: String {
        guard let result = viewModel.roundResult else { return "star.circle.fill" }
        if result.efficiency >= 100 { return "crown.fill" }
        else if result.efficiency >= 80 { return "star.fill" }
        else if result.efficiency >= 60 { return "hand.thumbsup.fill" }
        else { return "figure.walk" }
    }

    private var efficiencyLabel: String {
        guard let result = viewModel.roundResult else { return "Route logged" }
        if result.efficiency >= 100 { return "Shortest route" }
        else if result.efficiency >= 80 { return "Nearly optimal" }
        else if result.efficiency >= 60 { return "Solid route" }
        else { return "Scenic route" }
    }

    /// Mustard / cornflower / cocoa medal ladder (the pattern Movie Chain and
    /// Vibe Check use); cocoa takes cream text per §8.
    private var efficiencyMedal: Color {
        guard let result = viewModel.roundResult else { return AppTheme.Retro.panel }
        if result.efficiency >= 100 { return BorderHopStyle.medalFirst }
        else if result.efficiency >= 80 { return BorderHopStyle.medalSecond }
        else if result.efficiency >= 60 { return BorderHopStyle.medalThird }
        else { return AppTheme.Retro.panel }
    }

    // MARK: - Score Breakdown

    private func scoreBreakdown(result: BorderHopRoundResult) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Score Breakdown")
                .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)

            scoreRow(label: "Route", detail: "\(result.actualHops) hops (shortest: \(result.optimalHops))", value: "\(Int(result.efficiency.rounded()))")
            scoreRow(label: "Knowledge", detail: "\(result.firstTryCount) of \(result.questionCredits.count) first try", value: "\(Int(result.knowledgeScore.rounded()))")
            scoreRow(label: "Time", detail: "Just for reference — it doesn't score", value: formatTime(result.elapsedTime))

            if result.streakMultiplier > 1.0 {
                scoreRow(label: "Streak", detail: "×\(String(format: "%.1f", result.streakMultiplier))", value: "")
            }

            // Ink rule instead of the hairline system Divider (Rule 1)
            Rectangle()
                .fill(AppTheme.Retro.panelText)
                .frame(height: 2)

            HStack {
                Text("Total")
                    .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title3))
                    .foregroundColor(AppTheme.Retro.panelText)
                Spacer()
                Text("\(result.totalScoreInt)")
                    .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title3))
                    .foregroundColor(BorderHopStyle.chipTextColor(on: BorderHopStyle.accent))
                    .monospacedDigit()
                    .retroLozenge(BorderHopStyle.accent)
            }
        }
        .retroCard()
    }

    private func scoreRow(label: String, detail: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText)
                Text(detail)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(BorderHopStyle.mutedText)
            }
            Spacer()
            if !value.isEmpty {
                Text(value)
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Path Comparison

    private var isOptimalRoute: Bool {
        guard let result = viewModel.roundResult else { return false }
        return result.actualHops == result.optimalHops
    }

    private func pathComparison(result: BorderHopRoundResult) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Text("Route Comparison")
                    .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title3))
                    .foregroundColor(AppTheme.Retro.panelText)

                if isOptimalRoute {
                    Spacer()
                    Text("Perfect!")
                        .font(AppTheme.Retro.Typography.pillLabel)
                        .foregroundColor(BorderHopStyle.chipTextColor(on: BorderHopStyle.goalColor))
                        .retroLozenge(BorderHopStyle.goalColor)
                }
            }

            if isOptimalRoute {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.Retro.panelText)
                    Text("You found the shortest route!")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Retro.panelText)
                }
                .padding(.bottom, AppTheme.Spacing.xs)
            }

            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                pathColumn(title: "Your Route", path: result.actualPath,
                           color: isOptimalRoute ? BorderHopStyle.correctColor : BorderHopStyle.accent)
                if !isOptimalRoute {
                    pathColumn(title: "Optimal", path: result.optimalPath, color: BorderHopStyle.correctColor)
                }
            }
        }
        .retroCard()
    }

    private func pathColumn(title: String, path: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // §8: the column's identity color rides a lozenge with ink text —
            // grass or cornflower as small type on cream would fail contrast.
            Text(title)
                .font(AppTheme.Retro.Typography.pillLabel)
                .foregroundColor(BorderHopStyle.chipTextColor(on: color))
                .retroLozenge(color)

            Text("\(max(path.count - 1, 0)) hops")
                .font(AppTheme.Typography.caption)
                .foregroundColor(BorderHopStyle.mutedText)

            ForEach(Array(path.enumerated()), id: \.offset) { index, countryId in
                HStack(spacing: AppTheme.Spacing.xs) {
                    if index == 0 {
                        marker(fill: color)
                    } else if index == path.count - 1 {
                        marker(fill: BorderHopStyle.goalColor)
                    } else {
                        marker(fill: AppTheme.Retro.panel)
                    }

                    Text(viewModel.graph.country(for: countryId)?.name ?? countryId)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Retro.panelText)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Route beads: flat candy dot, ink rule (Rule 1 — outlines on everything).
    private func marker(fill: Color) -> some View {
        Circle()
            .fill(fill)
            .frame(width: 9, height: 9)
            .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
    }

    // MARK: - What You Learned

    /// Recap of the exact facts the player saw this round — re-surfacing them here is
    /// what makes them stick, unlike random trivia about countries never visited.
    private func learnedFactsCard(result: BorderHopRoundResult) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(AppTheme.Retro.panelText)
                Text("What you learned")
                    .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title3))
                    .foregroundColor(AppTheme.Retro.panelText)
            }

            ForEach(Array(result.learnedFacts.enumerated()), id: \.element.id) { index, fact in
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    BorderHopGlyphPlate(
                        systemImage: fact.gotItFirstTry ? "checkmark" : "arrow.counterclockwise",
                        fill: fact.gotItFirstTry ? BorderHopStyle.correctColor : BorderHopStyle.reviewColor,
                        diameter: 26,
                        glyphSize: 12
                    )

                    Text(fact.text)
                        .font(AppTheme.Typography.secondary)
                        .foregroundColor(AppTheme.Retro.panelText)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .staggeredAppear(index: index)
            }

            let missed = result.learnedFacts.filter { !$0.gotItFirstTry }.count
            if missed > 0 {
                Text("Facts marked with the orange arrow are worth a second look — they'll come around again.")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(BorderHopStyle.mutedText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            RetroPrimaryButton(title: "Play Again", icon: "arrow.counterclockwise",
                               accent: BorderHopStyle.accent) {
                viewModel.playAgain()
            }

            RetroPrimaryButton(title: "Change Difficulty", icon: "slider.horizontal.3",
                               accent: AppTheme.Retro.panel,
                               textColor: AppTheme.Retro.panelText) {
                viewModel.changeDifficulty()
            }

            RetroPrimaryButton(title: "Back to Home", icon: "house",
                               accent: AppTheme.Retro.panel,
                               textColor: AppTheme.Retro.panelText) {
                viewModel.quitGame()
            }
        }
        .padding(.bottom, AppTheme.Spacing.lg)
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
