import Foundation

/// Tunable thresholds controlling which clues are distinctive enough to show.
/// Adjust during playtesting; see the design spec for rationale.
struct ClueTuning {
    /// Minimum share of an actor's credits a genre must cover to be their "identity".
    var genreIdentityShare: Double = 0.30
    /// Career span (years) to count as long-running.
    var longevitySpanYears: Int = 30
    /// Credit count to be called "prolific".
    var prolificThreshold: Int = 50
    /// Max credits to be called "selective" (requires >= 3 acclaimed films too).
    var selectiveMaxCredits: Int = 15
    /// Vote count for a film to count as a "blockbuster".
    var blockbusterVotes: Int = 500_000
    /// Blockbusters required for the blockbuster clue.
    var blockbusterCount: Int = 2
    /// Rating threshold for a film to be "acclaimed".
    var acclaimRating: Double = 8.0
    /// Acclaimed films required for the acclaim clue.
    var acclaimCount: Int = 3
    /// Vote count for a film to be "recognizable" (anchored / signature films).
    var anchoredFilmMinVotes: Int = 50_000
    /// Films sharing a title stem required to count as a franchise.
    var franchiseMinFilms: Int = 2
    /// Combined votes a franchise's films must clear to be "major".
    var franchiseMinCombinedVotes: Int = 200_000
    /// Collaborations with one director required for the "frequent director" clue.
    var frequentDirectorCount: Int = 3
    /// Minimum movie votes for a co-star to be gathered.
    var coStarMinMovieVotes: Int = 20_000

    static let `default` = ClueTuning()
}
