import SwiftUI

/// Search/guess overlay — text field with debounced autocomplete for actors
struct GuessOverlayView: View {
    @ObservedObject var viewModel: CastingDirectorViewModel
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            // Dimmed background
            AppTheme.overlay
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.showingGuessOverlay = false
                }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: AppTheme.Spacing.md) {
                    // Header
                    HStack {
                        Text("Who is the actor?")
                            .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                            .foregroundColor(AppTheme.Retro.panelText)

                        Spacer()

                        Button {
                            viewModel.showingGuessOverlay = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(AppTheme.Typography.sectionHeader)
                                .foregroundStyle(AppTheme.Retro.panelText.opacity(0.6))
                        }
                    }

                    // Wrong guesses display
                    if !viewModel.roundState.wrongGuesses.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                ForEach(viewModel.roundState.wrongGuesses, id: \.self) { name in
                                    Text(name)
                                        .font(AppTheme.Typography.caption)
                                        .strikethrough()
                                        .foregroundStyle(AppTheme.Retro.ink)
                                        .padding(.horizontal, AppTheme.Spacing.sm)
                                        .padding(.vertical, AppTheme.Spacing.xs)
                                        .background(Capsule().fill(CastingDirectorStyle.errorColor.opacity(0.35)))
                                        .overlay(Capsule().stroke(CastingDirectorStyle.errorColor, lineWidth: 1.5))
                                }
                            }
                        }
                    }

                    // Search field — inset well on the cream card (§3 recipe).
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.Retro.panelText.opacity(0.6))

                        TextField("Search actors...", text: $viewModel.searchQuery)
                            .textFieldStyle(.plain)
                            .foregroundColor(AppTheme.Retro.panelText)
                            .autocorrectionDisabled()
                            .focused($isSearchFocused)

                        if !viewModel.searchQuery.isEmpty {
                            Button {
                                viewModel.searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppTheme.Retro.panelText.opacity(0.6))
                            }
                        }

                        if viewModel.isSearching {
                            GameSpinner(color: CastingDirectorStyle.accent)
                                .scaleEffect(0.6)
                        }
                    }
                    .padding(AppTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                            .fill(AppTheme.Retro.ground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                            .stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth)
                    )

                    // Results list
                    if !viewModel.searchResults.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: AppTheme.Spacing.xs) {
                                ForEach(viewModel.searchResults) { actor in
                                    Button {
                                        viewModel.submitGuess(actor)
                                    } label: {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle().fill(CastingDirectorStyle.accent)
                                                Circle().stroke(AppTheme.Retro.ink, lineWidth: 1.5)
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(AppTheme.Retro.ink)
                                            }
                                            .frame(width: 30, height: 30)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(actor.name)
                                                    .font(AppTheme.Retro.Typography.cardTitle)
                                                    .foregroundStyle(AppTheme.Retro.panelText)

                                                if let knownFor = actor.knownFor {
                                                    Text(knownFor)
                                                        .font(AppTheme.Typography.caption)
                                                        .foregroundStyle(AppTheme.Retro.panelText.opacity(0.7))
                                                        .lineLimit(1)
                                                }
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(AppTheme.Typography.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(AppTheme.Retro.panelText.opacity(0.6))
                                        }
                                        .padding(.horizontal, AppTheme.Spacing.sm)
                                        .padding(.vertical, AppTheme.Spacing.sm)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                                                .fill(AppTheme.Retro.ground.opacity(0.6))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                                                .stroke(AppTheme.Retro.ink.opacity(0.4), lineWidth: 1.5)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                    } else if !viewModel.searchQuery.isEmpty && !viewModel.isSearching {
                        Text("No actors found")
                            .font(AppTheme.Typography.secondary)
                            .foregroundStyle(AppTheme.Retro.panelText.opacity(0.7))
                            .padding()
                    }

                    // Penalty warning
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(AppTheme.Typography.tabLabel)
                            .foregroundStyle(CastingDirectorStyle.warningColor)
                        Text("Wrong guess: -\(viewModel.difficulty.wrongGuessPenalty) points")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Retro.panelText.opacity(0.7))
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .retroPanel(AppTheme.Retro.panel)
                .padding(.horizontal)
                .padding(.bottom, AppTheme.Spacing.lg)
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }
}
