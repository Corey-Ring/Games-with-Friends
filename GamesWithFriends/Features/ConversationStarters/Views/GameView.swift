import SwiftUI

struct GameView: View {
    var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOffset: CGSize = .zero
    @State private var showingResetAlert = false

    /// Runs a state change with a spring animation, or immediately when Reduce Motion is on.
    private func withNavAnimation(_ action: () -> Void) {
        if reduceMotion {
            action()
        } else {
            withAnimation(.spring()) {
                action()
            }
        }
    }

    var body: some View {
        NavigationStack {
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
                                .font(AppTheme.Typography.caption)
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
                        .rotationEffect(.degrees(reduceMotion ? 0 : Double(dragOffset.width / 20)))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    dragOffset = gesture.translation
                                }
                                .onEnded { gesture in
                                    if abs(gesture.translation.width) > 100 {
                                        if gesture.translation.width > 0 && viewModel.hasPrevious {
                                            withNavAnimation {
                                                viewModel.previousStarter()
                                            }
                                        } else if gesture.translation.width < 0 {
                                            // Swiping past the last card reaches "All Done"
                                            withNavAnimation {
                                                viewModel.nextStarter()
                                            }
                                        }
                                    }
                                    withNavAnimation {
                                        dragOffset = .zero
                                    }
                                }
                        )

                        Spacer()

                        // Navigation buttons
                        HStack(spacing: 40) {
                            Button(action: {
                                withNavAnimation {
                                    viewModel.previousStarter()
                                }
                            }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(viewModel.hasPrevious ? GameTheme.conversationStarters.accentColor : AppTheme.mediumGray.opacity(0.3))
                            }
                            .disabled(!viewModel.hasPrevious)
                            .accessibilityLabel("Previous conversation starter")

                            if viewModel.settings.timerEnabled {
                                Button(action: {
                                    withNavAnimation {
                                        viewModel.nextStarter()
                                    }
                                }) {
                                    VStack {
                                        Image(systemName: "forward.fill")
                                            .font(.system(size: 30))
                                        Text("Pass")
                                            .font(AppTheme.Typography.caption)
                                    }
                                    .foregroundColor(AppTheme.warning)
                                }
                                .accessibilityLabel("Pass and skip to next")
                            }

                            // Stays enabled on the last card — advancing past it
                            // shows the "All Done" screen.
                            Button(action: {
                                withNavAnimation {
                                    viewModel.nextStarter()
                                }
                            }) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(GameTheme.conversationStarters.accentColor)
                            }
                            .accessibilityLabel("Next conversation starter")
                        }
                        .padding(.bottom, AppTheme.Spacing.xl)
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
            .onAppear {
                // Start the round timer for the first card — nothing else does.
                // Only when a card is actually showing; an empty deck / All Done
                // screen must not run a countdown that fires with no card.
                if viewModel.currentStarter != nil {
                    viewModel.resetTimer()
                }
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
        case 1: return GameTheme.conversationStarters.accentColor
        case 2: return AppTheme.success
        case 3: return AppTheme.medalGold
        case 4: return AppTheme.warning
        case 5: return AppTheme.error
        default: return GameTheme.conversationStarters.accentColor
        }
    }

    private var timerView: some View {
        HStack(spacing: 5) {
            Image(systemName: viewModel.isTimerRunning ? "timer" : "pause.circle")
                .foregroundColor(viewModel.timeRemaining < 10 ? AppTheme.error : .primary)
            Text(timeString(from: viewModel.timeRemaining))
                .font(AppTheme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(viewModel.timeRemaining < 10 ? AppTheme.error : .primary)
                .monospacedDigit()
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(AppTheme.cardSurface.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.isTimerRunning ? "\(Int(viewModel.timeRemaining)) seconds remaining" : "Timer paused")
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
                .foregroundColor(.secondary)

            Text("No Starters Available")
                .font(AppTheme.Typography.sectionHeader)

            Text("Try adjusting your filters or adding more categories")
                .font(AppTheme.Typography.secondary)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { dismiss() }) {
                Text("Back to Settings")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .background(GameTheme.conversationStarters.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
            }
        }
        .padding()
    }

    private var allDoneView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(AppTheme.success)

            Text("All Done!")
                .font(AppTheme.Typography.screenTitle)

            Text("You've seen all the conversation starters")
                .font(AppTheme.Typography.secondary)
                .foregroundColor(.secondary)

            Button(action: {
                viewModel.resetDeck()
            }) {
                Text("Start Over")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .background(GameTheme.conversationStarters.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
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
                        .font(AppTheme.Typography.caption)
                    Text(starter.category.rawValue)
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(categoryColor.opacity(0.2))
                .foregroundColor(categoryColor)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))

                Spacer()

                Button(action: onStar) {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .font(AppTheme.Typography.sectionHeader)
                        .foregroundColor(isStarred ? AppTheme.medalGold : AppTheme.mediumGray)

                }
                .accessibilityLabel(isStarred ? "Remove from saved" : "Save this starter")
            }
            .padding()

            Spacer()

            // Question text
            Text(starter.text)
                .font(AppTheme.Typography.sectionHeader)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal, AppTheme.Spacing.xl)

            Spacer()

            // Footer with vibe level and themes
            VStack(spacing: 10) {
                HStack(spacing: 5) {
                    ForEach(1...5, id: \.self) { level in
                        Circle()
                            .fill(level <= starter.vibeLevel ? vibeColor : AppTheme.mediumGray.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }

                if !starter.themes.filter({ $0 != .evergreen }).isEmpty {
                    HStack(spacing: 5) {
                        ForEach(starter.themes.filter { $0 != .evergreen }, id: \.self) { theme in
                            HStack(spacing: 3) {
                                Image(systemName: theme.icon)
                                    .font(AppTheme.Typography.tabLabel)
                                Text(theme.rawValue)
                                    .font(AppTheme.Typography.tabLabel)
                            }
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .background(GameTheme.conversationStarters.lightBackground)
                            .foregroundColor(GameTheme.conversationStarters.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 320, maxHeight: 500)
        .background(AppTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
        .shadow(radius: 10)
        .padding(.horizontal, AppTheme.Spacing.xl)
    }

    private var categoryColor: Color {
        switch starter.category {
        case .wouldYouRather: return GameTheme.conversationStarters.accentColor
        case .hotTakes: return AppTheme.error
        case .hypotheticals: return AppTheme.warning
        case .storyTime: return GameTheme.conversationStarters.accentColor
        case .thisOrThat: return AppTheme.success
        case .deepDive: return GameTheme.conversationStarters.accentColor
        }
    }

    private var vibeColor: Color {
        switch starter.vibeLevel {
        case 1: return GameTheme.conversationStarters.accentColor
        case 2: return AppTheme.success
        case 3: return AppTheme.medalGold
        case 4: return AppTheme.warning
        case 5: return AppTheme.error
        default: return GameTheme.conversationStarters.accentColor
        }
    }
}
