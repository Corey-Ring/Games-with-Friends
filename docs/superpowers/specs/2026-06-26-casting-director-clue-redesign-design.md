# Casting Director — Clue System Redesign

**Date:** 2026-06-26
**Status:** Approved design, ready for implementation plan
**Scope:** `GamesWithFriends/Features/CastingDirector/` (primarily `Services/ClueGenerator.swift`)

## Problem

The Casting Director game asks players to guess an actor from a ladder of
progressively-revealing clues. In practice the early clues carry almost no
signal and read like raw stat dumps:

- *"Appeared in 39 movies"* — applies to hundreds of actors.
- *"Most active in the 2010s"* — applies to thousands.
- *"Known for Drama" / "Also appears in Thriller films"* — describes half of Hollywood.
- *"Appeared in a 2016 Comedy film"* — no title; thousands of candidates. Worse, the
  source movie is picked via `shuffledMovies.first`, so it is often a film no one
  associates with the actor.
- *"Appeared in a film rated 6.8/10"* — a mediocre rating with no anchor; the single
  least useful clue in the game.

The round does not become genuinely playable until the co-star and movie-title clues
appear. The problem is both **signal** (early clues do not narrow the candidate pool)
and **flavor** (clues feel like stat read-outs, not casting-director hints). Both share
one root cause: clue templates emit whatever the data says, even when the fact is not
distinguishing.

## Goal

Rebuild the clue system so that **every clue both narrows the candidate pool and reads
like a hint**, while staying entirely within the existing movie database (actors,
films, genres, years, ratings, vote counts, directors, co-stars). No new data sources
(no awards, character names, box-office figures, etc.).

## Non-goals

- No changes to scoring math, the reveal timer, or the difficulty knobs themselves.
- No difficulty-specific clue *quality* shaping in this pass. Difficulty keeps its
  existing behavior: it controls pacing (`clueInterval`), penalties
  (`wrongGuessPenalty`), clue budget (`maxClues`), co-star placement
  (`showCoStarsEarly`), and title count (`movieTitleCluesCount`). Reshaping clue
  quality by difficulty is a possible future pass.
- No new database schema or queries beyond what existing `MovieChainDatabase` methods
  already expose (`getMoviesWithActor`, `getDirectorsOfMovie`, `getActorsInMovie`,
  `getActor`, `getQualifiedActorIds`).

## Core principle

Every candidate clue must pass a **distinctiveness gate** before it is allowed into the
round. A fact that is true but generic ("39 movies", "rated 6.8/10", "Drama") is
suppressed. Each clue type is a small, isolated *builder* that either returns a clue or
returns `nil` because the actor's data is not distinctive enough on that axis.

This single principle fixes both problems at once: gating removes the low-signal clues,
and the surviving clues are, by construction, distinctive enough to be worth phrasing as
real hints.

## Architecture

Today `generateClues(for:difficulty:)` is one ~165-line method that appends templates
inline ([ClueGenerator.swift](../../../GamesWithFriends/Features/CastingDirector/Services/ClueGenerator.swift)).
It is restructured into a three-stage pipeline so each clue type is independently
understandable and testable:

1. **Gather facts.** Build a single fact bundle for the actor: filmography (sorted by
   votes), per-movie directors and co-stars, and aggregates (genre frequency, decade
   distribution, career span, acclaim/blockbuster counts, collaboration counts,
   detected franchises). Most of this already exists; it is consolidated into one value
   passed to every builder.

2. **Run builders.** Each clue type is a function `(facts) -> Clue?` (or `-> [Clue]`
   for types that can emit several, like named co-stars). A builder returns `nil` when
   its distinctiveness gate fails. Builders never read global state and never mutate the
   fact bundle, so each can be unit-tested in isolation.

3. **Assemble ladder.** Collect the surviving candidates, order them by tier (vague →
   narrowing → strong → giveaway), dedupe (e.g. a director named in a "frequent
   collaborator" clue should not also appear in a plain "worked with director" clue),
   apply the difficulty knobs, and **reserve slots** for the giveaway tier so the
   movie-title clues always fit within `maxClues`.

### Reserved giveaway slots (bug fix)

Today the final `prefix(maxClues)` trim
([ClueGenerator.swift:217](../../../GamesWithFriends/Features/CastingDirector/Services/ClueGenerator.swift:217))
can cut off the movie-title clues entirely. On Hard (`maxClues = 8`), if the
vague + narrowing + strong clues exceed 8, the giveaway titles are trimmed away and the
actor becomes near-unguessable. Assembly must reserve `movieTitleCluesCount` (plus the
Hard-mode co-star, when applicable) slots for the giveaway tier *before* filling the
earlier tiers, so the ladder always reaches at least one exact title within the budget.

## Clue catalog

Removed:
- **Bare movie-count clue** (`"Appeared in N movies"`).
- **Rating-only clue** (`"Appeared in a film rated X/10"`).

Changed:
- All movie-based clues anchor on **signature (high-vote) films**, not
  `shuffledMovies.first`.
- The two broad genre lines collapse into one **genre identity** clue.

Full catalog (tier, gate, example):

| Clue type | Tier | Distinctiveness gate (emit only if…) | Example wording |
|---|---|---|---|
| Genre identity (combo) | Vague | top genre ≥ `genreIdentityShare` of credits | "Best known for sci-fi and action" |
| Era / breakout | Vague | has a clear peak decade | "Broke out in the late 2000s" |
| Longevity | Vague | career span ≥ `longevitySpanYears` | "Has been working for over three decades" |
| Prolific / selective | Vague | ≥ `prolificThreshold` credits, or ≤ `selectiveMaxCredits` with ≥3 famous | "A remarkably prolific actor" / "A selective actor with a small, acclaimed body of work" |
| Blockbuster tier | Vague | ≥ `blockbusterCount` films above `blockbusterVotes` | "Star of several blockbusters" |
| Franchise (unnamed) | Narrowing | ≥ `franchiseMinFilms` films share a title stem and are recognizable | "Has a recurring role in a major franchise" |
| Anchored film (no title) | Narrowing | film is recognizable (high votes) | "Led an acclaimed 2016 thriller" |
| Acclaim | Narrowing | ≥ `acclaimCount` films rated ≥ `acclaimRating` | "Several films rated above 8.0" |
| Frequent director | Strong | same director ≥ `frequentDirectorCount` times | "A regular in Denis Villeneuve's films" |
| Named director | Strong | anchored on signature films | "Worked with director Christopher Nolan" |
| Named co-star | Strong | qualified pool, from high-vote films | "Co-starred with Idris Elba" |
| Franchise (named) | Strong | franchise detected and recognizable | "Part of the Avengers franchise" |
| Exact title | Giveaway | signature films, most famous revealed last | "Appeared in \"Sicario (2015)\"" |

## The ladder

Vague (persona / era) → Narrowing (franchise, anchored films, acclaim) →
Strong (named directors, co-stars, franchise) → Giveaway (exact titles).

Difficulty keeps its existing knobs unchanged. In particular `showCoStarsEarly` still
moves co-stars from the strong tier down to the giveaway tier on Hard, and
`movieTitleCluesCount` still controls how many exact titles are revealed.

## Fallback safety

A subset of clue types are **always available** because their gates are trivially
satisfied for any qualified actor:

- Era / decade (every actor has a peak decade).
- Anchored signature film (every qualified actor has ≥3 high-vote films).
- Named directors.
- Named co-stars.
- Exact titles.

So an actor who triggers none of the special gates (no franchise, not especially
prolific, no acclaim cluster) still receives a complete, coherent ladder:
era → anchored film → directors → co-stars → titles. The round never breaks or comes up
short of `maxClues`.

## Tunable heuristics

These are extracted as named constants and tuned during playtesting:

| Constant | Purpose | Starting value |
|---|---|---|
| `genreIdentityShare` | min share of credits for a genre to be "identity" | 0.30 |
| `longevitySpanYears` | career span to count as long-running | 30 |
| `prolificThreshold` | credit count for "prolific" | 50 |
| `selectiveMaxCredits` | max credits for "selective" (with ≥3 famous) | 15 |
| `blockbusterVotes` | vote count for a film to be a "blockbuster" | 500,000 |
| `blockbusterCount` | blockbusters needed for the clue | 2 |
| `acclaimRating` | rating threshold for "acclaimed" | 8.0 |
| `acclaimCount` | acclaimed films needed for the clue | 3 |
| `anchoredFilmMinVotes` | votes for a film to be "recognizable" | 50,000 |
| `franchiseMinFilms` | films sharing a stem to count as a franchise | 2 |
| `frequentDirectorCount` | collaborations for "frequent director" | 3 |

### Franchise detection (heuristic, flagged)

Title-stem matching is the riskiest heuristic. Approach: normalize each title by
lowercasing, stripping a trailing subtitle (text after a colon), and stripping trailing
sequel markers (digits, roman numerals, "Part N"). Group the actor's films by
normalized stem; a group of ≥ `franchiseMinFilms` whose combined vote count clears a
recognizability bar counts as a franchise. Kept deliberately conservative to avoid
false positives (e.g. "Love Actually" vs "Love & Other Drugs" must not match). The
named-franchise clue uses the most common human-readable stem.

## Difficulty / balance note

Richer early clues make the game somewhat easier to guess early, which is acceptable and
in line with the goal. Difficulty pacing and penalties are unchanged this pass; if play
testing shows rounds resolve too quickly, the follow-up lever is the difficulty knobs
(reveal interval, penalties, `maxClues`), not the clue quality.

## Testing

- **Per-builder unit tests:** for each clue type, one case where the gate passes
  (correct wording produced) and one where it fails (`nil` returned). Use small
  synthetic fact bundles.
- **Assembly tests:** ladder ordering (vague → giveaway), dedupe (a director/co-star
  named once does not reappear in a weaker clue), and giveaway-slot reservation
  (at least one exact title present on Hard with `maxClues = 8`).
- **Fallback test:** an actor that triggers no special gates still yields a full ladder
  ending in a title.
- **End-to-end spot checks:** a few well-known actors produce plausible, distinctive
  ladders.

## Out of scope / future work

- Difficulty-specific clue quality (Easy leans on franchises/famous films; Hard leans
  on obscure collaborators).
- A pool-wide distinctiveness-ranking engine that scores every candidate clue by how
  much it narrows the field across the whole actor pool.
- Enriching the dataset (awards, character names, box office).
