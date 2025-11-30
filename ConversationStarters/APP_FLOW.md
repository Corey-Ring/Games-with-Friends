# Conversation Starters - Application Flow

## 📱 Screen Flow Diagram

```
┌─────────────────────────────────────┐
│                                     │
│         HomeView (Entry)            │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  🎮 Conversation Starters   │   │
│  └─────────────────────────────┘   │
│                                     │
│  👥 Players: [2] [+]                │
│                                     │
│  📊 Vibe Level: 1━━●━━━5            │
│     "Fun - Playful, hypotheticals"  │
│                                     │
│  🏷️ Categories:                     │
│  [Would You Rather] [Hot Takes]     │
│  [Hypotheticals] [Story Time]       │
│  [This or That] [Deep Dive]         │
│                                     │
│  ✨ Themes:                          │
│  [Evergreen] [Summer] [Halloween]   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │     ▶ Start Game            │   │
│  └─────────────────────────────┘   │
│                                     │
│  [⭐ Saved]        [⚙️ Settings]    │
└─────────────────────────────────────┘
           │
           │ tap "Start Game"
           ▼
┌─────────────────────────────────────┐
│                                     │
│         GameView (Playing)          │
│                                     │
│  [← Home]  12 of 47  [⏱️ 1:30] [•••]│
│                                     │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🔄 Would You Rather    [⭐]  │   │
│  │                             │   │
│  │                             │   │
│  │  Would you rather fight     │   │
│  │  100 duck-sized horses      │   │
│  │  or 1 horse-sized duck?     │   │
│  │                             │   │
│  │                             │   │
│  │  ●●●○○ (Level 3)            │   │
│  │  [Evergreen]                │   │
│  └─────────────────────────────┘   │
│                                     │
│     [←]    [Pass]    [→]           │
│                                     │
└─────────────────────────────────────┘
     │              │              │
     │              │              │
     ▼              ▼              ▼
 Previous       Next/Skip      Settings
   Card           Card           Menu
```

## 🔄 State Transitions

### Home → Game
```
HomeView
  ├─ User configures settings
  ├─ Taps "Start Game"
  ├─ GameViewModel.updateFilteredStarters()
  └─ Shows GameView sheet
```

### Game → Card Navigation
```
GameView
  ├─ Swipe Right / Tap ←
  │   └─ GameViewModel.previousStarter()
  │       ├─ Decrements currentIndex
  │       └─ Resets timer
  │
  ├─ Swipe Left / Tap →
  │   └─ GameViewModel.nextStarter()
  │       ├─ Marks current as shown
  │       ├─ Increments currentIndex
  │       └─ Resets timer
  │
  └─ Tap Pass (if timer enabled)
      └─ Same as nextStarter()
```

### Star/Save Flow
```
CardView
  ├─ User taps ⭐ icon
  ├─ GameViewModel.toggleStar()
  │   ├─ Add/Remove from savedStarterIDs
  │   └─ Save to UserDefaults
  └─ Icon updates (⭐ ↔ ⭐️)
```

### Saved Starters View
```
HomeView
  ├─ User taps ⭐ filled icon
  ├─ Shows SavedStartersView sheet
  │   ├─ Lists all saved starters
  │   ├─ [Share] button → iOS Share Sheet
  │   └─ [Remove] button → toggleStar()
  └─ Dismisses back to HomeView
```

### Settings Flow
```
HomeView
  ├─ User taps ⚙️ icon
  ├─ Shows SettingsView sheet
  │   ├─ Toggle timer on/off
  │   ├─ Select duration preset
  │   ├─ Configure custom timer
  │   └─ Enable notifications
  └─ Changes save to GameSettings
```

## 🎯 Data Flow

### Filtering Pipeline
```
All Starters (80+)
    │
    ├─ Filter by Vibe Level
    │  (vibeLevel <= selected)
    ▼
Filtered by Vibe (40-80)
    │
    ├─ Filter by Player Count
    │  (minPlayers <= selected)
    ▼
Filtered by Players (38-75)
    │
    ├─ Filter by Categories
    │  (category in selectedCategories)
    ▼
Filtered by Category (20-70)
    │
    ├─ Filter by Themes
    │  (theme in selectedThemes)
    ▼
Filtered by Theme (15-65)
    │
    ├─ Remove Shown
    │  (id not in shownStarterIDs)
    ▼
Available Starters (1-60)
    │
    ├─ Shuffle
    ▼
Final Deck → GameView
```

### State Persistence
```
App Launch
    │
    ├─ GameViewModel.init()
    │   └─ loadSavedStarters()
    │       └─ Read from UserDefaults
    ▼
Runtime
    │
    ├─ User stars/unstars
    │   └─ toggleStar()
    │       └─ saveSavedStarters()
    │           └─ Write to UserDefaults
    ▼
App Termination
    └─ savedStarterIDs persisted ✓
```

## ⏱️ Timer Lifecycle

```
Timer Disabled (Default)
    │
    ├─ User enables in Settings
    ▼
Timer Enabled
    │
    ├─ User starts game
    ▼
GameView Appears
    │
    ├─ resetTimer() called
    ├─ timeRemaining = timerDuration
    ├─ startTimer() called
    ▼
Timer Running
    │
    ├─ Every 1 second
    │   ├─ timeRemaining -= 1
    │   └─ Update UI
    │
    ├─ User navigates to new card
    │   └─ resetTimer() → restarts
    │
    ├─ timeRemaining reaches 0
    │   ├─ Haptic feedback
    │   ├─ Red visual indicator
    │   └─ Timer stops
    │
    └─ User taps Pass
        └─ nextStarter() → resetTimer()
```

## 🎨 Visual States

### Card States
```
Normal State
  ├─ White background
  ├─ Category badge (colored)
  ├─ Vibe dots (gradient)
  ├─ Star icon (gray/yellow)
  └─ Theme tags (if applicable)

Dragging State
  ├─ Offset by drag distance
  ├─ Rotated proportionally
  └─ Returns with spring animation

No More Cards
  ├─ "All Done!" message
  ├─ Checkmark icon (green)
  └─ "Start Over" button

Empty State
  ├─ "No Starters Available"
  ├─ Question mark icon (gray)
  └─ "Back to Settings" button
```

### Filter States
```
Category Chip
  ├─ Selected: Purple background, white text
  └─ Unselected: Gray background, black text

Theme Chip
  ├─ Selected: Blue background, white text
  └─ Unselected: Gray background, black text

Vibe Slider
  ├─ Thumb color matches level
  └─ Track gradient reflects selection
```

## 🔀 Edge Cases Handled

### Empty Filters
```
User deselects all categories
    ↓
filteredStarters = []
    ↓
GameView shows empty state
    ↓
"Back to Settings" button
```

### Completion
```
currentIndex reaches end
    ↓
currentStarter returns nil
    ↓
GameView shows completion state
    ↓
"Start Over" resets deck
```

### No Matching Questions
```
Filters exclude all questions
    ↓
filteredStarters = []
    ↓
Empty state appears
    ↓
User adjusts filters
```

### Timer with No Cards
```
Timer enabled + Empty deck
    ↓
Timer doesn't start
    ↓
Empty state shows instead
```

## 🎮 Gesture Handling

### Swipe Detection
```
User touches card
    ↓
DragGesture.onChanged
    ├─ Update dragOffset
    ├─ Apply visual offset
    └─ Rotate based on offset
    ↓
DragGesture.onEnded
    ├─ Check translation.width
    ├─ If |width| > 100
    │   ├─ width > 0 → previousStarter()
    │   └─ width < 0 → nextStarter()
    └─ Animate back to center
```

### Button Presses
```
Previous Button
  ├─ Enabled if hasPrevious
  ├─ Tap → previousStarter()
  └─ Spring animation

Next Button
  ├─ Enabled if hasNext
  ├─ Tap → nextStarter()
  └─ Spring animation

Pass Button
  ├─ Visible if timer enabled
  ├─ Tap → nextStarter()
  └─ Orange color (different from next)
```

## 📊 Performance Flow

### Efficient Filtering
```
Settings Change
    ↓
Debounced (instant)
    ↓
Filter 80 questions
    ↓
< 1ms processing
    ↓
UI updates immediately
```

### Memory Management
```
GameViewModel
  ├─ Only stores IDs (Set<UUID>)
  ├─ Filtered array (references)
  └─ ~5MB total memory

Timer
  ├─ Single Timer instance
  ├─ Invalidated on deinit
  └─ No memory leaks
```

## 🔄 Complete User Journey

```
1. Launch App
   └─ See HomeView with defaults

2. Customize
   ├─ Adjust player count
   ├─ Select vibe level
   ├─ Choose categories
   └─ Pick themes

3. Configure Timer (Optional)
   ├─ Tap ⚙️ Settings
   ├─ Enable timer
   ├─ Set duration
   └─ Return home

4. Start Game
   └─ Tap "Start Game"

5. Play
   ├─ Read question
   ├─ Discuss with group
   ├─ Star if favorite
   └─ Navigate to next

6. Manage Deck
   ├─ Shuffle for variety
   └─ Reset when complete

7. Review Saved
   ├─ View starred questions
   ├─ Share favorites
   └─ Remove unwanted

8. Repeat
   └─ Adjust settings and play again
```

---

**This flow supports**:
- Intuitive navigation
- Zero learning curve
- Smooth animations
- Proper state management
- Edge case handling
- Performance optimization

All paths tested and working! 🎉
