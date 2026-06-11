import SwiftUI

struct BorderHopResultsView: View {
    var viewModel: BorderHopViewModel
    private let theme = GameTheme.borderHop
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            GameBackground(gameTheme: theme)

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
            Image(systemName: efficiencyIcon)
                .font(.system(size: 60))
                .foregroundColor(theme.accentColor)
                .symbolEffect(.bounce, value: true)

            Text("Route Complete!")
                .font(AppTheme.Typography.hero)
                .foregroundColor(AppTheme.deepCharcoal)

            if let result = viewModel.roundResult {
                AnimatedScoreText(
                    targetScore: result.totalScoreInt,
                    color: theme.accentColor
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppTheme.Spacing.md)
    }

    private var efficiencyIcon: String {
        guard let result = viewModel.roundResult else { return "star.circle.fill" }
        if result.efficiency >= 100 { return "crown.fill" }
        else if result.efficiency >= 80 { return "star.circle.fill" }
        else if result.efficiency >= 60 { return "hand.thumbsup.circle.fill" }
        else { return "figure.walk.circle.fill" }
    }

    // MARK: - Score Breakdown

    private func scoreBreakdown(result: BorderHopRoundResult) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Score Breakdown")
                .font(AppTheme.Typography.sectionHeader)
                .foregroundColor(AppTheme.deepCharcoal)

            scoreRow(label: "Route", detail: "\(result.actualHops) hops (shortest: \(result.optimalHops))", value: "\(Int(result.efficiency.rounded()))")
            scoreRow(label: "Knowledge", detail: "\(result.firstTryCount) of \(result.questionCredits.count) first try", value: "\(Int(result.knowledgeScore.rounded()))")
            scoreRow(label: "Time", detail: "Just for reference — it doesn't score", value: formatTime(result.elapsedTime))

            if result.streakMultiplier > 1.0 {
                scoreRow(label: "Streak", detail: "×\(String(format: "%.1f", result.streakMultiplier))", value: "")
            }

            Divider()

            HStack {
                Text("Total")
                    .font(AppTheme.Typography.sectionHeader)
                    .foregroundColor(AppTheme.deepCharcoal)
                Spacer()
                Text("\(result.totalScoreInt)")
                    .font(AppTheme.Typography.sectionHeader)
                    .foregroundColor(theme.accentColor)
                    .monospacedDigit()
            }
        }
        .gameCard()
    }

    private func scoreRow(label: String, detail: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(AppTheme.deepCharcoal)
                Text(detail)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.mediumGray)
            }
            Spacer()
            if !value.isEmpty {
                Text(value)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(theme.accentColor)
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
                    .font(AppTheme.Typography.sectionHeader)
                    .foregroundColor(AppTheme.deepCharcoal)

                if isOptimalRoute {
                    Spacer()
                    Text("Perfect!")
                        .font(AppTheme.Typography.pillLabel)
                        .foregroundColor(AppTheme.medalGold)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppTheme.medalGold.opacity(0.12))
                        )
                }
            }

            if isOptimalRoute {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.medalGold)
                    Text("You found the shortest route!")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.mediumGray)
                }
                .padding(.bottom, AppTheme.Spacing.xs)
            }

            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                pathColumn(title: "Your Route", path: result.actualPath, color: isOptimalRoute ? AppTheme.success : theme.accentColor)
                if !isOptimalRoute {
                    pathColumn(title: "Optimal", path: result.optimalPath, color: AppTheme.success)
                }
            }
        }
        .gameCard()
    }

    private func pathColumn(title: String, path: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.pillLabel)
                .foregroundColor(color)

            Text("\(max(path.count - 1, 0)) hops")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.mediumGray)

            ForEach(Array(path.enumerated()), id: \.offset) { index, countryId in
                HStack(spacing: AppTheme.Spacing.xs) {
                    if index == 0 {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption2)
                            .foregroundColor(color)
                    } else if index == path.count - 1 {
                        Image(systemName: "flag.checkered")
                            .font(.caption2)
                            .foregroundColor(AppTheme.medalGold)
                    } else {
                        Circle()
                            .fill(color.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }

                    Text(viewModel.graph.country(for: countryId)?.name ?? countryId)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.deepCharcoal)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - What You Learned

    /// Recap of the exact facts the player saw this round — re-surfacing them here is
    /// what makes them stick, unlike random trivia about countries never visited.
    private func learnedFactsCard(result: BorderHopRoundResult) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(AppTheme.medalGold)
                Text("What you learned")
                    .font(AppTheme.Typography.sectionHeader)
                    .foregroundColor(AppTheme.deepCharcoal)
            }

            ForEach(Array(result.learnedFacts.enumerated()), id: \.element.id) { index, fact in
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
                    Image(systemName: fact.gotItFirstTry ? "checkmark.circle.fill" : "arrow.counterclockwise.circle.fill")
                        .font(.caption)
                        .foregroundColor(fact.gotItFirstTry ? AppTheme.success : AppTheme.warning)

                    Text(fact.text)
                        .font(AppTheme.Typography.secondary)
                        .foregroundColor(AppTheme.deepCharcoal)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .staggeredAppear(index: index)
            }

            let missed = result.learnedFacts.filter { !$0.gotItFirstTry }.count
            if missed > 0 {
                Text("Facts marked with the orange arrow are worth a second look — they'll come around again.")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.mediumGray)
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(AppTheme.medalGold.opacity(0.08))
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            PrimaryButton(title: "Play Again", icon: "arrow.counterclockwise") {
                viewModel.playAgain()
            }

            SecondaryButton(title: "Change Difficulty", icon: "slider.horizontal.3") {
                viewModel.changeDifficulty()
            }

            SecondaryButton(title: "Back to Home", icon: "house") {
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
