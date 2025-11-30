import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    @State private var dragOffset: CGSize = .zero
    @State private var showingResetAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                if viewModel.filteredStarters.isEmpty {
                    emptyStateView
                } else if let starter = viewModel.currentStarter {
                    VStack(spacing: 20) {
                        // Progress indicator
                        HStack {
                            Text("\(viewModel.currentIndex + 1) of \(viewModel.filteredStarters.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            // Timer display
                            if viewModel.settings.timerEnabled {
                                timerView
                            }
                        }
                        .padding(.horizontal)

                        Spacer()

                        // Card
                        CardView(
                            starter: starter,
                            isStarred: viewModel.isStarred(starter),
                            onStar: { viewModel.toggleStar(starter) }
                        )
                        .offset(dragOffset)
                        .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    dragOffset = gesture.translation
                                }
                                .onEnded { gesture in
                                    if abs(gesture.translation.width) > 100 {
                                        if gesture.translation.width > 0 && viewModel.hasPrevious {
                                            withAnimation(.spring()) {
                                                viewModel.previousStarter()
                                            }
                                        } else if gesture.translation.width < 0 && viewModel.hasNext {
                                            withAnimation(.spring()) {
                                                viewModel.nextStarter()
                                            }
                                        }
                                    }
                                    withAnimation(.spring()) {
                                        dragOffset = .zero
                                    }
                                }
                        )

                        Spacer()

                        // Navigation buttons
                        HStack(spacing: 40) {
                            Button(action: {
                                withAnimation(.spring()) {
                                    viewModel.previousStarter()
                                }
                            }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(viewModel.hasPrevious ? .purple : .gray.opacity(0.3))
                            }
                            .disabled(!viewModel.hasPrevious)

                            if viewModel.settings.timerEnabled {
                                Button(action: {
                                    withAnimation(.spring()) {
                                        viewModel.nextStarter()
                                    }
                                }) {
                                    VStack {
                                        Image(systemName: "forward.fill")
                                            .font(.system(size: 30))
                                        Text("Pass")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.orange)
                                }
                            }

                            Button(action: {
                                withAnimation(.spring()) {
                                    viewModel.nextStarter()
                                }
                            }) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(viewModel.hasNext ? .purple : .gray.opacity(0.3))
                            }
                            .disabled(!viewModel.hasNext)
                        }
                        .padding(.bottom, 30)
                    }
                } else {
                    allDoneView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Home")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            viewModel.shuffle()
                        }) {
                            Label("Shuffle", systemImage: "shuffle")
                        }
                        Button(action: {
                            showingResetAlert = true
                        }) {
                            Label("Reset Deck", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Reset Deck?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    viewModel.resetDeck()
                }
            } message: {
                Text("This will mark all cards as unseen and reshuffle the deck.")
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                vibeColor.opacity(0.3),
                vibeColor.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var vibeColor: Color {
        switch viewModel.settings.vibeLevel {
        case 1: return .blue
        case 2: return .green
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .blue
        }
    }

    private var timerView: some View {
        HStack(spacing: 5) {
            Image(systemName: viewModel.isTimerRunning ? "timer" : "pause.circle")
                .foregroundColor(viewModel.timeRemaining < 10 ? .red : .primary)
            Text(timeString(from: viewModel.timeRemaining))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(viewModel.timeRemaining < 10 ? .red : .primary)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.9))
        .cornerRadius(15)
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("No Starters Available")
                .font(.title2)
                .fontWeight(.bold)

            Text("Try adjusting your filters or adding more categories")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { dismiss() }) {
                Text("Back to Settings")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(10)
            }
        }
        .padding()
    }

    private var allDoneView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("All Done!")
                .font(.title)
                .fontWeight(.bold)

            Text("You've seen all the conversation starters")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: {
                viewModel.resetDeck()
            }) {
                Text("Start Over")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct CardView: View {
    let starter: ConversationStarter
    let isStarred: Bool
    let onStar: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header with category and star
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: starter.category.icon)
                        .font(.caption)
                    Text(starter.category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(categoryColor.opacity(0.2))
                .foregroundColor(categoryColor)
                .cornerRadius(15)

                Spacer()

                Button(action: onStar) {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(isStarred ? .yellow : .gray)
                }
            }
            .padding()

            Spacer()

            // Question text
            Text(starter.text)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer()

            // Footer with vibe level and themes
            VStack(spacing: 10) {
                HStack(spacing: 5) {
                    ForEach(1...5, id: \.self) { level in
                        Circle()
                            .fill(level <= starter.vibeLevel ? vibeColor : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }

                if !starter.themes.filter({ $0 != .evergreen }).isEmpty {
                    HStack(spacing: 5) {
                        ForEach(starter.themes.filter { $0 != .evergreen }, id: \.self) { theme in
                            HStack(spacing: 3) {
                                Image(systemName: theme.icon)
                                    .font(.caption2)
                                Text(theme.rawValue)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 500)
        .background(Color.white)
        .cornerRadius(25)
        .shadow(radius: 10)
        .padding(.horizontal, 30)
    }

    private var categoryColor: Color {
        switch starter.category {
        case .wouldYouRather: return .purple
        case .hotTakes: return .red
        case .hypotheticals: return .orange
        case .storyTime: return .blue
        case .thisOrThat: return .green
        case .deepDive: return .indigo
        }
    }

    private var vibeColor: Color {
        switch starter.vibeLevel {
        case 1: return .blue
        case 2: return .green
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .blue
        }
    }
}
