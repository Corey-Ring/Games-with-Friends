import SwiftUI

struct Name5SetupView: View {
    @Bindable var viewModel: Name5ViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "hand.raised.fingers.spread.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Name 5")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Race against the clock to name 5 things!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Social Context Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Playing with...")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Age Group")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("Difficulty")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
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
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Timer")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Toggle("", isOn: $viewModel.timerEnabled)
                            .labelsHidden()
                    }

                    if viewModel.timerEnabled {
                        VStack(spacing: 12) {
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
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }

                // Category Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Categories")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Select which categories to include")
                        .font(.caption)
                        .foregroundColor(.secondary)

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
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.05))
                )

                // Player Count
                VStack(alignment: .leading, spacing: 12) {
                    Text("Number of Players")
                        .font(.headline)
                        .foregroundColor(.secondary)

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
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                    )
                }

                // Start Button
                Button(action: {
                    viewModel.startGame()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Quick Play")
                            .fontWeight(.bold)
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .disabled(!viewModel.canStart)
                .opacity(viewModel.canStart ? 1.0 : 0.6)
                .padding(.bottom, 20)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
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
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? selectedFill : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
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
            VStack(spacing: 12) {
                Image(systemName: context.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .blue)

                VStack(spacing: 4) {
                    Text(context.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(context.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ?
                          LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color.gray.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
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
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .purple)
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.purple : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
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
                    .foregroundColor(isSelected ? .white : .blue)

                Text(ageGroup.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}
