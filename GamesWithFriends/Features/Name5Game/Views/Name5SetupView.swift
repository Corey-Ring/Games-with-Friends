import SwiftUI

struct Name5SetupView: View {
    @ObservedObject var viewModel: Name5ViewModel

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
                        VStack(spacing: 8) {
                            HStack {
                                Text("\(viewModel.timerDuration) seconds")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Spacer()
                            }

                            Picker("Timer Duration", selection: Binding(
                                get: { viewModel.timerDuration },
                                set: { viewModel.updateConfiguration(duration: $0) }
                            )) {
                                Text("20s").tag(20)
                                Text("30s").tag(30)
                                Text("45s").tag(45)
                                Text("60s").tag(60)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }

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

                Spacer(minLength: 40)
            }
            .padding()
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
