import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var showingGame = false
    @State private var showingSettings = false
    @State private var showingSavedStarters = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
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
                                .foregroundColor(.purple)

                            Text("Conversation Starters")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("Break the ice and spark great conversations")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)

                        // Player Count
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Number of Players", systemImage: "person.3.fill")
                                .font(.headline)

                            HStack {
                                Button(action: {
                                    if viewModel.settings.playerCount > 2 {
                                        viewModel.settings.playerCount -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                }
                                .disabled(viewModel.settings.playerCount <= 2)

                                Text("\(viewModel.settings.playerCount)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .frame(minWidth: 50)

                                Button(action: {
                                    viewModel.settings.playerCount += 1
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                }
                            }
                            .foregroundColor(.purple)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)

                        // Vibe Level
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Vibe Level", systemImage: "waveform")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 5) {
                                Slider(value: Binding(
                                    get: { Double(viewModel.settings.vibeLevel) },
                                    set: { viewModel.settings.vibeLevel = Int($0) }
                                ), in: 1...5, step: 1)
                                .accentColor(vibeColor(for: viewModel.settings.vibeLevel))

                                HStack {
                                    ForEach(1...5, id: \.self) { level in
                                        Text(vibeLevelName(for: level))
                                            .font(.caption)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .foregroundColor(.secondary)
                            }

                            Text(vibeLevelDescription(for: viewModel.settings.vibeLevel))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 5)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)

                        // Category Filter
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Categories", systemImage: "tag.fill")
                                .font(.headline)

                            FlowLayout(spacing: 10) {
                                ForEach(Category.allCases, id: \.self) { category in
                                    CategoryChip(
                                        category: category,
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
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)

                        // Theme Filter
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Themes", systemImage: "sparkles")
                                .font(.headline)

                            FlowLayout(spacing: 10) {
                                ForEach(Theme.allCases, id: \.self) { theme in
                                    ThemeChip(
                                        theme: theme,
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
                        .background(Color.white)
                        .cornerRadius(15)
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
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                        }
                        .shadow(radius: 5)

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingSavedStarters = true }) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                        }
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
    }

    private func vibeColor(for level: Int) -> Color {
        switch level {
        case 1: return .blue
        case 2: return .green
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .blue
        }
    }

    private func vibeLevelName(for level: Int) -> String {
        switch level {
        case 1: return "Ice"
        case 2: return "Casual"
        case 3: return "Fun"
        case 4: return "Spicy"
        case 5: return "Wild"
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

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.purple : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct ThemeChip: View {
    let theme: Theme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: theme.icon)
                    .font(.caption)
                Text(theme.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// Simple flow layout for wrapping chips
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
