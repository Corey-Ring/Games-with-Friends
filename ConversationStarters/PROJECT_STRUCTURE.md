# Conversation Starters - Project Structure

## Directory Overview

```
ConversationStarters/
│
├── ConversationStartersApp.swift         # App entry point (@main)
│
├── Models/                               # Data models
│   ├── ConversationStarter.swift        # Main data model
│   │   ├── ConversationStarter struct   # Question data
│   │   ├── Category enum                # Question categories
│   │   └── Theme enum                   # Seasonal themes
│   └── GameSettings.swift               # Game configuration
│       ├── GameSettings struct          # Settings data
│       └── TimerPreset enum             # Timer options
│
├── ViewModels/                          # Business logic
│   └── GameViewModel.swift              # Main game controller
│       ├── Game state management
│       ├── Filtering logic
│       ├── Timer management
│       └── Persistence (UserDefaults)
│
├── Views/                               # UI components
│   ├── HomeView.swift                   # Main menu screen
│   │   ├── Player selection
│   │   ├── Vibe level slider
│   │   ├── Category filters
│   │   ├── Theme filters
│   │   └── Start button
│   │
│   ├── GameView.swift                   # Main game screen
│   │   ├── Card display
│   │   ├── Swipe gestures
│   │   ├── Navigation buttons
│   │   ├── Timer display
│   │   ├── Progress indicator
│   │   └── CardView component
│   │
│   ├── SettingsView.swift               # Timer configuration
│   │   ├── Timer toggle
│   │   ├── Duration presets
│   │   └── Custom timer picker
│   │
│   └── SavedStartersView.swift          # Saved questions
│       ├── Saved list display
│       ├── Remove functionality
│       └── Share capability
│
├── Data/                                # Static data
│   └── SampleData.swift                 # Question database
│       └── 80+ conversation starters
│
├── Utilities/                           # Helper code
│   └── PreviewHelpers.swift             # SwiftUI previews
│
└── Documentation/
    ├── README.md                        # Main documentation
    ├── QUICK_START.md                   # Setup guide
    └── PROJECT_STRUCTURE.md             # This file
```

## Data Flow

```
User Input (HomeView)
    ↓
GameSettings
    ↓
GameViewModel (filters, shuffles)
    ↓
ConversationStarter array
    ↓
GameView (displays)
    ↓
CardView (renders)
```

## Key Components

### 1. Models

**ConversationStarter**
- Core data structure for questions
- Properties: id, text, vibeLevel, category, themes, minPlayers
- Conforms to: Identifiable, Codable, Equatable

**Category Enum**
- 6 types of questions
- Each has an associated SF Symbol icon
- Used for filtering and display

**Theme Enum**
- 8 seasonal/evergreen themes
- Auto-detection based on current date
- Used for filtering seasonal content

**GameSettings**
- Stores user preferences
- Player count, vibe level, selected filters
- Timer configuration

### 2. ViewModels

**GameViewModel**
- Central game logic controller
- Observable object for state management
- Responsibilities:
  - Filter questions based on settings
  - Track shown questions
  - Manage saved questions
  - Handle timer countdown
  - Persist data to UserDefaults

### 3. Views

**HomeView**
- Main entry screen
- Configuration interface
- Custom components:
  - FlowLayout: Wrapping layout for chips
  - CategoryChip: Tappable category filter
  - ThemeChip: Tappable theme filter

**GameView**
- Main gameplay interface
- Features:
  - Drag gesture for swiping
  - Navigation buttons
  - Progress display
  - Timer countdown
  - Menu for shuffle/reset

**CardView**
- Reusable card component
- Displays:
  - Question text
  - Category badge
  - Vibe level dots
  - Theme tags
  - Star button

**SettingsView**
- Timer configuration
- Form-based interface
- Presets and custom options

**SavedStartersView**
- List of starred questions
- Share and remove actions
- Empty state handling

### 4. Data Layer

**SampleData**
- Static class with question database
- 80+ pre-written questions
- Covers all vibe levels, categories, and themes
- Easily extensible

## State Management

### @StateObject
- Used in HomeView to create GameViewModel instance
- Ensures single source of truth

### @ObservedObject
- Used in child views (GameView, SettingsView, etc.)
- Receives GameViewModel from parent
- Observes changes and updates UI

### @Published Properties
```swift
@Published var settings: GameSettings
@Published var currentIndex: Int
@Published var filteredStarters: [ConversationStarter]
@Published var shownStarterIDs: Set<UUID>
@Published var savedStarterIDs: Set<UUID>
@Published var timeRemaining: TimeInterval
@Published var isTimerRunning: Bool
```

## Persistence Strategy

### UserDefaults
- Stores saved starter IDs
- Key: "SavedStarters"
- Format: Array of UUID strings
- Loads on app launch
- Saves on every star/unstar action

### Future Enhancement Options
- SwiftData for more complex persistence
- iCloud sync for cross-device access
- CoreData for advanced querying

## UI/UX Patterns

### Color Coding
- **Vibe Levels**: Blue (1) → Green (2) → Yellow (3) → Orange (4) → Red (5)
- **Categories**: Each category has unique color
- **Themes**: Consistent blue for theme chips

### Gestures
- **Horizontal swipe**: Navigate cards
- **Tap**: Buttons and selections
- **Long press**: (Future: reveal hints)

### Feedback
- Haptic feedback on timer expiration
- Visual feedback on card transitions
- Button state changes (disabled/enabled)

## Extensibility Points

### Adding New Categories
1. Add case to `Category` enum
2. Add icon mapping
3. Add color mapping in views
4. Create questions with new category

### Adding New Themes
1. Add case to `Theme` enum
2. Add icon mapping
3. Update `currentSeasonalThemes()` logic
4. Create questions with new theme

### Adding New Features
- **Multiplayer mode**: Track which player is answering
- **Scoring system**: Rate answers, track points
- **Custom questions**: Allow user-created starters
- **History**: Review previously answered questions
- **Analytics**: Track most popular questions

## Performance Considerations

- Lazy loading of questions (already implemented via filtering)
- Efficient UUID-based Set operations for tracking
- Minimal re-renders with proper @Published usage
- Timer runs on main thread (appropriate for UI updates)

## Testing Recommendations

### Unit Tests
- Filter logic in GameViewModel
- Theme auto-detection
- Timer countdown logic
- Save/load persistence

### UI Tests
- Navigation flow
- Swipe gestures
- Filter selection
- Empty states

### Manual Testing Checklist
- [ ] All vibe levels show appropriate questions
- [ ] Category filters work correctly
- [ ] Theme filters work correctly
- [ ] Timer counts down properly
- [ ] Star/unstar persists across launches
- [ ] Share functionality works
- [ ] Swipe gestures are smooth
- [ ] No questions repeat until reset
- [ ] All edge cases handled (no filters, no questions, etc.)

---

Last Updated: 2025-11-30
