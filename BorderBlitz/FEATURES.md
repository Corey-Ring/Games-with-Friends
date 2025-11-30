# Border Blitz - Detailed Features Guide

## Gameplay Mechanics

### Letter Reveal System

The letter reveal system is the core mechanic that makes Border Blitz unique:

#### How It Works
1. **Initial State**: All letters start hidden (displayed as underscores)
2. **Progressive Reveal**: Letters appear one at a time from left to right
3. **Smart Spacing**: Spaces, hyphens, apostrophes, and periods are shown immediately
4. **Difficulty-Based Timing**: Reveal speed adjusts based on selected difficulty

#### Example Progression
For "SOUTH KOREA":
```
Start:    _____ _____
1 letter: S____ _____
2 letters: SO___ _____
3 letters: SOU__ _____
4 letters: SOUT_ _____
5 letters: SOUTH _____
6 letters: SOUTH K____
...continues until all revealed
```

### Scoring Breakdown

#### Base Points
```
Score = Hidden Letters × 100
```
- Each unrevealed letter is worth 100 points
- More hidden letters = higher score
- Encourages quick recognition

#### Time Bonus
```
Time Bonus = Base Score × 0.5 × (Time Remaining / Total Time)
```
Example:
- Base score: 800 (8 hidden letters)
- Time remaining: 30s / 60s total (50%)
- Time bonus: 800 × 0.5 × 0.5 = 200 points
- **Total: 1,000 points**

#### Streak Bonus
```
Streak Bonus = (Streak - 1) × 50
```
- Consecutive correct answers build a streak
- Each streak level adds 50 bonus points
- Resets to 0 on incorrect guess or time out

Example Streak:
- Round 1 (correct): +0 (streak = 1)
- Round 2 (correct): +50 (streak = 2)
- Round 3 (correct): +100 (streak = 3)
- Round 4 (incorrect): +0 (streak = 0)

#### Perfect Bonus
```
Perfect Bonus = +500 (if 0 letters revealed)
```
- Awarded for instant recognition
- Must guess before any letter reveals
- The ultimate achievement!

#### Complete Scoring Example

**Scenario**: Guessing "ITALY" on Hard difficulty
- Country has 5 letters
- Guessed after 1 letter revealed
- 4 letters still hidden
- 28 seconds remaining (of 35 total)
- Current streak: 3

**Calculation**:
```
Base Score:     4 × 100 = 400
Time Bonus:     400 × 0.5 × (28/35) = 160
Streak Bonus:   (3 - 1) × 50 = 100
Perfect Bonus:  0 (letter was revealed)
─────────────────────────────────
Total:          660 points
```

## Difficulty Comparison

### Easy Mode
- **Letter Speed**: 3 seconds per letter
- **Total Time**: 60 seconds
- **Best For**: Beginners, learning countries
- **Strategy**: Take your time, wait for hints

### Medium Mode (Default)
- **Letter Speed**: 2 seconds per letter
- **Total Time**: 45 seconds
- **Best For**: Casual players
- **Strategy**: Balance speed and accuracy

### Hard Mode
- **Letter Speed**: 1.5 seconds per letter
- **Total Time**: 35 seconds
- **Best For**: Geography enthusiasts
- **Strategy**: Quick recognition required

### Expert Mode
- **Letter Speed**: 1 second per letter
- **Total Time**: 25 seconds
- **Best For**: Geography masters
- **Strategy**: Instant identification or lose points fast

## UI Elements

### Timer Display
- **Green** (>20s): Plenty of time
- **Orange** (11-20s): Time running out
- **Red** (≤10s): Critical!

### Letter Tiles
- **Gray with underscore**: Hidden letter
- **Green background**: Revealed letter
- **Always visible**: Spaces and punctuation

### Feedback Messages
- **Green "Correct! 🎉"**: Correct guess
- **Red "Try again"**: Incorrect guess (doesn't end round)
- **Red "Time's up!"**: Timer expired

## Game States

### 1. Menu
- Difficulty selection
- Game description
- Start button

### 2. Playing
- Country silhouette displayed
- Timer counting down
- Letters revealing progressively
- Text input active
- Submit/Skip buttons enabled

### 3. Round Complete
- Result icon (✓ or ✗)
- Country name revealed
- Score breakdown shown
- Continue or Menu options

### 4. Game Over
- Final score display
- Statistics summary:
  - Total rounds played
  - Correct answers
  - Best streak achieved
- Return to menu

## Tips & Strategies

### Beginner Tips
1. **Start on Easy**: Get familiar with country shapes
2. **Wait for Letters**: Use revealed letters as hints
3. **Learn Patterns**: Boot shape = Italy, Island chain = Japan
4. **Use Alternates**: "UK" works for "United Kingdom"

### Advanced Strategies
1. **Memorize Silhouettes**: Recognize shapes instantly
2. **Count Letters**: Letter count can identify countries
3. **Build Streaks**: Consistency > risky speed
4. **Perfect Timing**: On Expert, aim for 0-1 letter reveals

### Scoring Optimization
1. **Speed Matters**: Faster guesses = time bonus
2. **Maintain Streaks**: Don't rush and break streak
3. **Perfect Bonuses**: +500 points worth the risk on familiar shapes
4. **Strategic Skipping**: Skip unfamiliar countries to preserve streak

## Country Recognition Guide

### Easy to Identify
- **Italy**: Distinctive boot shape
- **Japan**: Island chain, elongated
- **Norway**: Long, narrow northern country
- **United Kingdom**: Islands with distinctive shape

### Medium Difficulty
- **France**: Roughly hexagonal
- **Spain**: Square-ish with small western extension
- **Australia**: Large, relatively round landmass
- **South Korea**: Peninsula, compact shape

### Challenging
- **Germany**: Central European, irregular borders
- **Brazil**: Large South American shape
- **India**: Triangular peninsula
- **Canada**: Very large, complex northern border

### Expert Level
- **United States**: Complex shape with varied coasts
- **China**: Large Asian country, diverse borders
- **Mexico**: Recognizable but smaller details matter

## Accessibility Features

### Current Features
- Large, readable text
- High contrast colors
- Simple, clear UI
- Keyboard-first input

### Future Accessibility Enhancements
- VoiceOver support
- Dynamic type sizing
- Reduced motion option
- Color blind modes
- Haptic feedback
- Audio cues

## Performance

### Optimizations
- Efficient Shape rendering with normalized coordinates
- Timer-based letter reveals (not animation-heavy)
- Minimal memory footprint
- Smooth 60fps UI updates

### Battery Considerations
- Timers pause when app backgrounds
- No continuous animations
- Efficient state updates

## Technical Achievements

### SwiftUI Best Practices
✅ MVVM architecture
✅ Combine framework for reactive updates
✅ Clean separation of concerns
✅ Reusable components
✅ Preview support for all views

### Code Quality
✅ Type-safe enums
✅ Comprehensive documentation
✅ Extensible design
✅ No force unwraps
✅ Memory-safe (no retain cycles)

## Known Limitations

### Current Version
- 15 countries (not full 195)
- Simplified border coordinates
- Single player only
- No persistent statistics
- No sound effects

### Planned Improvements
See "Future Enhancements" in main README

## Educational Value

### Geography Skills
- Country shape recognition
- Name spelling practice
- Geographic awareness
- Spatial reasoning

### Cognitive Benefits
- Quick decision making
- Pattern recognition
- Time management
- Strategic thinking

## Community & Competition

### Challenge Ideas
- Speed runs (highest score in 10 rounds)
- Perfect streak challenges
- Expert mode mastery
- Country knowledge quiz

### Sharing Scores
Current version: Screenshot results
Future: Built-in sharing, leaderboards

---

Ready to become a Border Blitz champion? 🏆🌍
