import SwiftUI

struct HomeView: View {
    @State private var viewModel = GameViewModel()
    @State private var showingGame = false
    @State private var showingSettings = false
    @State private var showingSavedStarters = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Content column is wide; motifs keep to the edges and top
                // strip, ≥12pt clear of the interactive cards (§7).
                MotifGroundView(exclusions: [CGRect(x: 8, y: 60,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 60)])
            }
            .ignoresSafeArea()

            ScrollView {
                    VStack(spacing: 30) {
                        // Header: spot plate + framed Lilita title (Rule 4 —
                        // game names exceed the ~8-char Shrikhand cap).
                        VStack(spacing: AppTheme.Spacing.sm) {
                            ZStack {
                                Circle().fill(AppTheme.Retro.panel)
                                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                                RetroSpotIllustration(kind: .speechBubbles)
                                    .frame(width: 64, height: 64)
                            }
                            .frame(width: 84, height: 84)

                            Text("Conversation Starters")
                                .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                                .foregroundColor(AppTheme.Retro.ink)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppTheme.Spacing.md)
                                .padding(.vertical, AppTheme.Spacing.xs)
                                .retroPanel(ConversationStartersStyle.accent)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                                        .fill(AppTheme.Retro.ink)
                                        .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
                                )
                                .rotationEffect(.degrees(-1))

                            Text("Break the ice and spark great conversations")
                                .font(AppTheme.Typography.secondary)
                                .foregroundColor(AppTheme.Retro.panelText)
                                .multilineTextAlignment(.center)
                                .retroLozenge()
                                .rotationEffect(.degrees(0.8))
                        }
                        .padding(.top, AppTheme.Spacing.lg)

                        // Player Count
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Number of Players", systemImage: "person.3.fill")
                                .font(AppTheme.Retro.Typography.cardTitle)
                                .foregroundColor(AppTheme.Retro.panelText)

                            HStack {
                                Button(action: {
                                    if viewModel.settings.playerCount > 2 {
                                        viewModel.settings.playerCount -= 1
                                    }
                                }) {
                                    Image(systemName: "minus")
                                        .font(AppTheme.Typography.cardTitle.weight(.black))
                                        .foregroundColor(AppTheme.Retro.ink)
                                        .frame(width: 44, height: 44)
                                        .background(Circle().fill(ConversationStartersStyle.accent))
                                        .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth))
                                }
                                .disabled(viewModel.settings.playerCount <= 2)
                                .opacity(viewModel.settings.playerCount <= 2 ? 0.35 : 1)

                                Text("\(viewModel.settings.playerCount)")
                                    .font(AppTheme.Typography.screenTitle)
                                    .foregroundColor(AppTheme.Retro.panelText)
                                    .frame(minWidth: 50)

                                Button(action: {
                                    viewModel.settings.playerCount += 1
                                }) {
                                    Image(systemName: "plus")
                                        .font(AppTheme.Typography.cardTitle.weight(.black))
                                        .foregroundColor(AppTheme.Retro.ink)
                                        .frame(width: 44, height: 44)
                                        .background(Circle().fill(ConversationStartersStyle.accent))
                                        .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .retroCard()

                        // Vibe Level
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Vibe Level", systemImage: "waveform")
                                .font(AppTheme.Retro.Typography.cardTitle)
                                .foregroundColor(AppTheme.Retro.panelText)

                            VStack(alignment: .leading, spacing: 5) {
                                Slider(value: Binding(
                                    get: { Double(viewModel.settings.vibeLevel) },
                                    set: { viewModel.settings.vibeLevel = Int($0) }
                                ), in: 1...5, step: 1)
                                .tint(ConversationStartersStyle.vibeColor(viewModel.settings.vibeLevel))

                                HStack {
                                    ForEach(1...5, id: \.self) { level in
                                        Text(vibeLevelName(for: level))
                                            .font(AppTheme.Typography.caption)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .foregroundColor(AppTheme.Retro.cocoa)
                            }

                            Text(vibeLevelDescription(for: viewModel.settings.vibeLevel))
                                .font(AppTheme.Typography.secondary)
                                .foregroundColor(AppTheme.Retro.cocoa)
                                .padding(.top, AppTheme.Spacing.xs)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .retroCard()

                        // Category Filter
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Categories", systemImage: "tag.fill")
                                .font(AppTheme.Retro.Typography.cardTitle)
                                .foregroundColor(AppTheme.Retro.panelText)

                            FlowLayout(spacing: 10) {
                                ForEach(Category.allCases, id: \.self) { category in
                                    RetroCategoryPill(
                                        title: category.rawValue,
                                        icon: category.icon,
                                        color: ConversationStartersStyle.accent,
                                        isSelected: viewModel.settings.selectedCategories.contains(category),
                                        action: {
                                            if viewModel.settings.selectedCategories.contains(category) {
                                                viewModel.settings.selectedCategories.remove(category)
                                            } else {
                                                viewModel.settings.selectedCategories.insert(category)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .retroCard()

                        // Theme Filter
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Themes", systemImage: "sparkles")
                                .font(AppTheme.Retro.Typography.cardTitle)
                                .foregroundColor(AppTheme.Retro.panelText)

                            FlowLayout(spacing: 10) {
                                ForEach(Theme.allCases, id: \.self) { theme in
                                    RetroCategoryPill(
                                        title: theme.rawValue,
                                        icon: theme.icon,
                                        color: ConversationStartersStyle.accent,
                                        isSelected: viewModel.settings.selectedThemes.contains(theme),
                                        action: {
                                            if viewModel.settings.selectedThemes.contains(theme) {
                                                viewModel.settings.selectedThemes.remove(theme)
                                            } else {
                                                viewModel.settings.selectedThemes.insert(theme)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .retroCard()

                        // Start Button
                        RetroPrimaryButton(title: "Start Game", icon: "play.fill",
                                           accent: ConversationStartersStyle.accent) {
                            viewModel.updateFilteredStarters()
                            showingGame = true
                        }
                        .padding(.bottom, AppTheme.Spacing.lg)
                    }
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingSavedStarters = true }) {
                            Image(systemName: "star.fill")
                                .foregroundColor(AppTheme.Retro.ink)
                        }
                        .accessibilityLabel("Saved starters")
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                                .foregroundColor(AppTheme.Retro.ink)
                        }
                        .accessibilityLabel("Settings")
                    }
                }
            }
            .sheet(isPresented: $showingGame) {
                GameView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSavedStarters) {
                SavedStartersView(viewModel: viewModel)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .inactive || newPhase == .background {
                    viewModel.pauseTimer()
                }
            }
    }

    private func vibeLevelName(for level: Int) -> String {
        switch level {
        case 1: return "Ice"
        case 2: return "Casual"
        case 3: return "Fun"
        case 4: return "Deep"
        case 5: return "Daring"
        default: return ""
        }
    }

    private func vibeLevelDescription(for level: Int) -> String {
        switch level {
        case 1: return "Work-appropriate, light topics"
        case 2: return "Friendly get-togethers"
        case 3: return "Playful, hypotheticals"
        case 4: return "Deeper, more revealing questions"
        case 5: return "Silly, absurd, or bold questions"
        default: return ""
        }
    }
}

// Simple flow layout for wrapping pills
struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
