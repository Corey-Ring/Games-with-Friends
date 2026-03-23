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
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.returnToSetup()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.mediumGray)
                }
                .accessibilityLabel("Exit game")
            }

            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.isInitialPick {
                    Button("Give Up") {
                        viewModel.giveUp()
                    }
                    .foregroundStyle(GameTheme.movieChain.accentColor)
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Current player indicator
            HStack {
                Circle()
                    .fill(viewModel.currentPlayer.color)
                    .frame(width: 16, height: 16)

                Text(viewModel.currentPlayer.name)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(AppTheme.deepCharcoal)

                Spacer()

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
        .background(AppTheme.pureWhite)
        .shadow(color: AppTheme.Shadow.cardColor, radius: AppTheme.Shadow.cardRadius, x: AppTheme.Shadow.cardX, y: AppTheme.Shadow.cardY)
    }

    private var timerDisplay: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
            Text("\(viewModel.timeRemaining)")
                .font(AppTheme.Typography.sectionHeader).monospacedDigit()
                .fontWeight(.bold)
        }
        .foregroundStyle(timerColor)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(timerColor.opacity(0.2))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.timeRemaining) seconds remaining")
    }

    private var timerColor: Color {
        if viewModel.timeRemaining <= 5 {
            return .red
        } else if viewModel.timeRemaining <= 10 {
            return .orange
        }
        return .green
    }

    private var livesDisplay: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(0..<viewModel.gameMode.defaultLives, id: \.self) { index in
                Image(systemName: index < viewModel.currentPlayer.lives ? "heart.fill" : "heart")
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Chain Display

    private var chainDisplay: some View {
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
                        InitialPickView()
                            .id("pending-initial")
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

    // MARK: - Search Area

    private var searchArea: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Prompt
            Text(viewModel.currentPrompt)
                .font(AppTheme.Typography.cardTitle)
                .foregroundColor(AppTheme.deepCharcoal)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.mediumGray)

                TextField(
                    viewModel.isInitialPick ? "Search for an actor or movie..." : viewModel.turnType.searchPlaceholder,
                    text: $viewModel.searchQuery
                )
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .autocorrectionDisabled()

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.mediumGray)
                    }
                }

                if viewModel.isSearching {
                    GameSpinner(color: GameTheme.movieChain.accentColor)
                        .scaleEffect(0.6)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.pureWhite)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            .shadow(color: AppTheme.Shadow.cardColor, radius: AppTheme.Shadow.cardRadius, x: AppTheme.Shadow.cardX, y: AppTheme.Shadow.cardY)
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
                    Text("Not finding an actor?")
                }
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.mediumGray)
            }
            .padding(.top, AppTheme.Spacing.xs)
        }
        .padding(.bottom, AppTheme.Spacing.md)
        .background(AppTheme.pureWhite)
        .shadow(color: AppTheme.Shadow.cardColor, radius: 4, x: 0, y: -2)
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
        }
        .frame(maxHeight: 200)
    }

    private var noResultsView: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(AppTheme.Typography.screenTitle)
                .foregroundStyle(AppTheme.mediumGray)

            Text("No results found")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.mediumGray)

            Text("Try a different spelling")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.mediumGray.opacity(0.7))
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
            // Icon
            ZStack {
                Circle()
                    .fill(link.isMovie ? GameTheme.movieChain.accentColor : AppTheme.deepCharcoal)
                    .frame(width: 44, height: 44)

                Image(systemName: link.isMovie ? "film" : "person.fill")
                    .foregroundStyle(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(link.isMovie ? "MOVIE" : "ACTOR")
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.mediumGray)

                Text(link.displayName)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(AppTheme.deepCharcoal)

                if case .movie(let movie) = link, let year = movie.year {
                    Text("\(year)")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.mediumGray)
                }
            }

            Spacer()
        }
        .gameCard()
    }
}

// MARK: - Chain Connector

struct ChainConnector: View {
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<3) { _ in
                Circle()
                    .fill(AppTheme.mediumGray.opacity(0.5))
                    .frame(width: 4, height: 4)
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
                // Movie icon
                ZStack {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(GameTheme.movieChain.accentColor)
                        .frame(width: 44, height: 44)

                    Image(systemName: "film")
                        .foregroundStyle(GameTheme.movieChain.accentColor)
                }

                Text("or")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(AppTheme.mediumGray)

                // Actor icon
                ZStack {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(AppTheme.deepCharcoal)
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.fill")
                        .foregroundStyle(AppTheme.deepCharcoal)
                }
            }

            Text("Pick an Actor or Movie to begin!")
                .font(AppTheme.Typography.cardTitle)
                .foregroundColor(AppTheme.mediumGray)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .shadow(color: AppTheme.Shadow.cardColor, radius: AppTheme.Shadow.cardRadius, x: AppTheme.Shadow.cardX, y: AppTheme.Shadow.cardY)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundStyle(AppTheme.mediumGray.opacity(0.5))
        )
    }
}

// MARK: - Pending Link View

struct PendingLinkView: View {
    let turnType: TurnType

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(AppTheme.mediumGray)
                    .frame(width: 44, height: 44)

                Image(systemName: "questionmark")
                    .foregroundStyle(AppTheme.mediumGray)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(turnType == .movie ? "MOVIE" : "ACTOR")
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.mediumGray)

                Text("Your turn...")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(AppTheme.mediumGray)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .shadow(color: AppTheme.Shadow.cardColor, radius: AppTheme.Shadow.cardRadius, x: AppTheme.Shadow.cardX, y: AppTheme.Shadow.cardY)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundStyle(AppTheme.mediumGray.opacity(0.5))
        )
    }
}

// MARK: - Player Status Badge

struct PlayerStatusBadge: View {
    let player: MovieChainPlayer
    let isCurrentPlayer: Bool
    let gameMode: MovieChainGameMode

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(player.color)
                .frame(width: 12, height: 12)

            Text(player.name)
                .font(AppTheme.Typography.caption)
                .lineLimit(1)

            if gameMode.hasLives {
                Text("\(player.lives)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.red)
            } else if gameMode.hasScoring {
                Text("\(player.score)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(GameTheme.movieChain.accentColor)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(isCurrentPlayer ? player.color.opacity(0.3) : AppTheme.pureWhite.opacity(0.8))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isCurrentPlayer ? player.color : Color.clear, lineWidth: 2)
        )
        .shadow(color: AppTheme.Shadow.cardColor, radius: 2, x: 0, y: 1)
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
                // Icon
                ZStack {
                    Circle()
                        .fill(isMovie ? GameTheme.movieChain.accentColor.opacity(0.2) : AppTheme.deepCharcoal.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: isMovie ? "film" : "person.fill")
                        .foregroundStyle(isMovie ? GameTheme.movieChain.accentColor : AppTheme.deepCharcoal)
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.displayName)
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(AppTheme.deepCharcoal)

                    if let subtitle = result.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.mediumGray)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.mediumGray)
            }
            .padding(.vertical, AppTheme.Spacing.sm)
            .padding(.horizontal, AppTheme.Spacing.md)
            .background(AppTheme.pureWhite)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
            .shadow(color: AppTheme.Shadow.cardColor, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .pressable()
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
