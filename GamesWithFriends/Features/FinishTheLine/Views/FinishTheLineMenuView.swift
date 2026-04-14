//
//  FinishTheLineMenuView.swift
//  GamesWithFriends
//

import SwiftUI

struct FinishTheLineMenuView: View {
    @Bindable var viewModel: FinishTheLineViewModel
    @Environment(\.dismiss) private var dismiss
    private let theme = GameTheme.finishTheLine

    var body: some View {
        ZStack {
            GameBackground(gameTheme: theme)

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    headerSection
                        .staggeredAppear(index: 0)

                    heroIcon
                        .staggeredAppear(index: 1)

                    difficultySection
                        .staggeredAppear(index: 2)

                    categoriesSection
                        .staggeredAppear(index: 3)

                    decadesSection
                        .staggeredAppear(index: 4)

                    permissionSection
                        .staggeredAppear(index: 5)

                    startSection
                        .staggeredAppear(index: 6)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
        .navigationTitle("Finish the Line")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.speechManager.checkPermissionStatus()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text("Finish the Line")
                .font(AppTheme.Typography.hero)
                .foregroundColor(AppTheme.deepCharcoal)
                .multilineTextAlignment(.center)

            Text("Speak the missing word. Beat the clock.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.mediumGray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppTheme.Spacing.sm)
    }

    // MARK: - Hero icon

    private var heroIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [theme.accentColor, theme.accentColor.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
                .shadow(color: theme.accentColor.opacity(0.35), radius: 16, x: 0, y: 8)

            Image(systemName: theme.iconName)
                .font(.system(size: 62, weight: .semibold))
                .foregroundColor(.white)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Difficulty

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionHeader("Difficulty", systemImage: "gauge.with.needle.fill")

            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(QuoteDifficulty.allCases) { difficulty in
                    DifficultySegmentButton(
                        difficulty: difficulty,
                        isSelected: viewModel.difficulty == difficulty,
                        accentColor: theme.accentColor
                    ) {
                        viewModel.setDifficulty(difficulty)
                    }
                }
            }

            Text(viewModel.difficulty.tagline)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.mediumGray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
                .id(viewModel.difficulty)
        }
        .gameCard()
    }

    // MARK: - Categories

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                sectionHeader("Categories", systemImage: "rectangle.stack.fill")
                Spacer()
                filterActionButton(
                    select: viewModel.selectedCategories.count != QuoteCategory.allCases.count
                ) {
                    toggleAllCategories()
                }
            }

            FinishTheLineFlowLayout(spacing: AppTheme.Spacing.sm) {
                ForEach(QuoteCategory.allCases) { category in
                    CategoryPill(
                        title: category.displayName,
                        icon: category.iconName,
                        color: theme.accentColor,
                        isSelected: viewModel.selectedCategories.contains(category)
                    ) {
                        viewModel.toggleCategory(category)
                    }
                }
            }
        }
        .gameCard()
    }

    // MARK: - Decades

    private var decadesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                sectionHeader("Decades", systemImage: "clock.arrow.circlepath")
                Spacer()
                filterActionButton(
                    select: viewModel.selectedDecades.count != QuoteDecade.allCases.count
                ) {
                    toggleAllDecades()
                }
            }

            FinishTheLineFlowLayout(spacing: AppTheme.Spacing.sm) {
                ForEach(QuoteDecade.allCases) { decade in
                    CategoryPill(
                        title: decade.displayName,
                        icon: nil,
                        color: theme.accentColor,
                        isSelected: viewModel.selectedDecades.contains(decade)
                    ) {
                        viewModel.toggleDecade(decade)
                    }
                }
            }
        }
        .gameCard()
    }

    // MARK: - Permission

    @ViewBuilder
    private var permissionSection: some View {
        switch viewModel.speechManager.permissionStatus {
        case .notDetermined:
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 36))
                    .foregroundColor(theme.accentColor)

                Text("Microphone Required")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(AppTheme.deepCharcoal)

                Text("Finish the Line listens for the missing word. We need microphone and speech recognition access to play.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.mediumGray)
                    .multilineTextAlignment(.center)

                PrimaryButton(title: "Enable Microphone", icon: "mic.fill") {
                    Task { await viewModel.speechManager.requestPermissions() }
                }
            }
            .gameCard()

        case .denied:
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "mic.slash.fill")
                    .font(.system(size: 36))
                    .foregroundColor(AppTheme.error)

                Text("Microphone Access Denied")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(AppTheme.deepCharcoal)

                Text("Enable microphone and speech recognition for Games with Friends in Settings to play Finish the Line.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.mediumGray)
                    .multilineTextAlignment(.center)

                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    Link(destination: settingsURL) {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "arrow.up.right.square.fill")
                            Text("Open Settings")
                        }
                        .font(AppTheme.Typography.buttonLabel)
                        .foregroundColor(theme.accentColor)
                    }
                }
            }
            .gameCard()

        case .authorized:
            EmptyView()
        }
    }

    // MARK: - Start / best

    private var startSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            if !canStart {
                Text(startDisabledReason)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.warning)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            PrimaryButton(title: "Start Round", icon: "play.fill") {
                viewModel.startGame()
            }
            .disabled(!canStart)
            .opacity(canStart ? 1.0 : 0.45)

            if viewModel.availableQuoteCount > 0 {
                Text("\(viewModel.availableQuoteCount) quotes match your filters")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.mediumGray)
            }

            if viewModel.personalBest > 0 {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "trophy.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.medalGold)
                    Text("Personal best: \(viewModel.personalBest)")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.mediumGray)
                }
                .padding(.top, AppTheme.Spacing.xs)
            }
        }
    }

    // MARK: - Helpers

    private var canStart: Bool {
        viewModel.canStart && viewModel.speechManager.permissionStatus == .authorized
    }

    private var startDisabledReason: String {
        if viewModel.speechManager.permissionStatus != .authorized {
            return "Enable microphone access to start."
        }
        if viewModel.selectedCategories.isEmpty {
            return "Pick at least one category."
        }
        if viewModel.selectedDecades.isEmpty {
            return "Pick at least one decade."
        }
        if viewModel.availableQuoteCount == 0 {
            return "No quotes match your filters. Try loosening one."
        }
        return ""
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundColor(theme.accentColor)
            Text(title)
                .font(AppTheme.Typography.cardTitle)
                .foregroundColor(AppTheme.deepCharcoal)
        }
    }

    private func filterActionButton(select: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(select ? "Select all" : "Clear")
                .font(AppTheme.Typography.caption.weight(.semibold))
                .foregroundColor(theme.accentColor)
        }
    }

    private func toggleAllCategories() {
        if viewModel.selectedCategories.count == QuoteCategory.allCases.count {
            for category in QuoteCategory.allCases {
                viewModel.toggleCategory(category)
            }
        } else {
            for category in QuoteCategory.allCases where !viewModel.selectedCategories.contains(category) {
                viewModel.toggleCategory(category)
            }
        }
    }

    private func toggleAllDecades() {
        if viewModel.selectedDecades.count == QuoteDecade.allCases.count {
            for decade in QuoteDecade.allCases {
                viewModel.toggleDecade(decade)
            }
        } else {
            for decade in QuoteDecade.allCases where !viewModel.selectedDecades.contains(decade) {
                viewModel.toggleDecade(decade)
            }
        }
    }
}

// MARK: - Difficulty segmented button

private struct DifficultySegmentButton: View {
    let difficulty: QuoteDifficulty
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(difficulty.displayName)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(isSelected ? .white : accentColor)

                Text(multiplierLabel)
                    .font(AppTheme.Typography.footnote.weight(.semibold))
                    .foregroundColor(isSelected ? .white.opacity(0.85) : accentColor.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(isSelected ? accentColor : accentColor.opacity(0.10))
            )
        }
        .pressable()
        .accessibilityLabel("\(difficulty.displayName) difficulty, \(multiplierLabel) score multiplier")
    }

    private var multiplierLabel: String {
        String(format: "%.1f×", difficulty.multiplier)
    }
}

// MARK: - Flow layout (for wrapping pills)

/// Simple flow layout that wraps children onto new rows when horizontal space runs out.
/// Local to Finish the Line to avoid collision with the FlowLayout defined in Conversation Starters.
struct FinishTheLineFlowLayout: Layout {
    var spacing: CGFloat = AppTheme.Spacing.sm

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                totalWidth = max(totalWidth, currentX - spacing)
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalWidth = max(totalWidth, currentX - spacing)
        return CGSize(width: totalWidth, height: currentY + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX - bounds.minX + size.width > maxWidth, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
