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
                            .font(AppTheme.Typography.subsectionHeader)
                            .fontWeight(.semibold)

                        Spacer()

                        Button {
                            viewModel.showingGuessOverlay = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(AppTheme.Typography.sectionHeader)
                                .foregroundStyle(.secondary)
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
                                        .foregroundStyle(AppTheme.error)
                                        .padding(.horizontal, AppTheme.Spacing.sm)
                                        .padding(.vertical, AppTheme.Spacing.xs)
                                        .background(AppTheme.error.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField("Search actors...", text: $viewModel.searchQuery)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                            .focused($isSearchFocused)

                        if !viewModel.searchQuery.isEmpty {
                            Button {
                                viewModel.searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if viewModel.isSearching {
                            GameSpinner(color: GameTheme.castingDirector.accentColor)
                                .scaleEffect(0.6)
                        }
                    }
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.warmLinen)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))

                    // Results list
                    if !viewModel.searchResults.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: AppTheme.Spacing.xs) {
                                ForEach(viewModel.searchResults) { actor in
                                    Button {
                                        viewModel.submitGuess(actor)
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: "person.fill")
                                                .font(AppTheme.Typography.secondary)
                                                .foregroundStyle(GameTheme.castingDirector.accentColor)
                                                .frame(width: 30)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(actor.name)
                                                    .font(AppTheme.Typography.body)
                                                    .foregroundStyle(.primary)

                                                if let knownFor = actor.knownFor {
                                                    Text(knownFor)
                                                        .font(AppTheme.Typography.caption)
                                                        .foregroundStyle(.secondary)
                                                        .lineLimit(1)
                                                }
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(AppTheme.Typography.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.horizontal, AppTheme.Spacing.sm)
                                        .padding(.vertical, AppTheme.Spacing.sm)
                                        .background(AppTheme.warmLinen.opacity(0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                    } else if !viewModel.searchQuery.isEmpty && !viewModel.isSearching {
                        Text("No actors found")
                            .font(AppTheme.Typography.secondary)
                            .foregroundStyle(.secondary)
                            .padding()
                    }

                    // Penalty warning
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(AppTheme.Typography.tabLabel)
                            .foregroundStyle(.orange)
                        Text("Wrong guess: -\(viewModel.difficulty.wrongGuessPenalty) points")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
                .padding(.bottom, AppTheme.Spacing.lg)
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }
}
