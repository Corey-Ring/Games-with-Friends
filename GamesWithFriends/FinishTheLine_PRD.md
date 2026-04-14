# Finish the Line — Product Requirements Document

**Status:** Draft v1
**Author:** Corey Ring (with Claude)
**Last updated:** 2026-04-13
**Game mode in scope:** Spotlight (single-player turn-based)

---

## 1. Overview / Problem / Opportunity

### The problem
"Games with Friends" currently ships 9 games, but none are **purely verbal**. Every existing game requires the player to look at the screen and tap. That's a poor fit for the app's two core usage contexts:

1. **Road trips** — drivers can't look at a screen; passengers lose engagement when phone-bound games trap attention away from shared moments.
2. **Parties** — games that require passing a tiny screen around create awkward pauses and break the social energy of a room.

The app's most on-brand game — License Plate Game — gets close (eyes up, looking out the window), but it's a passive collection mechanic. There's nothing in the hub that turns the phone into a **host** rather than a screen to stare at.

### The opportunity
Sporcle has proven — across millions of daily plays — that **quote completion** ("fill in the missing word/phrase from something culturally iconic") is one of the stickiest quiz mechanics ever built. The feeling of "I KNOW this... I know this..." creates tip-of-tongue tension that's almost physical.

The constraint on Sporcle's version is that it's **keyboard-bound**. On desktop, that's fine. On mobile, typing is miserable. **But what if the player doesn't type — what if they speak?**

We already have offline, on-device speech recognition working well in **Border Blitz** (`Features/BorderBlitz/Services/BorderBlitzSpeechRecognitionManager.swift`). Its multi-pass sliding-window fuzzy matching is *more suited* to multi-word phrase matching than to the single-country matching it was built for. This is a rare case where infrastructure already exists for the thing we want to build.

### Why now
- Border Blitz shipped and proved the voice-input paradigm works for users in this app.
- The hub is at 9 games — we need to start adding games that carve out new *emotional* territory, not just new categories within existing mechanics (trivia, geography, collecting).
- Spotlight mode is the first voice-party-game format in the app. It establishes a new archetype we can build more games on later (e.g., "Group Shout" mode is the natural follow-up).

### The elevator pitch
> **Finish the Line** is a verbal party game where one player at a time holds the phone and races a 60-second clock to speak the missing word from as many iconic quotes as they can. The phone is the host; the players are the performers. It's Sporcle's best format, finally made for a car full of friends.

---

## 2. Goals & Non-Goals

### Goals

| # | Goal | How we know we succeeded |
|---|---|---|
| G1 | Ship a voice-first party game that works **hands-free** (no typing, minimal tapping) | Core loop completable while looking away from screen |
| G2 | Deliver the "tip-of-tongue" emotional payoff that makes quote completion addictive | Playtesters laugh, groan, or shout at the screen during a test round |
| G3 | Extract durable value from the Border Blitz speech recognition investment | Second game ships using the same underlying mechanic, validating future reuse |
| G4 | Provide intergenerational appeal so mixed-age groups all have moments to shine | Content library spans 6+ decades with balanced distribution |
| G5 | Stay faithful to the app's "warm minimalism, purposeful color" design philosophy | Code review confirms no hardcoded colors/spacing, uses `AppTheme`/`GameTheme` tokens throughout |

### Non-Goals (for this version)

| # | Non-goal | Why it's out of scope |
|---|---|---|
| NG1 | **Simultaneous multiplayer ("Group Shout" mode)** where everyone yells at the phone at once | Needs speaker identification, which iOS doesn't provide out-of-box. Parked for a future version — see §9. |
| NG2 | **Online content updates / DLC** | Violates the app's offline-first, zero-external-dependencies mandate. Content ships bundled. |
| NG3 | **Daily challenge integration** | Interesting retention mechanic but orthogonal to shipping the core game. Park for post-launch. |
| NG4 | **Full song lyrics** | Licensing risk. We'll use short phrases and hooks only (fair use), not extended excerpts. |
| NG5 | **User-generated content / custom quotes** | Scope creep. Ship the curated library first, evaluate demand later. |
| NG6 | **Non-English language support** | iOS Speech framework is locked to `en-US` in our codebase already. Internationalization is a cross-app concern, not this game's responsibility. |
| NG7 | **iCloud sync of best scores** | SwiftData local persistence is enough for MVP. Revisit if users ask. |
| NG8 | **A "Misquoted" mode** (Mandela-effect content, e.g., "Luke, I am your father" is actually "No, I am your father") | Explored in brainstorm as a separate game direction; it's a different enough mechanic that it should be its own game, not a mode in this one. Parked — see §9. |

---

## 3. Target Users & Jobs-to-be-Done

### Primary personas

**Road-tripper Rachel** — taking a 4-hour drive with her partner and two kids. Wants something to break up the monotony without forcing the driver to look at a screen. Has tried License Plate Game; wants something more active.

**Host Hiro** — having friends over for dinner. Wants an icebreaker that doesn't require a setup explanation. Has played Heads Up!; looking for something with more of a "wait, I KNOW this one" feeling.

**Solo-commute Sam** — has a 30-minute train ride each day. Plays games alone during commute. Wants something that feels satisfying solo but shareable at parties later.

### Jobs to be Done

1. **When I'm on a long drive with the people I care about, I want a game that keeps everyone engaged verbally, so we can share laughs without distracting the driver or isolating anyone behind a screen.**

2. **When I'm hosting friends, I want a quick, inclusive party game that doesn't require explaining rules or setting up equipment, so we can generate laughs in under two minutes.**

3. **When I'm playing with a mix of ages (kids, parents, grandparents), I want content that gives each generation a chance to shine, so no one feels left out or quizzed on content they don't know.**

4. **When I'm alone on a commute, I want a quick solo game that tests my recall, so I can feel clever and maybe pull it out at a party later.**

---

## 4. Gameplay Design — Spotlight Mode

### Core loop (one round)

```
1. Player picks up phone from menu
2. Selects categories, decades, difficulty → taps "Start"
3. (First run only) Grants mic + speech permissions
4. Countdown: "Get ready..." → 3 → 2 → 1 → GO
5. LOOP (60 seconds):
   a. Quote card shows setup with blank: "May the force be ___ you"
   b. Player speaks aloud: "with"
   c. Speech manager matches → ✓ celebrate → next quote (0.4s transition)
      OR player taps Skip → next quote (no celebration, small score penalty)
   d. Timer ticks down
6. Time's up → Results screen
7. "Play Again" (same player) or "Pass Phone" (reset for next player)
```

### Round mechanics

**Duration:** 60 seconds per round (tuneable during playtesting; may settle at 45–90s).

**Scoring:**
- **+100 points** per correct answer
- **+25 streak bonus** per consecutive correct (resets on skip or wrong)
- **–25 points** per skip (soft penalty, not punishing — we want players to skip when stuck)
- **Difficulty multiplier** applied to entire round:
  - Easy: 1.0×
  - Medium: 1.5×
  - Hard: 2.0×

**Quote presentation:**
- Setup text displayed large in a quote card (uses `.gameCard()` modifier).
- The blank is rendered as a styled underline or placeholder: `___` or a pill-shaped gap.
- Source attribution appears **after** correct answer, not before (no hints).
- Optional category tag shown subtly at top of card.

**Speech recognition behavior:**
- Continuous listening throughout the round (no tap-to-talk).
- Fuzzy matching via duplicated `FinishTheLineSpeechRecognitionManager` (see §6).
- On match: immediate positive feedback (haptic + visual flash + sound optional), quote card transitions to next.
- On ambient speech that doesn't match: silently ignored (no "wrong!" feedback for non-answers).

**Skip behavior:**
- Skip button in bottom-right of play screen, clearly visible but not dominant.
- Tapping skip: small –25 point penalty, quote card slides out, next quote loads.
- Skipped quotes are **not** reintroduced later in the same round (keeps the queue moving forward).
- Tracked in results ("You skipped 3 quotes").

**End-of-round:**
- Time expires → results screen with breakdown:
  - Final score (large, animated counter — use `AnimatedScoreText`)
  - Correct count, skip count, best streak
  - Difficulty multiplier shown
  - Personal best comparison (from SwiftData)
  - List of quotes played, with correct/skipped markers
  - CTAs: "Play Again" (restarts with same settings) and "Pass Phone" (returns to menu, resets state)

### Difficulty levels

| Level | Content profile | Target audience |
|---|---|---|
| **Easy** | Culturally omnipresent quotes — Star Wars, Disney, nursery rhymes, ubiquitous slogans | Kids, casual players, warm-up rounds |
| **Medium** | Well-known but requires recall — mid-tier movie quotes, TV catchphrases, well-known ads | Most adult players, default selection |
| **Hard** | Cult classics, literary quotes, deep cuts, older media | Media buffs, competitive players |

Difficulty controls **which quote pool** is drawn from — not separate timers or scoring structures (beyond the multiplier).

### Category filtering

Players can toggle specific content categories on/off. All on by default. If all categories off → start button disabled with tooltip "Select at least one category."

### Decade filtering

Same UX pattern as categories. "Timeless" decade is always on by default (it covers universally recognizable content like "Just do it" that doesn't anchor to a specific era).

---

## 5. Content Curation Strategy

This is the creative heart of the game. The content library is the product. A technically perfect game with boring quotes is a dead game.

### Design principles

1. **"At least one person in the room will shout this."** Every quote must be recognizable to *somebody* — but not *everybody*. The magic is in the mismatch: one kid shouts the Bluey line while the grandparents look confused, then a grandparent nails a Casablanca quote the kid has never heard. Rounds become intergenerational theater.

2. **Short-phrase fair use.** Quotes are short enough to qualify as fair use under US copyright. No full song lyrics, no extended movie excerpts, no paragraph-long book openings. Hooks, catchphrases, and punchlines only.

3. **PG-13 ceiling.** No profanity, no sexual content, no violence-glorifying quotes. This is a family road-trip app. When in doubt, cut.

4. **Distinctly recognizable.** "It was the best of times" → everyone knows where this is going. "Nobody expects the Spanish Inquisition" → fans of Python will explode, but enough others will recognize it.

5. **Speakable.** Every completion must be 1–4 words that can be clearly spoken and recognized by the Speech framework. "___" is the wrong format if the answer is a 15-word paragraph.

### Categories (7 total)

| Category | Description | Example |
|---|---|---|
| **Silver Screen** | Iconic movie quotes across eras and genres | "I'll be ___" → *back* (Terminator) |
| **Small Screen** | TV catchphrases, sitcom lines, reality show moments | "How you ___?" → *doin'* (Friends) |
| **Animated** | Disney, Pixar, classic cartoons, kids' shows | "To infinity and ___!" → *beyond* (Toy Story) |
| **Songs & Jingles** | Short licensing-safe hooks, commercial jingles | "I'm ___ it" → *lovin'* (McDonald's) |
| **Pitch Perfect** | Commercial slogans and taglines | "Just do ___" → *it* (Nike) |
| **Storytime** | Famous book openings, literary lines | "Call me ___" → *Ishmael* (Moby Dick) |
| **Play Time** | Video game quotes | "It's dangerous to go ___" → *alone* (Zelda) |

### Decades

`70s`, `80s`, `90s`, `2000s`, `2010s`, `2020s`, `Timeless`

"Timeless" is the escape hatch for content that doesn't cleanly anchor to an era — e.g., "Just do it" (Nike, 1988 but feels omnipresent), "Call me Ishmael" (1851 but eternally recognized).

### MVP library target: 200 quotes

Proposed distribution (guidelines, not rigid):

| Category | Quote count | Notes |
|---|---|---|
| Silver Screen | 60 | Largest bucket — most culturally dense |
| Small Screen | 40 | Spans sitcoms, dramas, reality |
| Animated | 30 | Disney, Pixar, classic cartoons — high kid appeal |
| Pitch Perfect | 25 | Slogans age well, high recognition |
| Songs & Jingles | 20 | Short hooks only — watch licensing |
| Storytime | 15 | Skew educational, rewarding for readers |
| Play Time | 10 | Gaming culture niche but beloved |
| **Total** | **200** | |

### Difficulty distribution per category

Roughly **50% Easy / 35% Medium / 15% Hard**. Easy is the default experience. Hard is a reward for enthusiasts. Skewing easier keeps early plays feeling satisfying.

### Decade distribution

Favor the "sweet spot" of 80s–2010s (peak cultural-recall density). Suggested weighting:

| Decade | Approx % of library |
|---|---|
| 70s | 10% |
| 80s | 18% |
| 90s | 22% |
| 2000s | 20% |
| 2010s | 15% |
| 2020s | 5% |
| Timeless | 10% |

2020s deliberately low — content is still settling and we don't want to bet on quotes that haven't proven durable yet.

### Sample content (seed list for Phase 2)

```
Silver Screen — Easy:
  "May the force be ___ you"        → "with"         (Star Wars, 1977)
  "Life is like a box of ___"       → "chocolates"   (Forrest Gump, 1994)
  "I'll be ___"                     → "back"         (Terminator, 1984)
  "Hasta la vista, ___"             → "baby"         (T2, 1991)
  "Here's Johnny"                   → "Johnny"       (The Shining, 1980)  [middle blank]
  "Show me the ___!"                → "money"        (Jerry Maguire, 1996)

Silver Screen — Medium:
  "You can't handle the ___!"       → "truth"        (A Few Good Men, 1992)
  "Here's looking at you, ___"      → "kid"          (Casablanca, 1942)
  "Nobody puts Baby in a ___"       → "corner"       (Dirty Dancing, 1987)
  "I see dead ___"                  → "people"       (The Sixth Sense, 1999)

Silver Screen — Hard:
  "Rosebud"                         → "Rosebud"      (Citizen Kane, 1941)
  "My precious"                     → "precious"     (LOTR, 2001)

Small Screen — Easy:
  "How you ___?"                    → "doin'"        (Friends, 1994)
  "Winter is ___"                   → "coming"       (Game of Thrones, 2011)
  "D'oh!"                           → "d'oh"         (The Simpsons, 1989)
  "Yabba dabba ___!"                → "doo"          (Flintstones, 1960)

Animated — Easy:
  "To infinity and ___!"            → "beyond"       (Toy Story, 1995)
  "Just keep ___"                   → "swimming"     (Finding Nemo, 2003)
  "Hakuna ___"                      → "matata"       (Lion King, 1994)
  "Let it ___"                      → "go"           (Frozen, 2013)

Pitch Perfect:
  "Just do ___"                     → "it"           (Nike, Timeless)
  "I'm ___ it"                      → "lovin'"       (McDonald's, 2003)
  "Got ___?"                        → "milk"         (Got Milk, 1993)
  "Because you're worth ___"        → "it"           (L'Oréal, Timeless)

Storytime:
  "Call me ___"                     → "Ishmael"      (Moby Dick)
  "It was the best of times, it was the worst of ___"  → "times"   (Tale of Two Cities)
  "It is a truth universally ___"   → "acknowledged" (Pride & Prejudice)

Play Time:
  "It's dangerous to go ___"        → "alone"        (Zelda, 1986)
  "The cake is a ___"               → "lie"          (Portal, 2007)
  "Finish ___"                      → "him"          (Mortal Kombat, 1992)
  "Thank you, Mario! But our princess is in another ___"  → "castle" (Mario, 1985)
```

### Content curation workflow

During Phase 2 (§10), we'll build the library iteratively:

1. **Draft** — enumerate candidate quotes per category/decade bucket, aiming for 2× target count to cull from.
2. **Validate speakability** — every completion must pass a "say it out loud" test. Reject quotes where the answer is mumbly, homophone-y, or unclear.
3. **Alternates pass** — for each quote, list common misspoken variants that should still count. Example: "may the force be with ya" should match "with you". This is critical for fuzzy matching accuracy.
4. **Licensing review** — any song lyric longer than ~5 words is cut. Any branded slogan we're unsure about is cut.
5. **Playtest** — run 10 rounds end-to-end with the draft library, note which quotes frustrate vs delight.
6. **Distribution rebalance** — ensure category/decade/difficulty targets are met.

### Content data format

Quotes are bundled as Swift literals in `Features/FinishTheLine/Data/FinishTheLineQuoteData.swift`. Not JSON — Swift literals give compile-time type safety and match the pattern used by `BorderHopCountryData.swift`. Example:

```swift
Quote(
    id: "sw-1977-force",
    setup: "May the force be ___ you",
    fullLine: "May the force be with you",
    missingWord: "with",
    alternates: ["with ya", "with u"],
    source: "Star Wars: A New Hope",
    category: .silverScreen,
    decade: .seventies,
    difficulty: .easy,
    blankPosition: .middle
)
```

---

## 6. Technical Architecture

### File structure

```
GamesWithFriends/Features/FinishTheLine/
├── FinishTheLineGame.swift                          # GameDefinition conformance
├── Models/
│   ├── Quote.swift                                  # Core data model
│   ├── QuoteCategory.swift                          # Enum with display names
│   ├── QuoteDecade.swift                            # Enum with display names
│   ├── QuoteDifficulty.swift                        # Enum with multipliers
│   ├── BlankPosition.swift                          # Enum: .start, .middle, .end
│   ├── FinishTheLineRoundResult.swift               # Session outcome (SwiftData @Model)
│   └── FinishTheLineGameSession.swift               # In-memory round state
├── ViewModels/
│   └── FinishTheLineViewModel.swift                 # @Observable state machine
├── Services/
│   └── FinishTheLineSpeechRecognitionManager.swift  # DUPLICATED from Border Blitz
├── Views/
│   ├── FinishTheLineMenuView.swift                  # Category/decade/difficulty selection
│   ├── FinishTheLinePermissionView.swift            # First-run mic/speech permission request
│   ├── FinishTheLineCountdownView.swift             # "3...2...1...GO"
│   ├── FinishTheLineGameView.swift                  # Active play screen
│   ├── FinishTheLineResultsView.swift               # End-of-round summary
│   └── Components/
│       ├── QuoteCardView.swift                      # The quote display component
│       ├── SpotlightTimerView.swift                 # 60s timer with color states
│       └── StreakBadge.swift                        # Streak indicator (reusable pattern from BorderHop)
└── Data/
    └── FinishTheLineQuoteData.swift                 # Bundled content library
```

### Data models

```swift
// Quote.swift
struct Quote: Identifiable, Hashable {
    let id: String
    let setup: String              // "May the force be ___ you"
    let fullLine: String           // "May the force be with you"
    let missingWord: String        // "with"
    let alternates: [String]       // ["with ya", "with u"]
    let source: String             // "Star Wars: A New Hope"
    let category: QuoteCategory
    let decade: QuoteDecade
    let difficulty: QuoteDifficulty
    let blankPosition: BlankPosition
}

// QuoteCategory.swift
enum QuoteCategory: String, CaseIterable, Identifiable {
    case silverScreen
    case smallScreen
    case animated
    case songsAndJingles
    case pitchPerfect
    case storytime
    case playTime

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .silverScreen: return "Silver Screen"
        case .smallScreen: return "Small Screen"
        case .animated: return "Animated"
        case .songsAndJingles: return "Songs & Jingles"
        case .pitchPerfect: return "Pitch Perfect"
        case .storytime: return "Storytime"
        case .playTime: return "Play Time"
        }
    }
    var iconName: String { /* SF Symbol per category */ }
}

// QuoteDecade.swift
enum QuoteDecade: String, CaseIterable, Identifiable {
    case seventies, eighties, nineties, twoThousands, twentyTens, twentyTwenties, timeless
    // Display: "70s", "80s", "90s", "2000s", "2010s", "2020s", "Timeless"
}

// QuoteDifficulty.swift
enum QuoteDifficulty: String, CaseIterable {
    case easy, medium, hard

    var multiplier: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        }
    }
    var displayName: String { rawValue.capitalized }
}

// BlankPosition.swift
enum BlankPosition {
    case start    // "___ I am your father"
    case middle   // "May the force ___ with you"
    case end      // "May the force be with ___"
}

// FinishTheLineRoundResult.swift (SwiftData)
@Model
final class FinishTheLineRoundResult {
    var id: UUID
    var date: Date
    var score: Int
    var correctCount: Int
    var skipCount: Int
    var bestStreak: Int
    var difficultyRaw: String
    var selectedCategoriesRaw: [String]
    var selectedDecadesRaw: [String]

    init(score: Int, correctCount: Int, skipCount: Int, bestStreak: Int,
         difficulty: QuoteDifficulty, categories: Set<QuoteCategory>, decades: Set<QuoteDecade>) {
        self.id = UUID()
        self.date = Date()
        self.score = score
        self.correctCount = correctCount
        self.skipCount = skipCount
        self.bestStreak = bestStreak
        self.difficultyRaw = difficulty.rawValue
        self.selectedCategoriesRaw = categories.map { $0.rawValue }
        self.selectedDecadesRaw = decades.map { $0.rawValue }
    }
}
```

**Important:** Register `FinishTheLineRoundResult.self` in the `ModelContainer` in `GamesWithFriendsApp.swift`. This is a required step — without it, SwiftData will crash at first write.

### ViewModel sketch

```swift
@MainActor
@Observable
final class FinishTheLineViewModel {
    enum Phase {
        case menu
        case permissions
        case countdown
        case playing
        case results
    }

    // Phase state
    var phase: Phase = .menu

    // Menu selections
    var selectedCategories: Set<QuoteCategory> = Set(QuoteCategory.allCases)
    var selectedDecades: Set<QuoteDecade> = Set(QuoteDecade.allCases)
    var difficulty: QuoteDifficulty = .medium

    // Round state
    private(set) var currentQuote: Quote?
    private(set) var quoteQueue: [Quote] = []
    private(set) var timeRemaining: TimeInterval = 60
    private(set) var score: Int = 0
    private(set) var currentStreak: Int = 0
    private(set) var bestStreak: Int = 0
    private(set) var correctQuotes: [Quote] = []
    private(set) var skippedQuotes: [Quote] = []

    // Infrastructure
    private var speechManager: FinishTheLineSpeechRecognitionManager?
    private var timer: Timer?
    private let modelContext: ModelContext

    // Public API
    func startGame() { /* transition menu → countdown → playing */ }
    func skipCurrentQuote() { /* penalty, next quote */ }
    func quitGame() { /* tear down, back to menu */ }
    func pauseGame() { /* scene phase handler */ }
    func resumeGame() { /* scene phase handler */ }
    func playAgain() { /* reset state, startGame */ }
    func passPhone() { /* reset to menu */ }
}
```

### Speech recognition: duplication plan

**Decision: DUPLICATE, don't extract.** Rationale:

- Border Blitz is shipped and working. Extracting its speech manager means touching Border Blitz's code path, which introduces regression risk on a stable feature.
- The duplicated file will be ~200–300 lines — not enormous.
- Once Finish the Line is shipped and stable, we can consolidate both into `Core/Services/SpeechRecognitionManager.swift` with confidence, validated by two real consumers.

**Execution steps:**

1. Copy `Features/BorderBlitz/Services/BorderBlitzSpeechRecognitionManager.swift` verbatim.
2. Save as `Features/FinishTheLine/Services/FinishTheLineSpeechRecognitionManager.swift`.
3. Rename class `BorderBlitzSpeechRecognitionManager` → `FinishTheLineSpeechRecognitionManager`.
4. Replace the country-specific match closure with a generic `(String) -> Bool` callback that the ViewModel provides. The ViewModel's callback will check the transcription against the current quote's `missingWord` and `alternates` using the same normalization/sliding-window logic the existing code already has.
5. Add a TODO comment at the top of BOTH files:
   ```swift
   // TODO: CONSOLIDATION — This manager is duplicated in both BorderBlitz and FinishTheLine.
   // After FinishTheLine ships and stabilizes, extract the common logic to
   // Core/Services/SpeechRecognitionManager.swift with a generic match callback.
   // See FinishTheLine_PRD.md §6.
   ```
6. Update `DECISIONS.md` with an entry noting: "Duplicated Border Blitz speech manager rather than extracting, to protect shipped feature. Consolidation planned post-launch."

**What to preserve from the original:**
- `SFSpeechRecognizer` setup with on-device preference
- `shouldReportPartialResults = true` for low-latency matching
- Multi-pass sliding window normalized matching (exactly what we need for multi-word phrases)
- Auto-restart on silence/timeout errors (codes 1110, 301)
- Audio level monitoring (powers the waveform in `SpotlightTimerView`)
- Permission request flow

**What to change:**
- The match callback is injected rather than hardcoded to country matching.
- The matching should be called with the transcription and should internally compare against the current quote's missing word + alternates.

### GameDefinition conformance

```swift
// FinishTheLineGame.swift
struct FinishTheLineGame: GameDefinition {
    let id = "finishTheLine"
    let name = "Finish the Line"
    let description = "Race the clock to speak the missing word from iconic quotes."
    let iconName = "quote.bubble.fill"  // or similar SF Symbol
    var accentColor: Color { GameTheme.finishTheLine.accent }

    func makeRootView() -> AnyView {
        AnyView(FinishTheLineMenuView())
    }
}
```

### Registration — critical step

Add to `Features/GameHub/GameRegistry.swift`:

```swift
static func allGames() -> [AnyGameDefinition] {
    [
        // ... existing games
        AnyGameDefinition(FinishTheLineGame()),
    ]
}
```

**Without this step, the game will not appear in the hub.** This is the single most common forgotten step when adding a new game.

### Theme entry

Add to `Theme/GameTheme.swift`:

```swift
extension GameTheme {
    static let finishTheLine = GameTheme(
        accent: Color(hex: "#C4654E"),    // Terracotta — warm, performative
        secondary: Color(hex: "#F4E4D6"), // Soft cream complement
        name: "Finish the Line"
    )
}
```

Terracotta is proposed because it's warm, evocative of stage/spotlight, and not yet used by any other game in the hub. Validate against the other 9 game themes for distinctness before committing.

---

## 7. UX Flow

### Screen inventory

| # | Screen | Purpose | Entry | Exit |
|---|---|---|---|---|
| 1 | **Menu** | Select categories, decades, difficulty | From Game Hub | → Countdown (or Permissions on first run) |
| 2 | **Permissions** | Request mic + speech permission | First-run only | → Countdown on grant; → Menu on deny |
| 3 | **Countdown** | Build tension, "get ready" | From Menu | → Play (after 3s) |
| 4 | **Play** | Active round | From Countdown | → Results (on timer expiry or quit) |
| 5 | **Results** | Score summary, next action | From Play | → Menu (Pass Phone) or → Countdown (Play Again) |

### Screen 1: Menu

**Layout (top to bottom):**
- Nav bar with back button (to Game Hub) and game title
- Hero icon (large, accent-colored SF Symbol in circle)
- Short tagline: "Speak the missing word. Beat the clock."
- **Difficulty segmented picker** — Easy / Medium / Hard
- **Category section** — 7 togglable pills (use `CategoryPill` from shared components)
- **Decade section** — 7 togglable pills
- **Start button** (primary, full-width, bottom) — disabled with inline helper text if no categories selected
- **Best score** — small secondary text showing personal best from SwiftData

**Interactions:**
- Tapping a category/decade pill toggles it (with haptic `.selection`).
- Difficulty changes trigger no state change beyond the picker.
- Start button tap → check permissions → transition to countdown or permission screen.

### Screen 2: Permissions (first run only)

Reuse the permission pattern from `BorderBlitzMenuView`. Two states:
- `.notDetermined` — show "Enable Microphone" primary button with explanatory copy
- `.denied` — show "Open Settings" button with apologetic copy

### Screen 3: Countdown

Full-screen overlay. Large number counter: **3 → 2 → 1 → GO!** with spring transitions. Haptic tick on each number. Background gets progressively warmer. Locks to the game theme accent color.

### Screen 4: Play

**Layout (top to bottom):**
- Top HUD bar:
  - Close button (top-left) → confirmation dialog before quitting
  - Timer (center) — large, color-coded (white > 30s, warning > 10s, error < 10s)
  - Score (top-right)
- Streak badge (if streak > 0) — floating below HUD, uses flame icon
- **Quote card** (center, dominant) — uses `.gameCard()` modifier
  - Setup text with blank styled distinctly
  - Category tag subtle at top
  - Source attribution hidden until correct
- Waveform visualization at bottom — audio level monitoring from speech manager
- **Skip button** (bottom-right, secondary style)

**Interactions:**
- Continuous speech recognition is active throughout.
- On correct match: card flashes accent color, haptic `.success`, quote transitions out with slide animation, next quote slides in.
- On skip: card fades, no positive feedback, next quote appears.
- On timer expiry: transition to Results screen with fade.
- On close button: confirmation dialog "End round? Your progress will be lost." → confirm → Menu.

### Screen 5: Results

**Layout:**
- Hero score (animated counter from 0 → final score using `AnimatedScoreText`)
- Stats grid (2×2):
  - Correct count
  - Skip count
  - Best streak
  - Difficulty multiplier
- Personal best comparison row ("+120 from best" or "New best!")
- Collapsible "Quotes Played" list — each row shows the quote, correct/skipped indicator, source
- Action buttons (bottom):
  - **Play Again** (primary) — restarts with same settings
  - **Pass Phone** (secondary) — returns to menu

---

## 8. Risks & Open Questions

### Risks

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R1 | Speech recognition fails in noisy environments (car, party) | High | Already proven viable in Border Blitz. Playtest in real cars before declaring done. Consider adding a "listening..." visual confirmation so players know the mic is picking them up. |
| R2 | Content library curation takes longer than expected | Medium | Start Phase 2 in parallel with Phase 1 if possible. Target 200 quotes but ship with 150 if needed — below that, the game feels thin. |
| R3 | Cultural content ages poorly (especially 2020s quotes) | Medium | Deliberately under-weight 2020s (5%). Budget for a content refresh in v1.1 post-launch. |
| R4 | On-device speech recognition unavailable on older iPhones | Low | The Speech framework falls back to network-based recognition automatically. Document this limitation but don't block on it. |
| R5 | Speech manager duplication creates divergent bug paths | Medium | Add the consolidation TODO comment in both files. Track as a tech debt item in `DECISIONS.md`. Plan consolidation in a post-launch cleanup sprint. |
| R6 | Licensing concerns around song lyrics or branded slogans | Low-Medium | Hard cap at ~5 words for lyrics. Commercial slogans are generally safe as trivia references. If legally uncertain, cut the quote. |
| R7 | The 60-second round timer is wrong (too short / too long) | Medium | Tunable constant. Playtest and iterate. Start at 60s, measure how many quotes average players complete, adjust. |

### Open questions

| # | Question | Who decides | Blocking? |
|---|---|---|---|
| Q1 | Should we include an audio "ding" when the recognizer hears a correct answer, or is haptic + visual enough? | Product / design | yes.
| Q2 | Should skipped quotes be returned to the queue later in the same round, or permanently removed? | Product | No — MVP: permanently removed, simpler and avoids "this one again?" frustration |
| Q3 | Should the player see the source attribution BEFORE or AFTER the answer? | Product | No — default to AFTER (avoids giving hints), revisit if playtests show frustration |
| Q4 | Do we need a "hint" system (reveal first letter after X seconds of silence)? | Product | No — MVP without hints; if playtests show players get stuck, add in v1.1 |
| Q5 | Should difficulty selection be a "hard gate" (locks other categories) or orthogonal (filter on top of categories)? | Product | **Resolved:** orthogonal. Difficulty filters the quote pool, categories filter the pool, decades filter the pool. All three are independent filters. |
| Q6 | How do we handle a quote where the player mouths the answer but doesn't speak audibly? | Engineering | No — the speech manager will simply not match; player can speak up or skip. No special handling needed. |
| Q7 | Should the results screen expose a "Share your score" button? | Product | **Parked** — no share mechanic in v1. Revisit when we have a daily challenge or leaderboard feature. |
| Q8 | Does the content library need to differentiate US vs. UK/international cultural references? | Product | **Resolved:** No. Ship with US-leaning content. Internationalization is its own future initiative. |

---

## 9. Out of Scope / Parked Ideas

These were considered and intentionally deferred. Documented so we don't re-derive them later.

### Parked modes

- **Group Shout mode** — everyone yells answers simultaneously; phone detects who got it first. Requires speaker ID, which iOS doesn't provide. Interesting for v2 if we solve the speaker-discrimination problem (or accept the simpler "phone is the referee, not scorekeeper" design).
- **Misquoted mode** — Mandela-effect content ("Luke, I am your father" is actually "No, I am your father"). Emerged from earlier brainstorm as a strong idea but is a *different* mechanic. Plan as a separate game, not a mode inside Finish the Line.
- **Head-to-head mode** — two players race the same quote, first correct wins. Fun but depends on speaker ID or a tap-to-claim UX. Revisit.

### Parked features

- **Daily challenge** — daily rotating quote set with global or personal streak tracking. Strong retention mechanic but orthogonal to shipping the core game.
- **Custom quote packs** — users create their own quote libraries. Scope creep for v1.
- **iCloud sync of best scores** — nice-to-have, SwiftData local persistence is enough for MVP.
- **Share-your-score screenshots** — no social mechanic in v1.
- **Quote audio playback** — actually playing the movie/TV clip after a correct answer. Cool but adds massive asset weight and licensing complexity.
- **Multiplayer leaderboard** — cross-device rankings. Requires backend, violates offline-first mandate.
- **Non-English content** — locked to `en-US` by the Speech framework in this codebase.

### Parked content directions

- **Song lyric hooks beyond 5 words** — licensing gray zone, cut for safety.
- **Politically charged quotes** — too polarizing for a family party app.
- **Explicit/R-rated content** — violates PG-13 ceiling.

---

## 10. Implementation Phases

Four phases. Each phase should be commit-able and testable on its own.

### Phase 0: Speech Manager Foundation

**Goal:** Get a working `FinishTheLineSpeechRecognitionManager` in place that's decoupled from Border Blitz.

**Tasks:**
- [ ] Create folder structure `Features/FinishTheLine/` with `Services/` subfolder
- [ ] Copy `BorderBlitzSpeechRecognitionManager.swift` → `FinishTheLineSpeechRecognitionManager.swift`
- [ ] Rename class, update file header comments
- [ ] Replace country-specific match logic with a generic `(String) -> Bool` callback injected at init
- [ ] Add the consolidation TODO comment to both files
- [ ] Build and verify compilation (no runtime integration yet)
- [ ] Update `DECISIONS.md` with the duplication decision

**Done when:** Both managers compile, Border Blitz still works, Finish the Line manager exists but is not wired to a UI yet.

**No user-facing changes in this phase.**

### Phase 1: Core Game Loop (Thin Slice)

**Goal:** A playable end-to-end game with **10 hardcoded quotes** and minimal polish, proving the loop works.

**Tasks:**
- [ ] Create `Quote` model + supporting enums (`QuoteCategory`, `QuoteDecade`, `QuoteDifficulty`, `BlankPosition`)
- [ ] Create a **seed library of 10 quotes** hardcoded in `FinishTheLineQuoteData.swift` — enough to test the loop
- [ ] Create `FinishTheLineViewModel` with phase state machine
- [ ] Create minimal `FinishTheLineMenuView` — skip filters, just a "Start" button
- [ ] Create `FinishTheLineCountdownView` with 3-2-1 transition
- [ ] Create `FinishTheLineGameView` with bare quote card + timer + skip button
- [ ] Create `FinishTheLineResultsView` with simple score display
- [ ] Wire the speech manager to the ViewModel with the match callback
- [ ] Create `FinishTheLineGame` conforming to `GameDefinition`
- [ ] **Register in `GameRegistry.allGames()`** (critical step, often forgotten)
- [ ] Add `FinishTheLineRoundResult` to the `ModelContainer` in `GamesWithFriendsApp.swift`
- [ ] First-run permission flow (reuse Border Blitz pattern)
- [ ] End-to-end test: hub → menu → countdown → play (complete 3 quotes) → results → back to menu

**Done when:** You can launch the app, tap Finish the Line from the hub, play a 60-second round with 10 test quotes, see a score at the end, and return to the menu.

**Known deferred:** Filters, theme polish, animations, full content library, streak scoring.

### Phase 2: Content Library

**Goal:** Build out the 200-quote content library and add category/decade/difficulty filters.

**Tasks:**
- [ ] Draft 400 candidate quotes (2× target) across the 7 categories following the distribution in §5
- [ ] Validate speakability — read each completion aloud, reject unclear answers
- [ ] Alternates pass — list common misspoken variants for each quote
- [ ] Licensing pass — cut anything over the ~5-word threshold for lyrics, anything legally uncertain
- [ ] Cull to 200 quotes, rebalance distribution to match targets
- [ ] Build `FinishTheLineQuoteData.swift` with all 200 entries as Swift literals
- [ ] Implement filtering logic in ViewModel: intersect selected categories × selected decades × selected difficulty
- [ ] Add category filter UI to menu screen (use `CategoryPill`)
- [ ] Add decade filter UI to menu screen
- [ ] Add difficulty picker (segmented control) to menu screen
- [ ] Disable Start button when filter intersection produces zero quotes; show inline message
- [ ] Playtest: 10 rounds end-to-end with full library, note frustrating quotes, iterate

**Done when:** Menu screen has working filters, library has 200 curated quotes, playtesting validates quality.

### Phase 3: Polish

**Goal:** Make it feel like a first-class Games with Friends title.

**Tasks:**
- [ ] Add `finishTheLine` entry to `GameTheme.swift` — pick and lock the accent color
- [ ] Theme pass: replace any placeholder colors with `GameTheme.finishTheLine.*`
- [ ] Theme pass: replace any raw spacing with `AppTheme.Spacing.*`
- [ ] Theme pass: replace any raw fonts with `AppTheme.Typography.*`
- [ ] Haptic feedback: `.success` on correct, `.selection` on skip, `.warning` at 10 seconds left
- [ ] Quote card transitions: spring animations in/out
- [ ] Streak badge with flame icon and subtle scale/glow animation
- [ ] `AnimatedScoreText` on results screen
- [ ] Waveform visualization on play screen (audio level from speech manager)
- [ ] Skip button with haptic and animation
- [ ] Personal best comparison on results screen (query SwiftData)
- [ ] Results screen quote list with correct/skip markers and source attribution
- [ ] Loading/skeleton state if the round is assembling a queue
- [ ] Empty state when all categories toggled off
- [ ] Scene phase handling: pause timer when app backgrounds, resume on foreground
- [ ] Accessibility pass: `accessibilityReduceMotion` respect, sensible voice-over labels, Dynamic Type scaling
- [ ] Confirmation dialog for mid-round quit

**Done when:** The game feels cohesive with the rest of the hub. Running it side-by-side with Border Blitz and BorderHop, it shouldn't stand out as unpolished.

---

## Summary

**Finish the Line** takes the single best mechanic on Sporcle (quote completion) and reimagines it as a voice-first party game that plays hands-free in cars and at dinner parties. It rides on existing speech recognition infrastructure (carefully duplicated, not extracted, to protect Border Blitz), and leans on a creatively curated content library spanning 7 categories and 6 decades — the real product differentiator.

The MVP scope is intentionally tight: one mode (Spotlight), one speech pattern (continuous listen, fuzzy match), one outcome format (60-second timed round). Everything else — Group Shout, Misquoted variant, daily challenges, share mechanics — is parked.

Success looks like: **a round of Finish the Line generates at least one "wait, I KNEW that!" moment per player per round**, and players ask for it by name on the next road trip.
