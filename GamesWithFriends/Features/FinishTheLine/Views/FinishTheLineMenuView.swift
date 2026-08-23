//
//  FinishTheLineMenuView.swift
//  GamesWithFriends
//

import SwiftUI

struct FinishTheLineMenuView: View {
    @Bindable var viewModel: FinishTheLineViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Setup column (header + filter cards + CTA) owns the width;
                // motifs keep to the nav strip and the outer gutters, ≥12pt
                // clear of every pill (§7 — the generator adds the clearance).
                MotifGroundView(seed: 0xFA11_0E01,
                                exclusions: [CGRect(x: 8, y: 56,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 56)])
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    headerSection
                        .staggeredAppear(index: 0)

                    difficultySection
                        .staggeredAppear(index: 1)

                    categoriesSection
                        .staggeredAppear(index: 2)

                    decadesSection
                        .staggeredAppear(index: 3)

                    permissionSection
                        .staggeredAppear(index: 4)

                    startSection
                        .staggeredAppear(index: 5)
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
    //
    // Spot plate + framed Lilita title (§3 recipe). The old gradient hero
    // circle with the SF `quote.bubble.fill` inside it is retired (§9) — the
    // clapperboard spot carries the identity now.

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            FinishTheLineSpotPlate()

            FinishTheLineTitlePanel(text: "Finish the Line")

            Text("Speak the missing word. Beat the clock.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Retro.panelText)
                .multilineTextAlignment(.center)
                .retroLozenge()
                .rotationEffect(.degrees(0.8))
        }
        .padding(.top, AppTheme.Spacing.sm)
    }

    // MARK: - Difficulty

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionHeader("Difficulty", systemImage: "gauge.with.needle.fill")

            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(QuoteDifficulty.allCases) { difficulty in
                    DifficultySegmentButton(
                        difficulty: difficulty,
                        isSelected: viewModel.difficulty == difficulty
                    ) {
                        viewModel.setDifficulty(difficulty)
                    }
                }
            }

            Text(viewModel.difficulty.tagline)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.cocoa)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
                .id(viewModel.difficulty)
        }
        .retroCard()
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
                    // §8 plum rule: the selected pill fills plum, so its label
                    // has to be cream — ink fails on this one accent.
                    RetroCategoryPill(
                        title: category.displayName,
                        icon: category.iconName,
                        color: FinishTheLineStyle.accent,
                        isSelected: viewModel.selectedCategories.contains(category),
                        selectedTextColor: FinishTheLineStyle.chipTextColor(on: FinishTheLineStyle.accent)
                    ) {
                        viewModel.toggleCategory(category)
                    }
                }
            }
        }
        .retroCard()
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
                    RetroCategoryPill(
                        title: decade.displayName,
                        icon: nil,
                        color: FinishTheLineStyle.accent,
                        isSelected: viewModel.selectedDecades.contains(decade),
                        selectedTextColor: FinishTheLineStyle.chipTextColor(on: FinishTheLineStyle.accent)
                    ) {
                        viewModel.toggleDecade(decade)
                    }
                }
            }
        }
        .retroCard()
    }

    // MARK: - Permission

    @ViewBuilder
    private var permissionSection: some View {
        switch viewModel.speechManager.permissionStatus {
        case .notDetermined:
            VStack(spacing: AppTheme.Spacing.md) {
                // Functional glyph on a cream plate with a hard ink offset —
                // there is no mic spot illustration, and §9 forbids a naked SF
                // hero floating on the card.
                glyphPlate("mic.fill", tint: FinishTheLineStyle.accent)

                Text("Microphone Required")
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText)

                Text("Finish the Line listens for the missing word. We need microphone and speech recognition access to play.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .multilineTextAlignment(.center)

                RetroPrimaryButton(
                    title: "Enable Microphone",
                    icon: "mic.fill",
                    accent: FinishTheLineStyle.accent,
                    textColor: FinishTheLineStyle.chipTextColor(on: FinishTheLineStyle.accent)
                ) {
                    Task { await viewModel.speechManager.requestPermissions() }
                }
            }
            .retroCard()

        case .denied:
            VStack(spacing: AppTheme.Spacing.md) {
                glyphPlate("mic.slash.fill", tint: FinishTheLineStyle.dangerColor)

                Text("Microphone Access Denied")
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText)

                Text("Enable microphone and speech recognition for Games with Friends in Settings to play Finish the Line.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .multilineTextAlignment(.center)

                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    Link(destination: settingsURL) {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "arrow.up.right.square.fill")
                            Text("Open Settings")
                        }
                        .font(AppTheme.Retro.Typography.heading(16, relativeTo: .subheadline))
                        .foregroundColor(FinishTheLineStyle.chipTextColor(on: FinishTheLineStyle.accent))
                        .retroLozenge(FinishTheLineStyle.accent)
                    }
                }
            }
            .retroCard()

        case .authorized:
            EmptyView()
        }
    }

    // MARK: - Start / best

    private var startSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            if !canStart {
                // Body copy never sits bare on the ground (§8) — lozenge it.
                Text(startDisabledReason)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(FinishTheLineStyle.skippedColor)
                    .multilineTextAlignment(.center)
                    .retroLozenge()
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            RetroPrimaryButton(
                title: "Start Round",
                icon: "play.fill",
                accent: FinishTheLineStyle.accent,
                textColor: FinishTheLineStyle.chipTextColor(on: FinishTheLineStyle.accent)
            ) {
                viewModel.startGame()
            }
            .disabled(!canStart)
            .opacity(canStart ? 1.0 : 0.45)

            if viewModel.availableQuoteCount > 0 {
                Text("\(viewModel.availableQuoteCount) quotes match your filters")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .retroLozenge()
            }

            if viewModel.personalBest > 0 {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "trophy.fill")
                        .font(.caption)
                        .foregroundColor(FinishTheLineStyle.bestColor)
                    Text("Personal best: \(viewModel.personalBest)")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Retro.panelText)
                }
                .retroLozenge()
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

    private func glyphPlate(_ systemImage: String, tint: Color) -> some View {
        ZStack {
            Circle().fill(AppTheme.Retro.panel)
            Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
            Image(systemName: systemImage)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(tint)
        }
        .frame(width: 72, height: 72)
        .background(
            Circle()
                .fill(AppTheme.Retro.ink)
                .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
        )
        .accessibilityHidden(true)
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundColor(AppTheme.Retro.panelText)
            Text(title)
                .font(AppTheme.Retro.Typography.cardTitle)
                .foregroundColor(AppTheme.Retro.panelText)
        }
    }

    private func filterActionButton(select: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(select ? "Select all" : "Clear")
                .font(AppTheme.Retro.Typography.pillLabel)
                .foregroundColor(FinishTheLineStyle.accent)
        }
        .buttonStyle(.plain)
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(difficulty.displayName)
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(labelColor)

                Text(multiplierLabel)
                    .font(AppTheme.Typography.footnote.weight(.semibold))
                    .foregroundColor(labelColor.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            // Selected fills plum (cream label, §8); unselected drops to a
            // cream panel with ink text, same as the letter grid in Country
            // Letter Challenge.
            .retroPanel(isSelected ? FinishTheLineStyle.accent : AppTheme.Retro.panel,
                        cornerRadius: AppTheme.Retro.Radius.inner)
        }
        .buttonStyle(RetroRaisedButtonStyle(cornerRadius: AppTheme.Retro.Radius.inner))
        .accessibilityLabel("\(difficulty.displayName) difficulty, \(multiplierLabel) per correct answer")
    }

    private var labelColor: Color {
        isSelected
            ? FinishTheLineStyle.chipTextColor(on: FinishTheLineStyle.accent)
            : AppTheme.Retro.panelText
    }

    private var multiplierLabel: String {
        "\(FinishTheLineViewModel.pointsPerCorrect(for: difficulty)) pts"
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
