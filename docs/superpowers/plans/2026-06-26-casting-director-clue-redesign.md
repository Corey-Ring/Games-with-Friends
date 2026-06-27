# Casting Director Clue Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Casting Director game's generic, low-signal clues with distinctiveness-gated clues that each narrow the candidate pool and read like real casting hints.

**Architecture:** Refactor `ClueGenerator` into a three-stage pipeline — (1) gather a pure `ActorFacts` value from the database, (2) run isolated pure *builder* functions that each emit a clue only when its distinctiveness gate passes, (3) assemble the surviving clues into a tiered ladder that reserves slots for the giveaway titles. All derivation and assembly logic is pure and unit-tested; only the thin fact-gathering glue touches SQLite.

**Tech Stack:** Swift 5.0, SwiftUI, iOS 17.0, XCTest (new target), Xcode 26.3, system SQLite via `MovieChainDatabase`.

**Spec:** [docs/superpowers/specs/2026-06-26-casting-director-clue-redesign-design.md](../specs/2026-06-26-casting-director-clue-redesign-design.md)

---

## File Structure

All new implementation files live under a new folder
`GamesWithFriends/Features/CastingDirector/Services/ClueGeneration/`:

- `ClueTuning.swift` — all tunable threshold constants (one struct).
- `ActorFacts.swift` — pure value type + pure initializer computing every aggregate a builder needs from raw `[Movie]` / director / co-star inputs.
- `FranchiseDetector.swift` — pure franchise (title-stem) detection.
- `ClueBuilders.swift` — pure builder functions, one per clue type, grouped by tier.
- `ClueLadderAssembler.swift` — orders builders' output into the final ladder, dedupes, reserves giveaway slots, applies difficulty budget, renumbers.

Modified:

- `GamesWithFriends/Features/CastingDirector/Models/CastingDirectorModels.swift` — add new `ClueType` cases + icons.
- `GamesWithFriends/Features/CastingDirector/Services/ClueGenerator.swift` — `generateClues` becomes thin glue: gather raw DB data → build `ActorFacts` → `ClueLadderAssembler.assemble`.

Tests (new target `GamesWithFriendsTests`):

- `GamesWithFriendsTests/FranchiseDetectorTests.swift`
- `GamesWithFriendsTests/ActorFactsTests.swift`
- `GamesWithFriendsTests/ClueBuildersTests.swift`
- `GamesWithFriendsTests/ClueLadderAssemblerTests.swift`

Helper scripts:

- `Scripts/setup_test_target.rb` — idempotent script that creates the test target (if missing), syncs all `*.swift` under `GamesWithFriendsTests/` into it, and wires the shared scheme's test action.

---

## Conventions used in every test task

All commands run from `GamesWithFriends/` (the directory containing `GamesWithFriends.xcodeproj`):

```bash
cd GamesWithFriends
```

The test destination is the booted simulator:

```
-destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

If `iPhone 17 Pro` is unavailable, list options with
`xcrun simctl list devices available | grep iPhone` and substitute a booted device name.

After creating or renaming any file under `GamesWithFriendsTests/`, re-run the sync script so the new file is compiled into the test target:

```bash
ruby Scripts/setup_test_target.rb
```

---

## Task 1: Create and verify the XCTest target

**Files:**
- Create: `Scripts/setup_test_target.rb`
- Create: `GamesWithFriendsTests/SmokeTests.swift`
- Modify: `GamesWithFriends.xcodeproj/project.pbxproj` (via script)
- Modify: `GamesWithFriends.xcodeproj/xcshareddata/xcschemes/GamesWithFriends.xcscheme` (via script)

- [ ] **Step 1: Install the xcodeproj gem**

Run (from repo root or anywhere):

```bash
gem install xcodeproj || sudo gem install xcodeproj || gem install --user-install xcodeproj
```

Expected: `Successfully installed xcodeproj-…`. Verify:

```bash
ruby -e "require 'xcodeproj'; puts 'ok'"
```

Expected output: `ok`. If `require` fails with a user-install, prefix later ruby calls with the gem path printed by `gem environment` (or just use `sudo gem install`).

- [ ] **Step 2: Write the idempotent setup script**

Create `Scripts/setup_test_target.rb`:

```ruby
#!/usr/bin/env ruby
require 'xcodeproj'

PROJECT = 'GamesWithFriends/GamesWithFriends.xcodeproj'
APP_TARGET = 'GamesWithFriends'
TEST_TARGET = 'GamesWithFriendsTests'
TESTS_DIR = 'GamesWithFriends/GamesWithFriendsTests'

project = Xcodeproj::Project.open(PROJECT)
app = project.targets.find { |t| t.name == APP_TARGET }
raise "App target #{APP_TARGET} not found" unless app

test_target = project.targets.find { |t| t.name == TEST_TARGET }
if test_target.nil?
  test_target = project.new_target(:unit_test_bundle, TEST_TARGET, :ios, '17.0', project.products_group, :swift)
  test_target.add_dependency(app)
  test_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.coreyring.GamesWithFriendsTests'
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/GamesWithFriends.app/GamesWithFriends'
    config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
  end
  puts "Created target #{TEST_TARGET}"
else
  puts "Target #{TEST_TARGET} already exists"
end

# Sync all *.swift under the tests dir into the target's compile phase.
group = project.main_group[TEST_TARGET] || project.main_group.new_group(TEST_TARGET, TESTS_DIR)
existing_paths = test_target.source_build_phase.files_references.compact.map(&:real_path).map(&:to_s)
Dir.glob("#{TESTS_DIR}/**/*.swift").sort.each do |path|
  abs = File.expand_path(path)
  next if existing_paths.include?(abs)
  ref = group.find_file_by_path(File.basename(path)) || group.new_file(File.expand_path(path))
  test_target.add_file_references([ref])
  puts "Added #{path}"
end

# Wire the shared scheme's test action to include the test target.
scheme_path = File.join(Xcodeproj::XCScheme.shared_data_dir(PROJECT).to_s, "#{APP_TARGET}.xcscheme")
if File.exist?(scheme_path)
  scheme = Xcodeproj::XCScheme.new(scheme_path)
  already = scheme.test_action.testables.any? do |t|
    t.buildable_references.any? { |b| b.target_name == TEST_TARGET }
  end
  unless already
    scheme.test_action.add_testable(Xcodeproj::XCScheme::TestAction::TestableReference.new(test_target))
    scheme.save_as(PROJECT, APP_TARGET, true)
    puts "Wired #{TEST_TARGET} into scheme #{APP_TARGET}"
  end
end

project.save
puts 'Done'
```

> **GUI fallback** if the gem cannot be installed: in Xcode, File ▸ New ▸ Target ▸ Unit Testing Bundle, name it `GamesWithFriendsTests`, host application `GamesWithFriends`. Then add each test file to the target's "Target Membership" as you create it, and skip every `ruby Scripts/setup_test_target.rb` step below.

- [ ] **Step 3: Write the smoke test**

Create `GamesWithFriends/GamesWithFriendsTests/SmokeTests.swift`:

```swift
import XCTest
@testable import GamesWithFriends

final class SmokeTests: XCTestCase {
    func testHarnessRuns() {
        XCTAssertEqual(2 + 2, 4)
    }
}
```

- [ ] **Step 4: Create the target and sync files**

Run (from repo root):

```bash
ruby Scripts/setup_test_target.rb
```

Expected: prints `Created target GamesWithFriendsTests`, `Added GamesWithFriends/GamesWithFriendsTests/SmokeTests.swift`, `Wired …`, `Done`.

- [ ] **Step 5: Run the smoke test**

```bash
cd GamesWithFriends
xcodebuild test -project GamesWithFriends.xcodeproj -scheme GamesWithFriends \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GamesWithFriendsTests/SmokeTests 2>&1 | tail -20
```

Expected: `** TEST SUCCEEDED **`. If the build fails because `@testable import` cannot find the module, confirm the app target's `ENABLE_TESTABILITY = YES` (it already is) and that `TEST_HOST`/`BUNDLE_LOADER` were set by the script.

- [ ] **Step 6: Commit**

```bash
cd ..
git add Scripts/setup_test_target.rb GamesWithFriends/GamesWithFriendsTests/SmokeTests.swift \
  GamesWithFriends/GamesWithFriends.xcodeproj
git commit -m "test: add XCTest unit-test target with smoke test"
```

---

## Task 2: Add new ClueType cases and icons

**Files:**
- Modify: `GamesWithFriends/Features/CastingDirector/Models/CastingDirectorModels.swift:6-35`
- Test: `GamesWithFriendsTests/ClueBuildersTests.swift` (created here, reused later)

The redesign needs four new clue types: `genreIdentity`, `longevity`, `blockbuster`, `franchise`. Existing types are reused for the rest (`.movieCount` for prolific/selective, `.decade` for breakout, `.movieYearGenre` for anchored film, `.rating` for acclaim, `.director`/`.coStar`/`.movieTitle` unchanged).

- [ ] **Step 1: Write the failing test**

Create `GamesWithFriends/GamesWithFriendsTests/ClueBuildersTests.swift`:

```swift
import XCTest
@testable import GamesWithFriends

final class ClueBuildersTests: XCTestCase {
    func testNewClueTypesHaveIcons() {
        let newTypes: [ClueType] = [.genreIdentity, .longevity, .blockbuster, .franchise]
        for type in newTypes {
            XCTAssertFalse(type.icon.isEmpty, "\(type) must have an icon")
        }
    }
}
```

- [ ] **Step 2: Sync and run to verify it fails**

```bash
ruby Scripts/setup_test_target.rb
cd GamesWithFriends
xcodebuild test -project GamesWithFriends.xcodeproj -scheme GamesWithFriends \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GamesWithFriendsTests/ClueBuildersTests 2>&1 | tail -20
cd ..
```

Expected: FAIL — compile error, `.genreIdentity` etc. not members of `ClueType`.

- [ ] **Step 3: Add the cases and icons**

In `CastingDirectorModels.swift`, change the `ClueType` enum (lines 6-35) to:

```swift
enum ClueType {
    case movieCount
    case decade
    case genre
    case genreIdentity
    case longevity
    case blockbuster
    case franchise
    case movieYearGenre
    case rating
    case director
    case coStar
    case combined
    case movieTitle

    var icon: String {
        switch self {
        case .movieCount, .movieYearGenre, .movieTitle:
            return "film.stack"
        case .decade, .longevity:
            return "calendar"
        case .genre, .genreIdentity:
            return "film"
        case .blockbuster:
            return "flame.fill"
        case .franchise:
            return "rectangle.stack.fill"
        case .rating:
            return "star.fill"
        case .director:
            return "megaphone"
        case .coStar:
            return "person.2"
        case .combined:
            return "sparkles"
        }
    }
}
```

- [ ] **Step 4: Run to verify it passes**

```bash
cd GamesWithFriends
xcodebuild test -project GamesWithFriends.xcodeproj -scheme GamesWithFriends \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GamesWithFriendsTests/ClueBuildersTests 2>&1 | tail -20
cd ..
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add GamesWithFriends/Features/CastingDirector/Models/CastingDirectorModels.swift \
  GamesWithFriends/GamesWithFriendsTests/ClueBuildersTests.swift GamesWithFriends/GamesWithFriends.xcodeproj
git commit -m "feat: add genreIdentity, longevity, blockbuster, franchise clue types"
```

---

## Task 3: Add ClueTuning constants

**Files:**
- Create: `GamesWithFriends/Features/CastingDirector/Services/ClueGeneration/ClueTuning.swift`

These are the spec's tunable thresholds in one place. No test (pure constants); it is exercised by every later task.

- [ ] **Step 1: Create the file**

```swift
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
```

- [ ] **Step 2: Build to confirm it compiles**

```bash
cd GamesWithFriends
xcodebuild build -project GamesWithFriends.xcodeproj -scheme GamesWithFriends \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10
cd ..
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add GamesWithFriends/Features/CastingDirector/Services/ClueGeneration/ClueTuning.swift \
  GamesWithFriends/GamesWithFriends.xcodeproj
git commit -m "feat: add ClueTuning thresholds for clue distinctiveness gates"
```

---

## Task 4: FranchiseDetector (pure, TDD)

**Files:**
- Create: `GamesWithFriends/Features/CastingDirector/Services/ClueGeneration/FranchiseDetector.swift`
- Test: `GamesWithFriendsTests/FranchiseDetectorTests.swift`

Detects franchises by normalizing titles (lowercase, strip subtitle after `:`, strip trailing sequel markers) and grouping films sharing a stem. Conservative to avoid false positives.

- [ ] **Step 1: Write the failing tests**

Create `GamesWithFriends/GamesWithFriendsTests/FranchiseDetectorTests.swift`:

```swift
import XCTest
@testable import GamesWithFriends

final class FranchiseDetectorTests: XCTestCase {
    private func movie(_ title: String, votes: Int) -> Movie {
        Movie(tconst: title, title: title, year: 2010, genres: "Action", rating: 7.0, votes: votes)
    }

    func testDetectsSequelStemAcrossNumberedTitles() {
        let movies = [movie("Iron Man", votes: 300_000),
                      movie("Iron Man 2", votes: 250_000),
                      movie("Iron Man 3", votes: 200_000)]
        let franchises = FranchiseDetector.detect(in: movies, tuning: .default)
        XCTAssertEqual(franchises.count, 1)
        XCTAssertEqual(franchises.first?.films.count, 3)
        XCTAssertEqual(franchises.first?.displayName, "Iron Man")
    }

    func testDetectsSubtitleStem() {
        let movies = [movie("Avengers: Infinity War", votes: 400_000),
                      movie("Avengers: Endgame", votes: 500_000)]
        let franchises = FranchiseDetector.detect(in: movies, tuning: .default)
        XCTAssertEqual(franchises.first?.displayName, "Avengers")
    }

    func testDoesNotFalseMatchSimilarFirstWord() {
        let movies = [movie("Love Actually", votes: 200_000),
                      movie("Love & Other Drugs", votes: 150_000)]
        let franchises = FranchiseDetector.detect(in: movies, tuning: .default)
        XCTAssertTrue(franchises.isEmpty)
    }

    func testRequiresRecognizableCombinedVotes() {
        let movies = [movie("Obscure Saga", votes: 5_000),
                      movie("Obscure Saga 2", votes: 4_000)]
        let franchises = FranchiseDetector.detect(in: movies, tuning: .default)
        XCTAssertTrue(franchises.isEmpty)
    }
}
```

- [ ] **Step 2: Sync and run to verify failure**

```bash
ruby Scripts/setup_test_target.rb
cd GamesWithFriends
xcodebuild test -project GamesWithFriends.xcodeproj -scheme GamesWithFriends \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GamesWithFriendsTests/FranchiseDetectorTests 2>&1 | tail -20
cd ..
```

Expected: FAIL — `FranchiseDetector` undefined.

- [ ] **Step 3: Implement FranchiseDetector**

Create `GamesWithFriends/Features/CastingDirector/Services/ClueGeneration/FranchiseDetector.swift`:

```swift
import Foundation

/// A detected franchise: a group of an actor's films sharing a title stem.
struct Franchise: Equatable {
    let stem: String          // normalized key, e.g. "iron man"
    let displayName: String   // human-readable, e.g. "Iron Man"
    let films: [Movie]
}

/// Pure title-stem franchise detection. Conservative by design.
enum FranchiseDetector {
    static func detect(in movies: [Movie], tuning: ClueTuning) -> [Franchise] {
        // Group films by normalized stem, keeping the shortest original title as the name.
        var groups: [String: [Movie]] = [:]
        for movie in movies {
            let stem = normalize(movie.title)
            guard !stem.isEmpty else { continue }
            groups[stem, default: []].append(movie)
        }

        var result: [Franchise] = []
        for (stem, films) in groups {
            guard films.count >= tuning.franchiseMinFilms else { continue }
            let combinedVotes = films.reduce(0) { $0 + ($1.votes ?? 0) }
            guard combinedVotes >= tuning.franchiseMinCombinedVotes else { continue }
            let display = displayName(for: films)
            result.append(Franchise(stem: stem, displayName: display, films: films))
        }
        // Stable order: most-voted franchise first.
        return result.sorted {
            $0.films.reduce(0) { $0 + ($1.votes ?? 0) } > $1.films.reduce(0) { $0 + ($1.votes ?? 0) }
        }
    }

    /// Lowercase, drop subtitle after a colon, strip trailing sequel markers.
    static func normalize(_ title: String) -> String {
        var s = title.lowercased()
        if let colon = s.firstIndex(of: ":") {
            s = String(s[..<colon])
        }
        s = s.trimmingCharacters(in: .whitespaces)
        // Strip a trailing "part N", roman numerals, or plain digits.
        let patterns = [#"\s+part\s+[ivxlcdm0-9]+$"#, #"\s+[ivxlcdm]+$"#, #"\s+\d+$"#]
        for pattern in patterns {
            if let range = s.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                s = String(s[..<range.lowerBound])
            }
        }
        return s.trimmingCharacters(in: .whitespaces)
    }

    private static func displayName(for films: [Movie]) -> String {
        // Use the normalized stem of the shortest title, title-cased from the original.
        let shortest = films.min { $0.title.count < $1.title.count } ?? films[0]
        let stem = normalize(shortest.title)
        return stem.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
```

- [ ] **Step 4: Run to verify pass**

```bash
cd GamesWithFriends
xcodebuild test -project GamesWithFriends.xcodeproj -scheme GamesWithFriends \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GamesWithFriendsTests/FranchiseDetectorTests 2>&1 | tail -20
cd ..
```

Expected: `** TEST SUCCEEDED **`. (`testDoesNotFalseMatchSimilarFirstWord` passes because "love actually" and "love & other drugs" normalize to different stems.)

- [ ] **Step 5: Commit**

```bash
git add GamesWithFriends/Features/CastingDirector/Services/ClueGeneration/FranchiseDetector.swift \
  GamesWithFriends/GamesWithFriendsTests/FranchiseDetectorTests.swift GamesWithFriends/GamesWithFriends.xcodeproj
git commit -m "feat: add pure FranchiseDetector with title-stem heuristic"
```

---

## Task 5: ActorFacts pure initializer (TDD)

**Files:**
- Create: `GamesWithFriends/Features/CastingDirector/Services/ClueGeneration/ActorFacts.swift`
- Test: `GamesWithFriendsTests/ActorFactsTests.swift`

`ActorFacts` is a pure value computed from raw inputs (no DB). Its initializer derives every aggregate the builders need.

- [ ] **Step 1: Write the failing tests**

Create `GamesWithFriends/GamesWithFriendsTests/ActorFactsTests.swift`:

```swift
import XCTest
@testable import GamesWithFriends

final class ActorFactsTests: XCTestCase {
    private func movie(_ id: String, year: Int?, genres: String?, rating: Double?, votes: Int?) -> Movie {
        Movie(tconst: id, title: id, year: year, genres: genres, rating: rating, votes: votes)
    }

    private func makeFacts(movies: [Movie],
                           directorsByMovie: [String: [Director]] = [:],
                           coStarsByMovie: [String: [Actor]] = [:],
                           qualifiedPool: Set<String> = []) -> ActorFacts {
        ActorFacts(actor: Actor(nconst: "nm1", name: "Target", knownFor: nil),
                   movies: movies,
                   directorsByMovie: directorsByMovie,
                   coStarsByMovie: coStarsByMovie,
                   qualifiedPool: qualifiedPool,
                   tuning: .default)
    }

    func testComputesCreditsGenreAndSpan() {
        let movies = [
            movie("a", year: 2000, genres: "Drama,Crime", rating: 8.5, votes: 600_000),
            movie("b", year: 2010, genres: "Drama", rating: 7.0, votes: 100_000),
            movie("c", year: 2018, genres: "Comedy", rating: 6.0, votes: 30_000)
        ]
        let facts = makeFacts(movies: movies)
        XCTAssertEqual(facts.totalCredits, 3)
        XCTAssertEqual(facts.sortedGenres.first?.genre, "Drama")
        XCTAssertEqual(facts.careerSpanYears, 18)
        XCTAssertEqual(facts.mostActiveDecade, 2010)
    }

    func testIdentifiesAcclaimAndBlockbusters() {
        let movies = [
            movie("a", year: 2000, genres: "Drama", rating: 8.5, votes: 600_000),
            movie("b", year: 2005, genres: "Drama", rating: 8.1, votes: 700_000),
            movie("c", year: 2010, genres: "Drama", rating: 9.0, votes: 40_000)
        ]
        let facts = makeFacts(movies: movies)
        XCTAssertEqual(facts.acclaimedFilms.count, 3)
        XCTAssertEqual(facts.blockbusterFilms.count, 2)
    }

    func testGathersQualifiedCoStarsFromHighVoteFilmsOnly() {
        let movies = [
            movie("a", year: 2000, genres: "Drama", rating: 8.0, votes: 600_000),
            movie("b", year: 2005, genres: "Drama", rating: 7.0, votes: 5_000)
        ]
        let coStars = [
            "a": [Actor(nconst: "nm2", name: "Famous", knownFor: nil),
                  Actor(nconst: "nm3", name: "Unknown", knownFor: nil)],
            "b": [Actor(nconst: "nm4", name: "LowVoteFilmCoStar", knownFor: nil)]
        ]
        let facts = makeFacts(movies: movies, coStarsByMovie: coStars, qualifiedPool: ["nm2"])
        // Only nm2 is qualified, and only film "a" clears coStarMinMovieVotes.
        XCTAssertEqual(facts.coStars.map(\.nconst), ["nm2"])
    }

    func testRanksDirectorsByCollaborationCount() {
        let movies = [
            movie("a", year: 2000, genres: "Drama", rating: 8.0, votes: 600_000),
            movie("b", year: 2005, genres: "Drama", rating: 8.0, votes: 500_000),
            movie("c", year: 2010, genres: "Drama", rating: 8.0, votes: 100_000)
        ]
        let nolan = Director(nconst: "d1", name: "Nolan")
        let other = Director(nconst: "d2", name: "Other")
        let dirs = ["a": [nolan], "b": [nolan], "c": [other]]
        let facts = makeFacts(movies: movies, directorsByMovie: dirs)
        XCTAssertEqual(facts.directorsByFrequency.first?.director.name, "Nolan")
        XCTAssertEqual(facts.directorsByFrequency.first?.count, 2)
    }
}
```

- [ ] **Step 2: Sync and run to verify failure**

```bash
ruby Scripts/setup_test_target.rb
cd GamesWithFriends
xcodebuild test -project GamesWithFriends.xcodeproj -scheme GamesWithFriends \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GamesWithFriendsTests/ActorFactsTests 2>&1 | tail -20
cd ..
```

Expected: FAIL — `ActorFacts` undefined.

- [ ] **Step 3: Implement ActorFacts**

Create `GamesWithFriends/Features/CastingDirector/Services/ClueGeneration/ActorFacts.swift`:

```swift
import Foundation

struct GenreCount: Equatable {
    let genre: String
    let count: Int
}

struct DirectorCredit: Equatable {
    let director: Director
    let count: Int
    let topMovie: Movie   // their highest-vote movie with this actor
}

/// Pure, fully-derived view of everything the clue builders need about an actor.
struct ActorFacts {
    let actor: Actor
    let movies: [Movie]                 // sorted by votes desc
    let totalCredits: Int
    let sortedGenres: [GenreCount]      // desc by count
    let topGenreShare: Double
    let mostActiveDecade: Int?
    let breakoutDecade: Int?            // decade of earliest recognizable film
    let careerSpanYears: Int
    let acclaimedFilms: [Movie]         // rating >= acclaimRating, votes desc
    let blockbusterFilms: [Movie]       // votes >= blockbusterVotes
    let signatureFilms: [Movie]         // recognizable (votes >= anchoredFilmMinVotes)
    let directorsByFrequency: [DirectorCredit]   // desc by count, then movie votes
    let coStars: [Actor]                // qualified, from high-vote films, fame order
    let franchises: [Franchise]
    let tuning: ClueTuning

    init(actor: Actor,
         movies rawMovies: [Movie],
         directorsByMovie: [String: [Director]],
         coStarsByMovie: [String: [Actor]],
         qualifiedPool: Set<String>,
         tuning: ClueTuning) {
        self.actor = actor
        self.tuning = tuning

        let sorted = rawMovies.sorted { ($0.votes ?? 0) > ($1.votes ?? 0) }
        self.movies = sorted
        self.totalCredits = sorted.count

        // Genre frequency
        var genreFreq: [String: Int] = [:]
        for movie in sorted {
            guard let genres = movie.genres else { continue }
            for raw in genres.components(separatedBy: ",") {
                let g = raw.trimmingCharacters(in: .whitespaces)
                guard !g.isEmpty else { continue }
                genreFreq[g, default: 0] += 1
            }
        }
        let sortedGenres = genreFreq
            .map { GenreCount(genre: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        self.sortedGenres = sortedGenres
        self.topGenreShare = sorted.isEmpty ? 0
            : Double(sortedGenres.first?.count ?? 0) / Double(sorted.count)

        // Decades
        var decadeCounts: [Int: Int] = [:]
        for movie in sorted {
            guard let year = movie.year else { continue }
            decadeCounts[(year / 10) * 10, default: 0] += 1
        }
        self.mostActiveDecade = decadeCounts.max { $0.value < $1.value }?.key

        let years = sorted.compactMap(\.year)
        self.careerSpanYears = (years.max() ?? 0) - (years.min() ?? 0)

        let earliestRecognizable = sorted
            .filter { ($0.votes ?? 0) >= tuning.anchoredFilmMinVotes }
            .compactMap(\.year)
            .min() ?? years.min()
        self.breakoutDecade = earliestRecognizable.map { ($0 / 10) * 10 }

        // Acclaim / blockbusters / signature
        self.acclaimedFilms = sorted.filter { ($0.rating ?? 0) >= tuning.acclaimRating }
        self.blockbusterFilms = sorted.filter { ($0.votes ?? 0) >= tuning.blockbusterVotes }
        let signature = sorted.filter { ($0.votes ?? 0) >= tuning.anchoredFilmMinVotes }
        self.signatureFilms = signature.isEmpty ? Array(sorted.prefix(3)) : signature

        // Directors by frequency (representative top movie = their highest-vote film)
        var counts: [String: (director: Director, count: Int, top: Movie)] = [:]
        for movie in sorted {
            for director in directorsByMovie[movie.tconst] ?? [] {
                if let existing = counts[director.nconst] {
                    let top = (movie.votes ?? 0) > (existing.top.votes ?? 0) ? movie : existing.top
                    counts[director.nconst] = (director, existing.count + 1, top)
                } else {
                    counts[director.nconst] = (director, 1, movie)
                }
            }
        }
        self.directorsByFrequency = counts.values
            .map { DirectorCredit(director: $0.director, count: $0.count, topMovie: $0.top) }
            .sorted {
                $0.count != $1.count ? $0.count > $1.count
                    : ($0.topMovie.votes ?? 0) > ($1.topMovie.votes ?? 0)
            }

        // Co-stars: from high-vote films only, qualified, fame order, deduped.
        var seen: Set<String> = [actor.nconst]
        var stars: [Actor] = []
        for movie in sorted where (movie.votes ?? 0) >= tuning.coStarMinMovieVotes {
            for coStar in coStarsByMovie[movie.tconst] ?? [] {
                guard !seen.contains(coStar.nconst) else { continue }
                seen.insert(coStar.nconst)
                if qualifiedPool.contains(coStar.nconst) {
                    stars.append(coStar)
                }
            }
        }
        self.coStars = stars

        self.franchises = FranchiseDetector.detect(in: sorted, tuning: tuning)
    }
}
```

- [ ] **Step 4: Run to verify pass**

```bash
cd GamesWithFriends
xcodebuild test -project GamesWithFriends.xcodeproj -scheme GamesWithFriends \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GamesWithFriendsTests/ActorFactsTests 2>&1 | tail -20
cd ..
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add GamesWithFriends/Features/CastingDirector/Services/ClueGeneration/ActorFacts.swift \
  GamesWithFriends/GamesWithFriendsTests/ActorFactsTests.swift GamesWithFriends/GamesWithFriends.xcodeproj
git commit -m "feat: add pure ActorFacts deriving clue-relevant aggregates"
```

---

## Task 6: ClueBuilders — pure builder functions (TDD)

**Files:**
- Create: `GamesWithFriends/Features/CastingDirector/Services/ClueGeneration/ClueBuilders.swift`
- Test: `GamesWithFriendsTests/ClueBuildersTests.swift` (extend the file from Task 2)

Each builder is pure: `(ActorFacts) -> Clue?` or `-> [Clue]`. Builders set `text`, `type`, `tier`; `orderNumber` is a placeholder (`0`) — the assembler renumbers. Gates suppress generic clues.

- [ ] **Step 1: Write the failing tests**

Replace the body of `GamesWithFriends/GamesWithFriendsTests/ClueBuildersTests.swift` with (keeping the icon test, adding builder tests):

```swift
import XCTest
@testable import GamesWithFriends

final class ClueBuildersTests: XCTestCase {
    func testNewClueTypesHaveIcons() {
        let newTypes: [ClueType] = [.genreIdentity, .longevity, .blockbuster, .franchise]
        for type in newTypes {
            XCTAssertFalse(type.icon.isEmpty, "\(type) must have an icon")
        }
    }

    private func movie(_ id: String, year: Int? = 2010, genres: String? = "Drama",
                       rating: Double? = 7.0, votes: Int? = 100_000) -> Movie {
        Movie(tconst: id, title: id, year: year, genres: genres, rating: rating, votes: votes)
    }

    private func facts(movies: [Movie],
                       directorsByMovie: [String: [Director]] = [:],
                       coStarsByMovie: [String: [Actor]] = [:],
                       qualifiedPool: Set<String> = []) -> ActorFacts {
        ActorFacts(actor: Actor(nconst: "nm1", name: "Target", knownFor: nil),
                   movies: movies, directorsByMovie: directorsByMovie,
                   coStarsByMovie: coStarsByMovie, qualifiedPool: qualifiedPool, tuning: .default)
    }

    func testGenreIdentityFiresWhenConcentrated() {
        let f = facts(movies: [movie("a", genres: "Drama"), movie("b", genres: "Drama"),
                               movie("c", genres: "Drama"), movie("d", genres: "Comedy")])
        let clue = ClueBuilders.genreIdentity(f)
        XCTAssertNotNil(clue)
        XCTAssertEqual(clue?.type, .genreIdentity)
        XCTAssertTrue(clue?.text.contains("Drama") == true)
    }

    func testGenreIdentitySuppressedWhenSpread() {
        let f = facts(movies: [movie("a", genres: "Drama"), movie("b", genres: "Comedy"),
                               movie("c", genres: "Action"), movie("d", genres: "Horror"),
                               movie("e", genres: "Sci-Fi")])
        XCTAssertNil(ClueBuilders.genreIdentity(f))
    }

    func testLongevityFiresForLongCareerOnly() {
        let long = facts(movies: [movie("a", year: 1980), movie("b", year: 2015)])
        XCTAssertNotNil(ClueBuilders.longevity(long))
        let short = facts(movies: [movie("a", year: 2010), movie("b", year: 2015)])
        XCTAssertNil(ClueBuilders.longevity(short))
    }

    func testProlificAndSelective() {
        let prolific = facts(movies: (0..<60).map { movie("m\($0)") })
        XCTAssertEqual(ClueBuilders.prolificOrSelective(prolific)?.text, "A remarkably prolific actor")

        let selective = facts(movies: [movie("a", rating: 8.5), movie("b", rating: 8.2),
                                       movie("c", rating: 8.1)])
        XCTAssertTrue(ClueBuilders.prolificOrSelective(selective)?.text.contains("selective") == true)

        let neither = facts(movies: [movie("a", rating: 6.0), movie("b", rating: 6.0)])
        XCTAssertNil(ClueBuilders.prolificOrSelective(neither))
    }

    func testBlockbusterFiresWithEnoughBigFilms() {
        let f = facts(movies: [movie("a", votes: 600_000), movie("b", votes: 700_000)])
        XCTAssertNotNil(ClueBuilders.blockbuster(f))
        let small = facts(movies: [movie("a", votes: 600_000), movie("b", votes: 10_000)])
        XCTAssertNil(ClueBuilders.blockbuster(small))
    }

    func testFranchiseUnnamedAndNamed() {
        let movies = [Movie(tconst: "1", title: "Thor", year: 2011, genres: "Action", rating: 7.0, votes: 300_000),
                      Movie(tconst: "2", title: "Thor: Ragnarok", year: 2017, genres: "Action", rating: 7.9, votes: 400_000)]
        let f = facts(movies: movies)
        XCTAssertEqual(ClueBuilders.franchiseUnnamed(f)?.tier, .narrowing)
        XCTAssertEqual(ClueBuilders.franchiseNamed(f)?.text, "Part of the Thor franchise")
    }

    func testAcclaimFiresWithThreeHighRatedFilms() {
        let f = facts(movies: [movie("a", rating: 8.1), movie("b", rating: 8.5), movie("c", rating: 9.0)])
        XCTAssertNotNil(ClueBuilders.acclaim(f))
        let f2 = facts(movies: [movie("a", rating: 8.1), movie("b", rating: 7.0)])
        XCTAssertNil(ClueBuilders.acclaim(f2))
    }

    func testFrequentDirectorAndNamedDirectorsExcludeOverlap() {
        let movies = [movie("a", votes: 600_000), movie("b", votes: 500_000),
                      movie("c", votes: 400_000), movie("d", votes: 100_000)]
        let nolan = Director(nconst: "d1", name: "Nolan")
        let other = Director(nconst: "d2", name: "Other")
        let dirs = ["a": [nolan], "b": [nolan], "c": [nolan], "d": [other]]
        let f = facts(movies: movies, directorsByMovie: dirs)
        XCTAssertEqual(ClueBuilders.frequentDirector(f)?.text, "A regular in Nolan's films")
        let named = ClueBuilders.namedDirectors(f)
        XCTAssertFalse(named.contains { $0.text.contains("Nolan") }, "frequent director must not repeat")
        XCTAssertTrue(named.contains { $0.text.contains("Other") })
    }

    func testNamedCoStars() {
        let movies = [movie("a", votes: 600_000)]
        let costars = ["a": [Actor(nconst: "nm2", name: "Idris Elba", knownFor: nil)]]
        let f = facts(movies: movies, coStarsByMovie: costars, qualifiedPool: ["nm2"])
        XCTAssertEqual(ClueBuilders.namedCoStars(f).first?.text, "Co-starred with Idris Elba")
    }

    func testExactTitlesMostFamousLast() {
        let movies = [movie("Small", votes: 60_000), movie("Mid", votes: 200_000),
                      movie("Huge", votes: 900_000)]
        let titles = ClueBuilders.exactTitles(facts(movies: movies), count: 2)
        XCTAssertEqual(titles.count, 2)
        XCTAssertTrue(titles.last?.text.contains("Huge") == true)
        XCTAssertEqual(titles.last?.tier, .giveaway)
    }
}
```

- [ ] **Step 2: Run to verify failure**

```bash
cd GamesWithFriends
xcodebuild test -project GamesWithFriends.xcodeproj -scheme GamesWithFriends \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GamesWithFriendsTests/ClueBuildersTests 2>&1 | tail -20
cd ..
```

Expected: FAIL — `ClueBuilders` undefined.

- [ ] **Step 3: Implement ClueBuilders**

Create `GamesWithFriends/Features/CastingDirector/Services/ClueGeneration/ClueBuilders.swift`:

```swift
import Foundation

/// Pure builders. Each returns a clue only when its distinctiveness gate passes.
/// `orderNumber` is a placeholder (0); the assembler renumbers.
enum ClueBuilders {

    private static func clue(_ text: String, _ type: ClueType, _ tier: ClueTier) -> Clue {
        Clue(text: text, type: type, tier: tier, orderNumber: 0)
    }

    // MARK: Vague

    static func genreIdentity(_ f: ActorFacts) -> Clue? {
        guard let top = f.sortedGenres.first, f.topGenreShare >= f.tuning.genreIdentityShare else { return nil }
        if f.sortedGenres.count >= 2 {
            let second = f.sortedGenres[1]
            return clue("Best known for \(top.genre) and \(second.genre)", .genreIdentity, .vague)
        }
        return clue("Best known for \(top.genre)", .genreIdentity, .vague)
    }

    static func breakout(_ f: ActorFacts) -> Clue? {
        guard let decade = f.breakoutDecade else { return nil }
        return clue("First gained recognition in the \(decade)s", .decade, .vague)
    }

    static func longevity(_ f: ActorFacts) -> Clue? {
        guard f.careerSpanYears >= f.tuning.longevitySpanYears else { return nil }
        let rounded = (f.careerSpanYears / 10) * 10
        return clue("Has been working for over \(rounded) years", .longevity, .vague)
    }

    static func prolificOrSelective(_ f: ActorFacts) -> Clue? {
        if f.totalCredits >= f.tuning.prolificThreshold {
            return clue("A remarkably prolific actor", .movieCount, .vague)
        }
        if f.totalCredits <= f.tuning.selectiveMaxCredits && f.acclaimedFilms.count >= 3 {
            return clue("A selective actor with a small but acclaimed body of work", .movieCount, .vague)
        }
        return nil
    }

    static func blockbuster(_ f: ActorFacts) -> Clue? {
        guard f.blockbusterFilms.count >= f.tuning.blockbusterCount else { return nil }
        return clue("Star of several blockbusters", .blockbuster, .vague)
    }

    // MARK: Narrowing

    static func franchiseUnnamed(_ f: ActorFacts) -> Clue? {
        guard !f.franchises.isEmpty else { return nil }
        return clue("Has a recurring role in a major franchise", .franchise, .narrowing)
    }

    static func anchoredFilm(_ f: ActorFacts) -> Clue? {
        // Prefer a recognizable, acclaimed film with a year and genre.
        let candidate = f.signatureFilms.first { $0.year != nil && $0.genres != nil }
        guard let movie = candidate, let year = movie.year else { return nil }
        let genre = movie.genres?.components(separatedBy: ",").first?
            .trimmingCharacters(in: .whitespaces).lowercased() ?? "film"
        let acclaimed = (movie.rating ?? 0) >= f.tuning.acclaimRating
        let lead = acclaimed ? "Led an acclaimed" : "Appeared in a"
        return clue("\(lead) \(year) \(genre) film", .movieYearGenre, .narrowing)
    }

    static func acclaim(_ f: ActorFacts) -> Clue? {
        guard f.acclaimedFilms.count >= f.tuning.acclaimCount else { return nil }
        let threshold = String(format: "%.1f", f.tuning.acclaimRating)
        return clue("Has several films rated above \(threshold)", .rating, .narrowing)
    }

    // MARK: Strong

    static func frequentDirector(_ f: ActorFacts) -> Clue? {
        guard let top = f.directorsByFrequency.first, top.count >= f.tuning.frequentDirectorCount else { return nil }
        return clue("A regular in \(top.director.name)'s films", .director, .strongSignal)
    }

    /// Named directors, excluding any already covered by the frequent-director clue.
    static func namedDirectors(_ f: ActorFacts, limit: Int = 2) -> [Clue] {
        f.directorsByFrequency
            .filter { $0.count < f.tuning.frequentDirectorCount }
            .prefix(limit)
            .map { clue("Worked with director \($0.director.name)", .director, .strongSignal) }
    }

    static func namedCoStars(_ f: ActorFacts, limit: Int = 2) -> [Clue] {
        f.coStars.prefix(limit).map { clue("Co-starred with \($0.name)", .coStar, .strongSignal) }
    }

    static func franchiseNamed(_ f: ActorFacts) -> Clue? {
        guard let franchise = f.franchises.first else { return nil }
        return clue("Part of the \(franchise.displayName) franchise", .franchise, .strongSignal)
    }

    static func combinedDirectorFilm(_ f: ActorFacts) -> Clue? {
        guard let top = f.directorsByFrequency.first, let year = top.topMovie.year else { return nil }
        return clue("Appeared in a \(year) film directed by \(top.director.name)", .combined, .strongSignal)
    }

    // MARK: Giveaway

    /// Exact titles spread across fame levels, most famous revealed last.
    static func exactTitles(_ f: ActorFacts, count: Int) -> [Clue] {
        let byFame = f.movies.sorted { ($0.votes ?? 0) < ($1.votes ?? 0) }
        guard count > 0, !byFame.isEmpty else { return [] }

        let selected: [Movie]
        if byFame.count <= count {
            selected = byFame
        } else {
            var picks: [Movie] = []
            let step = max(1, byFame.count / count)
            for i in 0..<count {
                picks.append(byFame[min(i * step, byFame.count - 1)])
            }
            if let mostFamous = byFame.last, picks.last?.tconst != mostFamous.tconst {
                picks[picks.count - 1] = mostFamous
            }
            selected = picks
        }
        return selected.map { clue("Appeared in \"\($0.displayTitle)\"", .movieTitle, .giveaway) }
    }
}
```

- [ ] **Step 4: Run to verify pass**

```bash
cd GamesWithFriends
xcodebuild test -project GamesWithFriends.xcodeproj -scheme GamesWithFriends \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GamesWithFriendsTests/ClueBuildersTests 2>&1 | tail -20
cd ..
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add GamesWithFriends/Features/CastingDirector/Services/ClueGeneration/ClueBuilders.swift \
  GamesWithFriends/GamesWithFriendsTests/ClueBuildersTests.swift GamesWithFriends/GamesWithFriends.xcodeproj
git commit -m "feat: add pure distinctiveness-gated clue builders"
```

---

## Task 7: ClueLadderAssembler (TDD)

**Files:**
- Create: `GamesWithFriends/Features/CastingDirector/Services/ClueGeneration/ClueLadderAssembler.swift`
- Test: `GamesWithFriendsTests/ClueLadderAssemblerTests.swift`

Assembles builder output into the final ladder: tier order (vague → narrowing → strong → giveaway), Hard-mode co-star relocation, **giveaway-slot reservation** (the bug fix), difficulty budget, renumbering.

- [ ] **Step 1: Write the failing tests**

Create `GamesWithFriends/GamesWithFriendsTests/ClueLadderAssemblerTests.swift`:

```swift
import XCTest
@testable import GamesWithFriends

final class ClueLadderAssemblerTests: XCTestCase {
    private func movie(_ id: String, year: Int = 2010, genres: String = "Drama",
                       rating: Double = 8.5, votes: Int) -> Movie {
        Movie(tconst: id, title: id, year: year, genres: genres, rating: rating, votes: votes)
    }

    /// A rich actor that triggers many gates, used to stress the budget/reservation logic.
    private func richFacts() -> ActorFacts {
        let movies = (0..<12).map { movie("Film\($0)", year: 1985 + $0, votes: 100_000 + $0 * 50_000) }
        let nolan = Director(nconst: "d1", name: "Nolan")
        var dirs: [String: [Director]] = [:]
        for m in movies.prefix(4) { dirs[m.tconst] = [nolan] }
        let costars = ["Film11": [Actor(nconst: "nm2", name: "Idris Elba", knownFor: nil),
                                  Actor(nconst: "nm3", name: "Emma Stone", knownFor: nil)]]
        return ActorFacts(actor: Actor(nconst: "nm1", name: "Target", knownFor: nil),
                          movies: movies, directorsByMovie: dirs, coStarsByMovie: costars,
                          qualifiedPool: ["nm2", "nm3"], tuning: .default)
    }

    func testLadderIsTierOrderedAndRenumbered() {
        let clues = ClueLadderAssembler.assemble(facts: richFacts(), difficulty: .easy, tuning: .default)
        XCTAssertFalse(clues.isEmpty)
        // orderNumber is sequential from 1
        XCTAssertEqual(clues.map(\.orderNumber), Array(1...clues.count))
        // tiers never decrease across the ladder
        let tiers = clues.map { $0.tier.rawValue }
        XCTAssertEqual(tiers, tiers.sorted())
    }

    func testRespectsMaxCluesBudget() {
        let clues = ClueLadderAssembler.assemble(facts: richFacts(), difficulty: .hard, tuning: .default)
        XCTAssertLessThanOrEqual(clues.count, CastingDirectorDifficulty.hard.maxClues)
    }

    func testReservesGiveawayTitleSlotOnHard() {
        // The core bug fix: titles must survive the Hard budget of 8.
        let clues = ClueLadderAssembler.assemble(facts: richFacts(), difficulty: .hard, tuning: .default)
        XCTAssertTrue(clues.contains { $0.type == .movieTitle },
                      "at least one exact-title clue must appear within the Hard budget")
    }

    func testHardModeMovesCoStarsLate() {
        let clues = ClueLadderAssembler.assemble(facts: richFacts(), difficulty: .hard, tuning: .default)
        if let coStar = clues.first(where: { $0.type == .coStar }) {
            XCTAssertEqual(coStar.tier, .giveaway, "Hard mode co-stars belong in the giveaway tier")
        }
    }

    func testFallbackActorStillGetsTitle() {
        // Actor that triggers no special gates: few films, mixed genres, short career, low ratings.
        let movies = [movie("A", year: 2018, genres: "Drama", rating: 6.0, votes: 60_000),
                      movie("B", year: 2019, genres: "Comedy", rating: 6.2, votes: 80_000),
                      movie("C", year: 2020, genres: "Action", rating: 6.1, votes: 120_000)]
        let facts = ActorFacts(actor: Actor(nconst: "nm9", name: "Plain", knownFor: nil),
                               movies: movies, directorsByMovie: [:], coStarsByMovie: [:],
                               qualifiedPool: [], tuning: .default)
        let clues = ClueLadderAssembler.assemble(facts: facts, difficulty: .medium, tuning: .default)
        XCTAssertTrue(clues.contains { $0.type == .movieTitle })
        XCTAssertFalse(clues.isEmpty)
    }
}
```

- [ ] **Step 2: Sync and run to verify failure**

```bash
ruby Scripts/setup_test_target.rb
cd GamesWithFriends
xcodebuild test -project GamesWithFriends.xcodeproj -scheme GamesWithFriends \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GamesWithFriendsTests/ClueLadderAssemblerTests 2>&1 | tail -20
cd ..
```

Expected: FAIL — `ClueLadderAssembler` undefined.

- [ ] **Step 3: Implement ClueLadderAssembler**

Create `GamesWithFriends/Features/CastingDirector/Services/ClueGeneration/ClueLadderAssembler.swift`:

```swift
import Foundation

/// Assembles builder output into the final, budget-respecting clue ladder.
enum ClueLadderAssembler {

    static func assemble(facts: ActorFacts,
                         difficulty: CastingDirectorDifficulty,
                         tuning: ClueTuning) -> [Clue] {
        // 1. Run builders by tier.
        let vague: [Clue] = [
            ClueBuilders.genreIdentity(facts),
            ClueBuilders.breakout(facts),
            ClueBuilders.longevity(facts),
            ClueBuilders.prolificOrSelective(facts),
            ClueBuilders.blockbuster(facts)
        ].compactMap { $0 }

        let narrowing: [Clue] = [
            ClueBuilders.franchiseUnnamed(facts),
            ClueBuilders.anchoredFilm(facts),
            ClueBuilders.acclaim(facts)
        ].compactMap { $0 }

        var strong: [Clue] = []
        if let freq = ClueBuilders.frequentDirector(facts) { strong.append(freq) }
        strong.append(contentsOf: ClueBuilders.namedDirectors(facts))
        if let named = ClueBuilders.franchiseNamed(facts) { strong.append(named) }
        if let combined = ClueBuilders.combinedDirectorFilm(facts) { strong.append(combined) }

        let coStarClues = ClueBuilders.namedCoStars(facts)

        // 2. Co-star placement by difficulty.
        var giveawayCoStars: [Clue] = []
        if difficulty.showCoStarsEarly {
            strong.append(contentsOf: coStarClues)
        } else {
            // Hard: relocate a single co-star to the giveaway tier.
            giveawayCoStars = coStarClues.prefix(1).map {
                Clue(text: $0.text, type: .coStar, tier: .giveaway, orderNumber: 0)
            }
        }

        // 3. Giveaway titles + relocated co-stars (reserved).
        let titles = ClueBuilders.exactTitles(facts, count: difficulty.movieTitleCluesCount)
        let reserved = giveawayCoStars + titles

        // 4. Budget: reserve giveaway slots first, then fill earlier tiers.
        let budget = difficulty.maxClues
        let reservedCount = min(reserved.count, budget)
        let earlyBudget = max(0, budget - reservedCount)
        let early = Array((vague + narrowing + strong).prefix(earlyBudget))
        var ladder = early + Array(reserved.prefix(reservedCount))

        // 5. Renumber sequentially.
        ladder = ladder.enumerated().map { index, clue in
            Clue(text: clue.text, type: clue.type, tier: clue.tier, orderNumber: index + 1)
        }
        return ladder
    }
}
```

- [ ] **Step 4: Run to verify pass**

```bash
cd GamesWithFriends
xcodebuild test -project GamesWithFriends.xcodeproj -scheme GamesWithFriends \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GamesWithFriendsTests/ClueLadderAssemblerTests 2>&1 | tail -20
cd ..
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add GamesWithFriends/Features/CastingDirector/Services/ClueGeneration/ClueLadderAssembler.swift \
  GamesWithFriends/GamesWithFriendsTests/ClueLadderAssemblerTests.swift GamesWithFriends/GamesWithFriends.xcodeproj
git commit -m "feat: add ClueLadderAssembler with giveaway-slot reservation"
```

---

## Task 8: Wire ClueGenerator to the new pipeline

**Files:**
- Modify: `GamesWithFriends/Features/CastingDirector/Services/ClueGenerator.swift:62-254` (replace `generateClues` body, remove now-dead helpers, keep actor-pool methods above line 62)

`generateClues` becomes thin glue: fetch raw DB data, build `ActorFacts`, delegate to the assembler. The DB-touching part is the only untested glue (verified end-to-end in Task 9).

- [ ] **Step 1: Replace generateClues and remove dead helpers**

In `ClueGenerator.swift`, replace everything from the start of `generateClues(for:difficulty:)` (line 62) through the **final closing brace of the file** (line 254, the class-closing `}`) — i.e. the entire `// MARK: - Clue Generation` and `// MARK: - Helpers` sections plus the class's closing brace — with the following (the block below ends with both the method's `}` and the class's `}`, so do not leave the original line 254 in place):

```swift
    // MARK: - Clue Generation

    /// Generate an ordered array of clues for the given actor, respecting difficulty settings.
    func generateClues(for actor: Actor, difficulty: CastingDirectorDifficulty) -> [Clue] {
        let movies = database.getMoviesWithActor(actorId: actor.nconst)
        guard !movies.isEmpty else { return [] }

        let tuning = ClueTuning.default
        let qualifiedPool = Set(getQualifiedActors())

        // Fetch raw directors and co-stars per movie (the only DB-touching step).
        var directorsByMovie: [String: [Director]] = [:]
        var coStarsByMovie: [String: [Actor]] = [:]
        for movie in movies {
            directorsByMovie[movie.tconst] = database.getDirectorsOfMovie(movieId: movie.tconst)
            if (movie.votes ?? 0) >= tuning.coStarMinMovieVotes {
                coStarsByMovie[movie.tconst] = database.getActorsInMovie(movieId: movie.tconst)
            }
        }

        let facts = ActorFacts(actor: actor,
                               movies: movies,
                               directorsByMovie: directorsByMovie,
                               coStarsByMovie: coStarsByMovie,
                               qualifiedPool: qualifiedPool,
                               tuning: tuning)

        return ClueLadderAssembler.assemble(facts: facts, difficulty: difficulty, tuning: tuning)
    }
}
```

> Note: this deletes the old inline tier logic and the `computeGenreFrequency` / `computeMostActiveDecade` private helpers (their logic now lives in `ActorFacts`). Ensure the final closing brace count is correct — the file ends after this method's `}` plus the class-closing `}` shown above. The actor-pool methods (`getQualifiedActors`, `pickRandomActor`, etc.) above line 62 are unchanged.

- [ ] **Step 2: Build to confirm it compiles**

```bash
cd GamesWithFriends
xcodebuild build -project GamesWithFriends.xcodeproj -scheme GamesWithFriends \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -15
cd ..
```

Expected: `** BUILD SUCCEEDED **`. If "cannot find type" errors appear, confirm the new files compile into the **app** target (they live under `Features/…/Services/ClueGeneration/`; new `.swift` files in an existing source group are usually auto-added, but if Xcode reports them missing, add them to the `GamesWithFriends` target membership).

- [ ] **Step 3: Run the full test suite**

```bash
cd GamesWithFriends
xcodebuild test -project GamesWithFriends.xcodeproj -scheme GamesWithFriends \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GamesWithFriendsTests 2>&1 | tail -20
cd ..
```

Expected: `** TEST SUCCEEDED **` — all suites green.

- [ ] **Step 4: Commit**

```bash
git add GamesWithFriends/Features/CastingDirector/Services/ClueGenerator.swift \
  GamesWithFriends/GamesWithFriends.xcodeproj
git commit -m "refactor: route ClueGenerator through ActorFacts + ClueLadderAssembler"
```

---

## Task 9: End-to-end verification in the simulator

**Files:** none (verification only)

Confirms real database actors produce sensible, distinctive ladders and that the giveaway titles always appear.

- [ ] **Step 1: Launch the app and play Casting Director**

Build and run on the simulator (via Xcode Run, or the `run` skill). Start a Casting Director game on **Hard** (the tightest budget, where the old title-trim bug lived).

- [ ] **Step 2: Verify the ladder quality**

Watch a full round reveal and confirm:
- Early clues are distinctive (genre identity / era / prolific / blockbuster / franchise), not "Appeared in N movies" or "rated 6.8/10".
- No bare movie-count or rating-only clues appear.
- At least one exact movie title appears before the round exhausts its clues.
- Co-stars appear late on Hard.

Repeat for 3–4 rounds to sample different actors (including one obscure actor to exercise the fallback path).

- [ ] **Step 3: Record the result**

Note any clue that still reads as generic or any actor whose ladder looks wrong. If a threshold needs tuning, adjust the relevant constant in `ClueTuning.swift` and re-run Task 8's test suite. No commit unless tuning changed; if so:

```bash
git add GamesWithFriends/Features/CastingDirector/Services/ClueGeneration/ClueTuning.swift
git commit -m "tune: adjust clue thresholds after playtest"
```

---

## Self-Review Notes

- **Spec coverage:** removed clues (movie-count, rating-only) → Task 8 drops them, no builder emits them. Anchored signature films → `anchoredFilm`/`exactTitles` use `signatureFilms` (Task 6). Genre-identity collapse → Task 6. All new clue types → Tasks 2/6. Distinctiveness gates per type → Task 6 + thresholds in Task 3. Pipeline refactor → Tasks 5/7/8. Reserved giveaway slots / Hard-trim bug fix → Task 7. Fallback safety → Task 7 `testFallbackActorStillGetsTitle`. Franchise heuristic → Task 4. Tunable constants → Task 3. Testing strategy → Task 1 + per-task tests. Difficulty unchanged → Task 7 reuses existing `CastingDirectorDifficulty` knobs only.
- **Type consistency:** `ActorFacts` initializer signature, `GenreCount`/`DirectorCredit`/`Franchise` structs, `ClueBuilders` static method names, and `ClueLadderAssembler.assemble(facts:difficulty:tuning:)` are referenced identically across Tasks 5–8.
- **No placeholders:** every code step contains complete, compilable code and exact commands.
