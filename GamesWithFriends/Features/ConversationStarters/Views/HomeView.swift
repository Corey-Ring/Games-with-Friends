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
            LinearGradient(
                colors: [GameTheme.conversationStarters.accentColor.opacity(0.15), GameTheme.conversationStarters.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 60))
                                .foregroundColor(GameTheme.conversationStarters.accentColor)

                            Text("Conversation Starters")
                                .font(AppTheme.Typography.hero)

                            Text("Break the ice and spark great conversations")
                                .font(AppTheme.Typography.secondary)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)

                        // Player Count
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Number of Players", systemImage: "person.3.fill")
                                .font(AppTheme.Typography.cardTitle)

                            HStack {
                                Button(action: {
                                    if viewModel.settings.playerCount > 2 {
                                        viewModel.settings.playerCount -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(AppTheme.Typography.sectionHeader)
                                }
                                .disabled(viewModel.settings.playerCount <= 2)

                                Text("\(viewModel.settings.playerCount)")
                                    .font(AppTheme.Typography.screenTitle)
                                    .frame(minWidth: 50)

                                Button(action: {
                                    viewModel.settings.playerCount += 1
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(AppTheme.Typography.sectionHeader)
                                }
                            }
                            .foregroundColor(GameTheme.conversationStarters.accentColor)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
                        .shadow(radius: 5)

                        // Vibe Level
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Vibe Level", systemImage: "waveform")
                                .font(AppTheme.Typography.cardTitle)

                            VStack(alignment: .leading, spacing: 5) {
                                Slider(value: Binding(
                                    get: { Double(viewModel.settings.vibeLevel) },
                                    set: { viewModel.settings.vibeLevel = Int($0) }
                                ), in: 1...5, step: 1)
                                .accentColor(vibeColor(for: viewModel.settings.vibeLevel))

                                HStack {
                                    ForEach(1...5, id: \.self) { level in
                                        Text(vibeLevelName(for: level))
                                            .font(AppTheme.Typography.caption)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .foregroundColor(.secondary)
                            }

                            Text(vibeLevelDescription(for: viewModel.settings.vibeLevel))
                                .font(AppTheme.Typography.secondary)
                                .foregroundColor(.secondary)
                                .padding(.top, AppTheme.Spacing.xs)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
                        .shadow(radius: 5)

                        // Category Filter
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Categories", systemImage: "tag.fill")
                                .font(AppTheme.Typography.cardTitle)

                            FlowLayout(spacing: 10) {
                                ForEach(Category.allCases, id: \.self) { category in
                                    CategoryPill(
                                        title: category.rawValue,
                                        icon: category.icon,
                                        color: GameTheme.conversationStarters.accentColor,
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
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
                        .shadow(radius: 5)

                        // Theme Filter
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Themes", systemImage: "sparkles")
                                .font(AppTheme.Typography.cardTitle)

                            FlowLayout(spacing: 10) {
                                ForEach(Theme.allCases, id: \.self) { theme in
                                    CategoryPill(
                                        title: theme.rawValue,
                                        icon: theme.icon,
                                        color: GameTheme.conversationStarters.accentColor,
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
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
                        .shadow(radius: 5)

                        // Start Button
                        Button(action: {
                            viewModel.updateFilteredStarters()
                            showingGame = true
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Game")
                                    .fontWeight(.semibold)
                            }
                            .font(AppTheme.Typography.sectionHeader)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [GameTheme.conversationStarters.accentColor, GameTheme.conversationStarters.darkAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
                        }
                        .shadow(radius: 5)
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
                                .foregroundColor(.yellow)
                        }
                        .accessibilityLabel("Saved starters")
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
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

    private func vibeColor(for level: Int) -> Color {
        switch level {
        case 1: return GameTheme.conversationStarters.accentColor
        case 2: return .green
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return GameTheme.conversationStarters.accentColor
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
