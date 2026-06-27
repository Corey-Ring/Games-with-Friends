# Finish the Line — Fun Upgrades Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land the approved fun-upgrade slate for Finish the Line: Reveal Beat, synthesized sound, On Fire streaks with time-back, free skips with groan reveal, mic trust pack, Encore double points, score-to-beat gauntlet, live per-answer scoring — plus the full quote-library audit.

**Architecture:** All changes stay inside `Features/FinishTheLine/` plus one `DECISIONS.md` entry. The ViewModel gains a per-card *resolution beat* state machine (`cardResolution: .correct/.skipped` held for ~0.8s before advancing) that drives the blank-fill reveal in `QuoteCardView`. Sound is synthesized at runtime via `AVAudioEngine` PCM buffers (no asset files, no licensing, offline). The SwiftData `@Model` schema and `Quote` struct shape are untouched.

**Tech Stack:** SwiftUI, @Observable, AVFoundation (AVAudioEngine synthesis), Speech (existing). No new dependencies. No test target exists (per AGENTS.md §6.2 — do not fabricate one); verification is `xcodebuild` + preview compilation.

---

### Task 1: Quote library audit (`Data/FinishTheLineQuoteData.swift`)

**Files:** Modify `Features/FinishTheLine/Data/FinishTheLineQuoteData.swift`

- [ ] Cut/replace fabricated, broken, and rule-violating entries (18 edits, same category, 1:1 so the library stays at 200):
  - `so-2002-orange` (profanity) → SNL "Live from New York, it's Saturday ___!" → *Night* (smallScreen, timeless, easy)
  - `pk-2000-tiger` → "Houston, we have a ___" → *problem* (Apollo 13, nineties, easy)
  - `rm-1988-dead` → "Ohana means ___" → *family* (Lilo & Stitch, twoThousands, easy)
  - `ml-2020-home` → "We don't talk about ___" → *Bruno* (Encanto, twentyTwenties, easy)
  - `bl-2018-family` → "For real ___?" → *life* (Bluey, twentyTwenties, easy)
  - `kp-2008-destiny` → "There is no secret ___" → *ingredient* (Kung Fu Panda, twoThousands, medium)
  - `mj-1987-moon` → "Hello from the other ___" → *side* (Adele, twentyTens, easy)
  - `ab-1978-dancing` → "'Cause the haters gonna ___" → *hate* (Shake It Off, twentyTens, easy)
  - `la-2008-lady` → "Caught in a bad ___" → *romance* (Bad Romance, twentyTens, medium)
  - `ge-1861-pip` → "Green eggs and ___" → *ham* (Dr. Seuss, timeless, easy, storytime)
  - `mn-2001-boo` (no blank in setup) → "Put that thing back where it came from, or so help ___" → *me* (Monsters, Inc., twoThousands, medium)
  - `p-1989-how` → "Smelly ___, smelly ___" → *cat* (Friends, nineties, easy)
  - `sf-2005-patrick` → "Is mayonnaise an ___?" → *instrument* (SpongeBob, nineties, medium)
  - `tw-2013-horror` → "You are the weakest link. ___!" → *Goodbye* (twoThousands, easy)
  - `ss-1969-count` (answer "ah" unspeakable) → "Is that your final ___?" → *answer* (Millionaire, twoThousands, easy)
  - `sr-1996-press` → "Do a barrel ___!" → *roll* (Star Fox, nineties, medium)
  - `gg-2000-coffee` → "Say my ___" → *name* (Breaking Bad, twentyTens, medium)
  - `ms-2023-jawn` → "Hi, I'm Olaf and I like warm ___" → *hugs* (Frozen, twentyTens, easy)
- [ ] Re-blank instead of cut: `fn-1999-rule` ("…you do not ___ about Fight Club" → *talk*), `inc-2004-normal` ("When everyone's super… ___ will be" → *no one*), `bm-1993-worries` ("It means no ___ for the rest of your days" → *worries*), `eb-1985-eb` ("Tony the Tiger says they're ___!").
- [ ] Weak-easy swaps: `pcc-2006-pirate` → "Shaken, not ___" → *stirred* (Bond, timeless, easy); `ww-2017-wonder` → "Wax on, wax ___" → *off* (Karate Kid, eighties, easy); `gbf-1974-gas` → "You had me at ___" → *hello* (Jerry Maguire, nineties, medium).
- [ ] Re-tier: `st-1966-life` hard→easy; `dk-2008-clown` medium→easy; `300-2006-sparta` medium→easy; `tg-1939-damn` hard→medium; `csm-1984-woman` hard→medium; `nv-2008-phonecall` easy→medium; `pc-2003-rum` easy→medium; `bm-2006-dynamite` easy→medium; `tm-1986-maverick` easy→medium; `bb-2008-danger` easy→medium; `ai-2002-dawg` easy→medium; `off-2005-identity` easy→medium; `lb-1998-rug` easy→hard. Move entries to the matching comment block where straightforward.
- [ ] Alternates: add `"legendary"` to `hi-2005-wait`.

### Task 2: ViewModel mechanics (`ViewModels/FinishTheLineViewModel.swift`)

**Files:** Modify `Features/FinishTheLine/ViewModels/FinishTheLineViewModel.swift`

- [ ] **Resolution beat:** add `enum CardResolution { case correct, skipped }` and `private(set) var cardResolution: CardResolution?`. `registerCorrect` sets `.correct`, holds ~0.85s, then advances. `skipCurrentQuote` sets `.skipped` (groan reveal), holds ~0.95s, then advances. Both guard on `cardResolution == nil` to prevent double-resolution. Remove `showCorrectFlash`/`flashCorrect`.
- [ ] **Free skips:** delete `skipPenalty` and the score deduction; skip still resets the streak.
- [ ] **Live per-answer scoring:** replace the end-of-round multiplier with per-answer points: easy 100 / medium 150 / hard 200 (`pointsPerCorrect(for:)`), streak bonus stays +25/step, Encore (final 10s) doubles the whole award. Remove the `endRound` score multiplication.
- [ ] **On Fire:** `isOnFire == currentStreak >= 5`. Each correct while on fire adds +2s to `timeRemaining` (capped at 90s) and bumps `timeBonusCount` for view feedback. Ignition bumps `onFireIgnitionCount` (sound/visual trigger).
- [ ] **Encore:** `isEncore == phase == .playing && timeRemaining <= 10`. Timer tick fires a light haptic + tick sound on each whole-second crossing ≤ 10.
- [ ] **Hint lifeline:** `private(set) var hintRevealed = false`; per-card `Task` reveals the source after 6s if the card is still unresolved; cancelled on advance/teardown.
- [ ] **Mic trust:** track the per-card transcription baseline; match only the portion of the transcription that appeared after the card was shown (handle recognizer restarts where the transcript resets). Short single-word answers (≤4 letters) must appear in the **last 3 words** of the new portion. Expose `heardSnippet` (last few heard words). Near-miss detection: Levenshtein ≤1 (≤2 for 7+ letters) between the last heard word and any single-word candidate of 4+ letters → bump `nearMissCount` + warning haptic, throttled to one per 1.5s.
- [ ] **Gauntlet:** `private(set) var scoreToBeat: Int?`, `private(set) var hasBeatenTarget = false`. `passPhone()` records `max(scoreToBeat, finishedScore)`. Crossing the target mid-round flips `hasBeatenTarget` once (heavy haptic + fanfare).
- [ ] **Sound triggers:** `let soundPlayer = FinishTheLineSoundPlayer()`; play on correct (pitch rises with streak), skip, ignite, tick, round-end buzzer, target-beaten fanfare.

### Task 3: Sound synthesis service (new file + pbxproj)

**Files:** Create `Features/FinishTheLine/Services/FinishTheLineSoundPlayer.swift`; Modify `GamesWithFriends.xcodeproj/project.pbxproj` (4 insertions mirroring `FTL…10` IDs with new `FTL…99` IDs)

- [ ] `@MainActor final class FinishTheLineSoundPlayer`: lazy `AVAudioEngine` + `AVAudioPlayerNode`, renders short sine-with-envelope `AVAudioPCMBuffer`s on demand. Sounds: `playCorrect(streak:)` (two-note rising arpeggio, +1 semitone per streak step, capped), `playSkip()` (descending blip), `playTick()`, `playBuzzer()`, `playIgnite()` (rising sweep), `playFanfare()` (three rising notes). Modest gain (≤0.5). Engine failures degrade silently (haptics remain).
- [ ] Register the file in pbxproj: PBXBuildFile, PBXFileReference, Services group child, Sources phase entry.

### Task 4: Reveal Beat UI (`Views/Components/QuoteCardView.swift`)

- [ ] New inputs: `resolution: FinishTheLineViewModel.CardResolution?`, `showSource: Bool`, `isOnFire: Bool` (replaces `isFlashing`).
- [ ] Blank fill: when resolved, render the missing word in place of the blank — `AppTheme.success` tint for correct, `AppTheme.warning` for skipped — with a spring transition.
- [ ] Source row hidden unless `showSource` (resolved or hint), fades in.
- [ ] Border/shadow: success styling on correct, warning on skip, ember gradient (warning→brandOrange, matching StreakBadge flame) while on fire.

### Task 5: StreakBadge On Fire state (`Views/Components/StreakBadge.swift`)

- [ ] `isOnFire: Bool = false` parameter: saturated flame gradient background, white text, stronger glow, "ON FIRE" treatment.

### Task 6: Game screen (`Views/FinishTheLineGameView.swift`)

- [ ] Pass new QuoteCardView params; shake the card on `nearMissCount` change (GeometryEffect) with a transient "So close — say it again!" pip; "+2s" pip near the timer on `timeBonusCount` change; ENCORE ×2 banner while `isEncore`; score-to-beat chip (trophy → crown when beaten) beside the streak badge; `heardSnippet` caption under the waveform; update the skip button accessibility label (no penalty).

### Task 7: Results + countdown (`Views/FinishTheLineResultsView.swift`, `Views/FinishTheLineCountdownView.swift`)

- [ ] Results: secondary CTA becomes "Pass the Phone" (sets the gauntlet target via `passPhone()`); replace the stale multiplier caption with per-quote points copy.
- [ ] Countdown: show "Score to beat: N" when a gauntlet target exists.

### Task 8: Verify + document

- [ ] `xcodebuild -project GamesWithFriends.xcodeproj -scheme GamesWithFriends -destination 'generic/platform=iOS Simulator' build` → BUILD SUCCEEDED, no new warnings.
- [ ] Append a DECISIONS.md entry: per-answer difficulty points replace the end-of-round multiplier (personal bests remain comparable in magnitude but are now computed live); runtime-synthesized audio (no assets); source-as-hint reveal model; Taken quote kept at medium pending PG-13 judgment call.
