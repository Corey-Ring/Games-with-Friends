import SwiftUI

/// Main gameplay view for Movie Chain
struct MovieChainGameView: View {
    @ObservedObject var viewModel: MovieChainViewModel
    @FocusState private var isSearchFocused: Bool
    @State private var showingDatabaseInfo = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.red.opacity(0.2), Color.orange.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with player info and timer
                topBar

                // Chain display
                chainDisplay

                // Prompt and search area
                searchArea
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.returnToSetup()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Exit game")
            }

            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.isInitialPick {
                    Button("Give Up") {
                        viewModel.giveUp()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: 12) {
            // Current player indicator
            HStack {
                Circle()
                    .fill(viewModel.currentPlayer.color)
                    .frame(width: 16, height: 16)

                Text(viewModel.currentPlayer.name)
                    .font(.headline)

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
                    HStack(spacing: 12) {
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
        .padding()
        .background(.ultraThinMaterial)
    }

    private var timerDisplay: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
            Text("\(viewModel.timeRemaining)")
                .font(.title2.monospacedDigit())
                .fontWeight(.bold)
        }
        .foregroundStyle(timerColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
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
        HStack(spacing: 4) {
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

                        if index < viewModel.chain.count - 1 {
                            ChainConnector()
                        }
                    }

                    // Show what's needed next (only show after the chain items)
                    // Use chain count in ID to force view refresh
                    if viewModel.chain.isEmpty {
                        InitialPickView()
                            .id("pending-initial")
                    } else {
                        ChainConnector()

                        PendingLinkView(turnType: viewModel.turnType)
                            .id("pending-\(viewModel.chain.count)")
                    }
                }
                .padding()
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
        VStack(spacing: 12) {
            // Prompt
            Text(viewModel.currentPrompt)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

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
                            .foregroundStyle(.secondary)
                    }
                }

                if viewModel.isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                    Text("Not finding an actor?")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(.bottom)
        .background(.ultraThinMaterial)
        .alert("Database Limitation", isPresented: $showingDatabaseInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Our database includes the top 10 billed cast members for each movie, sourced from IMDb. Some actors with smaller roles may not appear in search results.\n\nWe're working to expand our database in future updates. Thanks for your patience!")
        }
    }

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.searchResults) { result in
                    SearchResultRow(result: result) {
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
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundStyle(.secondary)

            Text("No results found")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Try a different spelling")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

// MARK: - Chain Link View

struct ChainLinkView: View {
    let link: ChainLink
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(link.isMovie ? Color.red : Color.blue)
                    .frame(width: 44, height: 44)

                Image(systemName: link.isMovie ? "film" : "person.fill")
                    .foregroundStyle(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(link.isMovie ? "MOVIE" : "ACTOR")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(link.displayName)
                    .font(.headline)

                if case .movie(let movie) = link, let year = movie.year {
                    Text("\(year)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Chain Connector

struct ChainConnector: View {
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<3) { _ in
                Circle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 24)
    }
}

// MARK: - Initial Pick View

struct InitialPickView: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Movie icon
                ZStack {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.red)
                        .frame(width: 44, height: 44)

                    Image(systemName: "film")
                        .foregroundStyle(.red)
                }

                Text("or")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                // Actor icon
                ZStack {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.blue)
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.fill")
                        .foregroundStyle(.blue)
                }
            }

            Text("Pick an Actor or Movie to begin!")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundStyle(.secondary.opacity(0.5))
        )
    }
}

// MARK: - Pending Link View

struct PendingLinkView: View {
    let turnType: TurnType

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)

                Image(systemName: "questionmark")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(turnType == .movie ? "MOVIE" : "ACTOR")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text("Your turn...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundStyle(.secondary.opacity(0.5))
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
                .font(.caption)
                .lineLimit(1)

            if gameMode.hasLives {
                Text("\(player.lives)")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if gameMode.hasScoring {
                Text("\(player.score)")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isCurrentPlayer ? player.color.opacity(0.3) : Color.clear)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isCurrentPlayer ? player.color : Color.clear, lineWidth: 2)
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
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isMovie ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: isMovie ? "film" : "person.fill")
                        .foregroundStyle(isMovie ? .red : .blue)
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let subtitle = result.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
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
