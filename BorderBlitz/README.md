# Border Blitz - iOS Country Identification Game

Border Blitz is a SwiftUI iOS game where players identify countries based on their geographic borders and silhouettes. Race against the clock as letters reveal one by one, and score points based on how quickly you can identify each country!

## Features

### 🎮 Core Gameplay
- **Country Silhouettes**: Identify countries from their filled border shapes without labels or context
- **Progressive Letter Reveal**: Letters appear one at a time from left to right
- **Dynamic Difficulty**: Choose from 4 difficulty levels with different reveal speeds and time limits
- **Real-time Timer**: Countdown timer with color-coded warnings
- **Instant Feedback**: Visual and textual feedback on correct/incorrect guesses

### 📊 Scoring System
- **Base Points**: 100 points per unrevealed letter
- **Time Bonus**: Additional points based on remaining time (50% multiplier)
- **Streak Bonus**: 50 points per consecutive correct answer
- **Perfect Bonus**: 500 points for guessing with zero letters revealed
- **Score Breakdown**: Detailed score breakdown after each round

### 🎯 Difficulty Levels

| Difficulty | Letter Reveal Speed | Total Time | Description |
|-----------|-------------------|-----------|-------------|
| Easy | 1 letter / 3 seconds | 60 seconds | Perfect for beginners |
| Medium | 1 letter / 2 seconds | 45 seconds | Balanced challenge |
| Hard | 1 letter / 1.5 seconds | 35 seconds | For geography experts |
| Expert | 1 letter / 1 second | 25 seconds | Ultimate challenge |

### 🌍 Countries Included

The game includes 15 countries with simplified border coordinates:
- **Europe**: Italy, France, Spain, Germany, United Kingdom, Norway
- **Asia**: Japan, China, India, South Korea
- **Americas**: United States, Canada, Mexico, Brazil
- **Oceania**: Australia

Each country supports alternate names and spellings (e.g., "USA" for "United States", "UK" for "United Kingdom").

## Project Structure

```
BorderBlitz/
├── BorderBlitz/
│   ├── BorderBlitzApp.swift          # Main app entry point
│   ├── Models/
│   │   ├── Country.swift             # Country data model
│   │   ├── Difficulty.swift          # Difficulty configuration
│   │   ├── LetterTile.swift          # Letter reveal system
│   │   └── ScoringConfig.swift       # Scoring logic
│   ├── ViewModels/
│   │   └── GameViewModel.swift       # Game state management
│   ├── Views/
│   │   ├── MenuView.swift            # Main menu with difficulty selection
│   │   ├── GameView.swift            # Main game screen
│   │   ├── CountrySilhouetteView.swift  # Country border rendering
│   │   └── LetterTilesView.swift     # Letter tile display
│   ├── Data/
│   │   └── CountryDataProvider.swift # Country border coordinates
│   └── Info.plist                    # App configuration
└── README.md
```

## Technical Details

### Architecture
- **SwiftUI**: Modern declarative UI framework
- **MVVM Pattern**: Separation of concerns with ViewModels
- **Combine Framework**: Reactive state management with `@Published` and `@ObservedObject`
- **Timer-based System**: Coordinated timers for countdown and letter reveals

### Key Components

#### Letter Reveal System
```swift
class LetterRevealManager: ObservableObject {
    - Manages sequential letter reveals
    - Automatically shows spaces and special characters
    - Configurable reveal intervals
    - Tracks hidden letter count for scoring
}
```

#### Scoring Algorithm
```swift
struct ScoringConfig {
    - Base: 100 points × hidden letters
    - Time bonus: score × 50% × (time remaining / total time)
    - Streak bonus: (streak - 1) × 50 points
    - Perfect bonus: +500 points (0 letters revealed)
}
```

#### Country Border Rendering
- Uses SwiftUI `Shape` protocol for custom path drawing
- Automatic normalization and scaling to fit view
- Maintains aspect ratio
- Centered positioning

## How to Build and Run

### Requirements
- Xcode 14.0 or later
- iOS 15.0 or later
- Swift 5.7 or later

### Steps
1. Open `BorderBlitz.xcodeproj` in Xcode
2. Select a simulator or connected device
3. Press `Cmd + R` to build and run

### Building from Command Line
```bash
cd BorderBlitz
xcodebuild -scheme BorderBlitz -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Game Rules

1. **Starting a Round**:
   - A country silhouette appears
   - Letters start hidden (shown as underscores)
   - Timer begins countdown

2. **Letter Revealing**:
   - Letters reveal sequentially left to right
   - Spaces and special characters (-, ', .) are always visible
   - Reveal speed depends on selected difficulty

3. **Making a Guess**:
   - Type country name in the text field
   - Press "Submit" or hit Enter
   - Alternate spellings are accepted

4. **Round Completion**:
   - **Correct**: Score points, maintain/increase streak
   - **Incorrect**: Streak resets to 0, try again
   - **Time Out**: Round ends, answer is revealed

5. **Scoring**:
   - More hidden letters = higher score
   - Faster guesses = time bonus
   - Consecutive correct answers = streak multiplier
   - Perfect guesses (0 letters shown) = 500 bonus points

## Extending the Game

### Adding New Countries

Add countries to `CountryDataProvider.swift`:

```swift
Country(
    id: "XXX",                    // 3-letter ISO code
    name: "COUNTRY NAME",         // Display name (uppercase)
    borderPoints: countryBorder,  // Array of CGPoint
    alternateNames: ["Alt1", "Alt2"]  // Accepted spellings
)
```

### Creating Border Coordinates

Border points are simplified polygons:
- Use CGPoint(x, y) coordinates
- Scale: roughly 0-100 for both x and y
- ~10-20 points for simple shapes
- More points for complex borders
- Points should form a closed loop

### Customizing Difficulty

Modify `Difficulty.swift` to add new levels or adjust timing:

```swift
case custom = "Custom"

var letterRevealInterval: TimeInterval {
    case .custom: return 2.5
}

var totalTime: TimeInterval {
    case .custom: return 40.0
}
```

### Adjusting Scoring

Edit `ScoringConfig.swift` to change point values:

```swift
struct ScoringConfig {
    let basePointsPerLetter: Int = 100      // Points per hidden letter
    let timeBonusMultiplier: Double = 0.5   // Time bonus percentage
    let streakBonus: Int = 50               // Points per streak level
    let perfectBonus: Int = 500             // Perfect guess bonus
}
```

## Future Enhancements

Potential features to add:
- [ ] More countries (full 195 UN members)
- [ ] Multiplayer mode
- [ ] Global leaderboards
- [ ] Hints system (show neighboring countries)
- [ ] Region-based challenges (e.g., "Europe only")
- [ ] Daily challenge mode
- [ ] Achievement system
- [ ] Sound effects and music
- [ ] Dark mode support
- [ ] Accessibility improvements
- [ ] iPad-optimized layout

## Credits

Part of the **Games with Friends** collection - building shared trivia muscles with lightweight, educational games.

## License

No license specified yet. Add one if you plan to share or distribute the project.
