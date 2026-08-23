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
                GeometryReader { geo in
                    // Card + controls column stays motif-free (§7); the
                    // vibe-tinted gradient is retired (§2 rule 2) — vibe
                    // still reads from the card's dot meter.
                    MotifGroundView(seed: 0xC0FF_EE01,
                                    exclusions: [CGRect(x: 24, y: 100,
                                                        width: geo.size.width - 48,
                                                        height: geo.size.height - 180)])
                }
                .ignoresSafeArea()

                if viewModel.filteredStarters.isEmpty {
                    emptyStateView
                } else if let starter = viewModel.currentStarter {
                    VStack(spacing: 20) {
                        // Progress indicator
                        HStack {
                            Text("\(viewModel.currentIndex + 1) of \(viewModel.filteredStarters.count)")
                                .font(AppTheme.Retro.Typography.pillLabel)
                                .foregroundColor(AppTheme.Retro.panelText)
                                .retroLozenge()

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
                                Image(systemName: "chevron.left")
                                    .font(AppTheme.Typography.screenTitle.weight(.black))
                                    .foregroundColor(AppTheme.Retro.ink)
                                    .frame(width: 60, height: 60)
                                    .retroPanel(viewModel.hasPrevious ? ConversationStartersStyle.accent : AppTheme.Retro.panel,
                                                cornerRadius: 999)
                            }
                            .buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))
                            .disabled(!viewModel.hasPrevious)
                            .opacity(viewModel.hasPrevious ? 1 : 0.4)
                            .accessibilityLabel("Previous conversation starter")

                            if viewModel.settings.timerEnabled {
                                Button(action: {
                                    withNavAnimation {
                                        viewModel.nextStarter()
                                    }
                                }) {
                                    VStack(spacing: 2) {
                                        Image(systemName: "forward.fill")
                                            .font(AppTheme.Typography.cardTitle)
                                        Text("Pass")
                                            .font(AppTheme.Retro.Typography.pillLabel)
                                    }
                                    .foregroundColor(AppTheme.Retro.ink)
                                    .frame(width: 60, height: 60)
                                    .retroPanel(AppTheme.Retro.tangerine, cornerRadius: 999)
                                }
                                .buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))
                                .accessibilityLabel("Pass and skip to next")
                            }

                            // Stays enabled on the last card — advancing past it
                            // shows the "All Done" screen.
                            Button(action: {
                                withNavAnimation {
                                    viewModel.nextStarter()
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(AppTheme.Typography.screenTitle.weight(.black))
                                    .foregroundColor(AppTheme.Retro.ink)
                                    .frame(width: 60, height: 60)
                                    .retroPanel(ConversationStartersStyle.accent, cornerRadius: 999)
                            }
                            .buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))
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
            .tint(AppTheme.Retro.ink)
        }
    }

    private var timerView: some View {
        HStack(spacing: 5) {
            Image(systemName: viewModel.isTimerRunning ? "timer" : "pause.circle")
            Text(timeString(from: viewModel.timeRemaining))
                .font(AppTheme.Retro.Typography.pillLabel)
                .monospacedDigit()
        }
        .foregroundColor(viewModel.timeRemaining < 10 ? AppTheme.Retro.tomato : AppTheme.Retro.panelText)
        .retroLozenge()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.isTimerRunning ? "\(Int(viewModel.timeRemaining)) seconds remaining" : "Timer paused")
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // §9: no naked SF heroes — empty/celebration states get the game's spot
    // plate, a framed heading, and a retro primary button.
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle().fill(AppTheme.Retro.panel)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                RetroSpotIllustration(kind: .speechBubbles)
                    .frame(width: 60, height: 60)
                    .opacity(0.6)
            }
            .frame(width: 80, height: 80)

            Text("No Starters Available")
                .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title2))
                .foregroundColor(AppTheme.Retro.ink)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .retroPanel(ConversationStartersStyle.accent)
                .rotationEffect(.degrees(-1))

            Text("Try adjusting your filters or adding more categories")
                .font(AppTheme.Typography.secondary)
                .foregroundColor(AppTheme.Retro.panelText)
                .multilineTextAlignment(.center)
                .retroLozenge()

            RetroPrimaryButton(title: "Back to Settings",
                               accent: ConversationStartersStyle.accent) { dismiss() }
                .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .padding()
    }

    private var allDoneView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle().fill(AppTheme.Retro.panel)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                RetroSpotIllustration(kind: .speechBubbles)
                    .frame(width: 60, height: 60)
            }
            .frame(width: 80, height: 80)

            // Cream display text on grass — §8 display-only, 20pt Lilita.
            Text("All Done!")
                .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title2))
                .foregroundColor(AppTheme.Retro.cream)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .retroPanel(AppTheme.Retro.grass)
                .rotationEffect(.degrees(-1))

            Text("You've seen all the conversation starters")
                .font(AppTheme.Typography.secondary)
                .foregroundColor(AppTheme.Retro.panelText)
                .retroLozenge()

            RetroPrimaryButton(title: "Start Over", accent: AppTheme.Retro.grass) {
                viewModel.resetDeck()
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
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
                        .font(AppTheme.Retro.Typography.pillLabel)
                }
                .foregroundColor(ConversationStartersStyle.chipTextColor(on: categoryColor))
                .padding(.horizontal, AppTheme.Spacing.sm + 2)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(Capsule().fill(categoryColor))
                .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))

                Spacer()

                Button(action: onStar) {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .font(AppTheme.Typography.sectionHeader)
                        .foregroundColor(isStarred ? AppTheme.Retro.mustard : AppTheme.Retro.ink.opacity(0.35))

                }
                .accessibilityLabel(isStarred ? "Remove from saved" : "Save this starter")
            }
            .padding()

            Spacer()

            // Question text — the card's hero. Lilita One display (§4) so the
            // content pops as loud as the chrome around it.
            Text(starter.text)
                .font(AppTheme.Retro.Typography.heading(26, relativeTo: .title))
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.Retro.panelText)
                .lineSpacing(4)
                .padding(.horizontal, AppTheme.Spacing.lg)

            Spacer()

            // Footer with vibe level and themes
            VStack(spacing: 10) {
                HStack(spacing: 5) {
                    ForEach(1...5, id: \.self) { level in
                        Circle()
                            .fill(level <= starter.vibeLevel ? vibeColor : AppTheme.Retro.ink.opacity(0.15))
                            .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1))
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
                            .foregroundColor(AppTheme.Retro.ink)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .background(Capsule().fill(AppTheme.Retro.bubblegum))
                            .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 320, maxHeight: 500)
        .retroPanel(AppTheme.Retro.panel)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                .fill(AppTheme.Retro.ink)
                .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
        )
        .padding(.horizontal, AppTheme.Spacing.xl)
    }

    private var categoryColor: Color {
        ConversationStartersStyle.categoryColor(starter.category)
    }

    private var vibeColor: Color {
        ConversationStartersStyle.vibeColor(starter.vibeLevel)
    }
}
