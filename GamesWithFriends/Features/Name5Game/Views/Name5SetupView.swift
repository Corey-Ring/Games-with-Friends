import SwiftUI

struct Name5SetupView: View {
    @Bindable var viewModel: Name5ViewModel

    var body: some View {
        ZStack {
            WarmLinenBackground()
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "hand.raised.fingers.spread.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(GameTheme.name5.accentColor)

                        Text("Name 5")
                            .font(AppTheme.Typography.hero)
                            .fontWeight(.bold)

                        Text("Race against the clock to name 5 things!")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.mediumGray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppTheme.Spacing.lg)

                    // Social Context Selection
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Playing with...")
                            .font(AppTheme.Typography.cardTitle)
                            .foregroundColor(AppTheme.mediumGray)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
                            ForEach(SocialContext.allCases, id: \.self) { context in
                                ContextCard(
                                    context: context,
                                    isSelected: viewModel.socialContext == context
                                ) {
                                    viewModel.updateConfiguration(context: context)
                                }
                            }
                        }
                    }

                    // Age Group Selection (show only for family or all ages)
                    if viewModel.socialContext == .family {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("Age Group")
                                .font(AppTheme.Typography.cardTitle)
                                .foregroundColor(AppTheme.mediumGray)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
                                ForEach(AgeGroup.allCases, id: \.self) { age in
                                    AgeGroupCard(
                                        ageGroup: age,
                                        isSelected: viewModel.ageGroup == age
                                    ) {
                                        viewModel.updateConfiguration(age: age)
                                    }
                                }
                            }
                        }
                    }

                    // Difficulty Selection
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Difficulty")
                            .font(AppTheme.Typography.cardTitle)
                            .foregroundColor(AppTheme.mediumGray)

                        HStack(spacing: AppTheme.Spacing.md) {
                            DifficultyToggle(
                                difficulty: .easy,
                                isSelected: viewModel.selectedDifficulties.contains(.easy)
                            ) {
                                viewModel.toggleDifficulty(.easy)
                            }

                            DifficultyToggle(
                                difficulty: .medium,
                                isSelected: viewModel.selectedDifficulties.contains(.medium)
                            ) {
                                viewModel.toggleDifficulty(.medium)
                            }

                            DifficultyToggle(
                                difficulty: .hard,
                                isSelected: viewModel.selectedDifficulties.contains(.hard)
                            ) {
                                viewModel.toggleDifficulty(.hard)
                            }
                        }
                    }

                    // Timer Settings
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack {
                            Text("Timer")
                                .font(AppTheme.Typography.cardTitle)
                                .foregroundColor(AppTheme.mediumGray)

                            Spacer()

                            Toggle("", isOn: $viewModel.timerEnabled)
                                .labelsHidden()
                        }

                        if viewModel.timerEnabled {
                            VStack(spacing: AppTheme.Spacing.md) {
                                Picker("Timer Duration", selection: Binding(
                                    get: { viewModel.timerDuration },
                                    set: { viewModel.updateConfiguration(duration: $0) }
                                )) {
                                    Text("15s").tag(15)
                                    Text("30s").tag(30)
                                    Text("45s").tag(45)
                                    Text("60s").tag(60)
                                }
                                .pickerStyle(.segmented)

                                Text(timerDescription(for: viewModel.timerDuration))
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.mediumGray)
                            }
                            .gameCard()
                        }
                    }

                    // Category Selection
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Categories")
                            .font(AppTheme.Typography.cardTitle)
                            .foregroundColor(AppTheme.mediumGray)

                        Text("Select which categories to include")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.mediumGray)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(PromptCategory.allCases, id: \.self) { category in
                                CategorySelectionCard(
                                    category: category,
                                    isSelected: viewModel.selectedCategories.contains(category)
                                ) {
                                    viewModel.toggleCategory(category)
                                }
                            }
                        }
                    }
                    .gameCard()

                    // Player Count
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Number of Players")
                            .font(AppTheme.Typography.cardTitle)
                            .foregroundColor(AppTheme.mediumGray)

                        HStack {
                            Text("\(viewModel.playerCount) \(viewModel.playerCount == 1 ? "Player" : "Players")")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Spacer()
                        }

                        Stepper("", value: Binding(
                            get: { viewModel.playerCount },
                            set: { viewModel.updateConfiguration(players: $0) }
                        ), in: 1...20)
                        .labelsHidden()
                    }

                    // Available Prompts Info
                    if !viewModel.availablePrompts.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("\(viewModel.availablePrompts.count) prompts available")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.mediumGray)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                .fill(Color.green.opacity(0.1))
                        )
                    }

                    // Start Button
                    PrimaryButton(title: "Quick Play", icon: "play.fill") {
                        viewModel.startGame()
                    }
                    .disabled(!viewModel.canStart)
                    .opacity(viewModel.canStart ? 1.0 : 0.6)
                    .padding(.bottom, AppTheme.Spacing.lg)
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
    }

    private func timerDescription(for duration: Int) -> String {
        switch duration {
        case 15: return "Sprint mode — fast and frantic"
        case 30: return "Standard — a good challenge"
        case 45: return "Relaxed — plenty of time to think"
        case 60: return "Easy going — no rush at all"
        default: return "\(duration) seconds per round"
        }
    }
}

// MARK: - Difficulty Toggle
struct DifficultyToggle: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                HStack(spacing: 2) {
                    ForEach(0..<starCount, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(isSelected ? .white : starColor)
                    }
                }

                Text(difficulty.rawValue)
                    .font(AppTheme.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : AppTheme.deepCharcoal)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(isSelected ? selectedFill : AppTheme.pureWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .stroke(isSelected ? Color.clear : AppTheme.mediumGray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.black.opacity(0.1) : Color.clear, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var starCount: Int {
        switch difficulty {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }

    private var starColor: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }

    private var selectedFill: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - Context Card
struct ContextCard: View {
    let context: SocialContext
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: context.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : GameTheme.name5.accentColor)

                VStack(spacing: 4) {
                    Text(context.rawValue)
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(isSelected ? .white : AppTheme.deepCharcoal)

                    Text(context.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : AppTheme.mediumGray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .fill(isSelected ? GameTheme.name5.accentColor : AppTheme.pureWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .stroke(isSelected ? Color.clear : AppTheme.mediumGray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.black.opacity(0.15) : AppTheme.Shadow.cardColor, radius: AppTheme.Shadow.cardRadius, y: AppTheme.Shadow.cardY)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Selection Card
struct CategorySelectionCard: View {
    let category: PromptCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : GameTheme.name5.accentColor)
                
                Text(category.rawValue)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : AppTheme.deepCharcoal)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? GameTheme.name5.accentColor : AppTheme.pureWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : AppTheme.mediumGray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Age Group Card
struct AgeGroupCard: View {
    let ageGroup: AgeGroup
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: ageGroup.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : GameTheme.name5.accentColor)

                Text(ageGroup.rawValue)
                    .font(AppTheme.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : AppTheme.deepCharcoal)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(isSelected ? GameTheme.name5.accentColor : AppTheme.pureWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .stroke(isSelected ? Color.clear : AppTheme.mediumGray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.black.opacity(0.1) : Color.clear, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}
