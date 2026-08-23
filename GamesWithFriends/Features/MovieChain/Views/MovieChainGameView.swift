import SwiftUI

/// Main gameplay view for Movie Chain
struct MovieChainGameView: View {
    @ObservedObject var viewModel: MovieChainViewModel
    @FocusState private var isSearchFocused: Bool
    @State private var showingDatabaseInfo = false

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with player info and timer
            topBar

            // Chain display
            chainDisplay

            // Prompt and search area
            searchArea
        }
        .onAppear {
            if viewModel.isInitialPick {
                isSearchFocused = true
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Current player indicator + exit/give up controls
            HStack {
                Button {
                    viewModel.returnToSetup()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.Retro.panelText.opacity(0.6))
                }
                .accessibilityLabel("Exit game")

                Circle()
                    .fill(viewModel.currentPlayer.color)
                    .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                    .frame(width: 16, height: 16)

                Text(viewModel.currentPlayer.name)
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .lineLimit(1)

                Spacer()

                if !viewModel.isInitialPick {
                    Button("Give Up") {
                        viewModel.giveUp()
                    }
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .foregroundStyle(MovieChainStyle.accent)
                }

                // Timer or lives display
                if viewModel.gameMode.hasTimer {
                    timerDisplay
                } else if viewModel.gameMode.hasLives {
                    livesDisplay
                }
            }

            // All players status (for multiplayer)
            if viewModel.players.count > 2 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.md) {
                        ForEach(viewModel.players) { player in
                            PlayerStatusBadge(
                                player: player,
                                isCurrentPlayer: player.id == viewModel.currentPlayer.id,
                                gameMode: viewModel.gameMode
                            )
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        // Cream strip with a hard ink rule under it (§2 rule 2 — no soft
        // shadows), separating the chrome from the chain scroll.
        .background(AppTheme.Retro.panel)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.Retro.ink)
                .frame(height: AppTheme.Retro.strokeWidth)
        }
    }

    private var timerDisplay: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "timer")
            Text("\(viewModel.timeRemaining)")
                .font(AppTheme.Typography.sectionHeader).monospacedDigit()
                .fontWeight(.bold)
        }
        .foregroundStyle(timerColor)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(Capsule().fill(AppTheme.Retro.panel))
        .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.timeRemaining) seconds remaining")
    }

    private var timerColor: Color {
        if viewModel.timeRemaining <= 5 {
            return MovieChainStyle.timerUrgent
        } else if viewModel.timeRemaining <= 10 {
            return MovieChainStyle.timerWarning
        }
        return MovieChainStyle.timerCalm
    }

    private var livesDisplay: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(0..<viewModel.gameMode.defaultLives, id: \.self) { index in
                Image(systemName: index < viewModel.currentPlayer.lives ? "heart.fill" : "heart")
                    .foregroundStyle(MovieChainStyle.lives)
            }
        }
    }

    // MARK: - Chain Display

    private var chainDisplay: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.chain.enumerated()), id: \.element.id) { index, link in
                            ChainLinkView(link: link, index: index)
                                .id(link.id)
                                .staggeredAppear(index: index)

                            if index < viewModel.chain.count - 1 {
                                ChainConnector()
                            }
                        }

                        // Show what's needed next
                        if viewModel.chain.isEmpty {
                            VStack {
                                Spacer()
                                InitialPickView()
                                    .id("pending-initial")
                                Spacer()
                            }
                            .frame(minHeight: geometry.size.height * 0.45)
                        } else {
                            ChainConnector()

                            PendingLinkView(turnType: viewModel.turnType)
                                .id("pending-\(viewModel.chain.count)")
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                }
                .onChange(of: viewModel.chain.count) { _, newCount in
                    withAnimation {
                        if newCount == 0 {
                            proxy.scrollTo("pending-initial", anchor: .bottom)
                        } else {
                            proxy.scrollTo("pending-\(newCount)", anchor: .bottom)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Search Area

    private var searchArea: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Prompt (hidden during initial pick — InitialPickView already shows it)
            if !viewModel.isInitialPick {
                Text(viewModel.currentPrompt)
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Retro.panelText.opacity(0.6))

                TextField(
                    viewModel.isInitialPick ? "Search for an actor or movie..." : viewModel.turnType.searchPlaceholder,
                    text: $viewModel.searchQuery
                )
                    .textFieldStyle(.plain)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .focused($isSearchFocused)
                    .autocorrectionDisabled()

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.Retro.panelText.opacity(0.6))
                    }
                }

                if viewModel.isSearching {
                    GameSpinner(color: MovieChainStyle.accent)
                        .scaleEffect(0.6)
                }
            }
            .padding(AppTheme.Spacing.md)
            .retroPanel(AppTheme.Retro.panel, cornerRadius: AppTheme.Retro.Radius.inner)
            .padding(.horizontal)

            // Search results
            if !viewModel.searchResults.isEmpty {
                searchResultsList
            } else if !viewModel.searchQuery.isEmpty && !viewModel.isSearching {
                noResultsView
            }

            // Database limitation info button
            Button {
                showingDatabaseInfo = true
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "info.circle")
                    Text(viewModel.isInitialPick
                        ? "Not finding what you're looking for?"
                        : viewModel.turnType == .actor
                            ? "Not finding an actor?"
                            : "Not finding a movie?")
                }
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Retro.panelText.opacity(0.7))
            }
            .padding(.top, AppTheme.Spacing.xs)
        }
        .padding(.top, AppTheme.Spacing.md)
        .padding(.bottom, AppTheme.Spacing.md)
        // Mustard tray behind the input — an ink rule on its top edge in
        // place of the retired soft top shadow (§2 rule 2).
        .background(AppTheme.Retro.ground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.Retro.ink)
                .frame(height: AppTheme.Retro.strokeWidth)
        }
        .alert("Database Limitation", isPresented: $showingDatabaseInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Our database includes the top 10 billed cast members for each movie, sourced from IMDb. Some actors with smaller roles may not appear in search results.\n\nWe're working to expand our database in future updates. Thanks for your patience!")
        }
    }

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.sm) {
                ForEach(viewModel.searchResults) { result in
                    SearchResultRow(result: result) {
                        HapticManager.selection()
                        viewModel.submitAnswer(result)
                        isSearchFocused = false
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, AppTheme.Retro.shadowOffset)
        }
        .frame(maxHeight: isSearchFocused ? 250 : 200)
    }

    private var noResultsView: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ChainNodeDisc(systemImage: "magnifyingglass",
                          color: AppTheme.Retro.panel,
                          diameter: 44)

            Text("No results found")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Retro.panelText)

            Text("Try a different spelling")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
        }
        .padding(AppTheme.Spacing.md)
    }
}

// MARK: - Chain Link View

struct ChainLinkView: View {
    let link: ChainLink
    let index: Int

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ChainNodeDisc(
                systemImage: link.isMovie ? "film" : "person.fill",
                color: link.isMovie ? MovieChainStyle.movieNode : MovieChainStyle.actorNode
            )

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(link.isMovie ? "MOVIE" : "ACTOR")
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .foregroundColor(AppTheme.Retro.panelText.opacity(0.6))

                Text(link.displayName)
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText)

                if case .movie(let movie) = link, let year = movie.year {
                    Text(verbatim: "\(year)")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                }
            }

            Spacer()
        }
        .retroCard()
    }
}

// MARK: - Chain Connector

struct ChainConnector: View {
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<3) { _ in
                Circle()
                    .fill(AppTheme.Retro.ink)
                    .frame(width: 5, height: 5)
            }
        }
        .frame(height: 24)
    }
}

// MARK: - Initial Pick View

struct InitialPickView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                ChainNodeDisc(systemImage: "film",
                              color: MovieChainStyle.movieNode,
                              dashed: true)

                Text("or")
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))

                ChainNodeDisc(systemImage: "person.fill",
                              color: MovieChainStyle.actorNode,
                              dashed: true)
            }

            Text("Pick an Actor or Movie to begin!")
                .font(AppTheme.Retro.Typography.cardTitle)
                .foregroundColor(AppTheme.Retro.panelText)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                .fill(AppTheme.Retro.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                .strokeBorder(AppTheme.Retro.ink,
                              style: StrokeStyle(lineWidth: AppTheme.Retro.strokeWidth, dash: [8]))
        )
    }
}

// MARK: - Pending Link View

struct PendingLinkView: View {
    let turnType: TurnType

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ChainNodeDisc(systemImage: "questionmark",
                          color: AppTheme.Retro.panel,
                          dashed: true)

            VStack(alignment: .leading, spacing: 2) {
                Text(turnType == .movie ? "MOVIE" : "ACTOR")
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .foregroundColor(AppTheme.Retro.panelText.opacity(0.6))

                Text("Your turn...")
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                .fill(AppTheme.Retro.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                .strokeBorder(AppTheme.Retro.ink,
                              style: StrokeStyle(lineWidth: AppTheme.Retro.strokeWidth, dash: [8]))
        )
    }
}

// MARK: - Player Status Badge

struct PlayerStatusBadge: View {
    let player: MovieChainPlayer
    let isCurrentPlayer: Bool
    let gameMode: MovieChainGameMode

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Circle()
                .fill(player.color)
                .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1))
                .frame(width: 12, height: 12)

            Text(player.name)
                .font(AppTheme.Retro.Typography.pillLabel)
                .foregroundColor(AppTheme.Retro.panelText)
                .lineLimit(1)

            if gameMode.hasLives {
                Text("\(player.lives)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(MovieChainStyle.lives)
            } else if gameMode.hasScoring {
                Text("\(player.score)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Retro.panelText)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(Capsule().fill(isCurrentPlayer ? player.color.opacity(0.35) : AppTheme.Retro.panel))
        .overlay(
            Capsule()
                .stroke(AppTheme.Retro.ink,
                        lineWidth: isCurrentPlayer ? AppTheme.Retro.strokeWidth : 1)
        )
        .opacity(player.isEliminated ? 0.5 : 1.0)
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let result: SearchResult
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                ChainNodeDisc(
                    systemImage: isMovie ? "film" : "person.fill",
                    color: isMovie ? MovieChainStyle.movieNode : MovieChainStyle.actorNode,
                    diameter: 40
                )

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.displayName)
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .foregroundColor(AppTheme.Retro.panelText)

                    if let subtitle = result.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Retro.panelText.opacity(0.6))
            }
            .padding(.vertical, AppTheme.Spacing.sm)
            .padding(.horizontal, AppTheme.Spacing.md)
            .retroPanel(AppTheme.Retro.panel, cornerRadius: AppTheme.Retro.Radius.inner)
        }
        .buttonStyle(RetroRaisedButtonStyle(cornerRadius: AppTheme.Retro.Radius.inner))
    }

    private var isMovie: Bool {
        if case .movie = result { return true }
        return false
    }
}

#Preview {
    NavigationStack {
        MovieChainGameView(viewModel: {
            let vm = MovieChainViewModel()
            vm.gamePhase = .playing
            return vm
        }())
    }
}
