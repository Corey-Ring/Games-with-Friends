# Conversation Starters - iOS Game

A SwiftUI iOS game that helps break the ice and spark great conversations at any gathering!

## Features

### 🎮 Core Gameplay
- **Player Selection**: Choose 2-10+ players
- **Vibe Levels**: Select from 5 different intensity levels
  - 1️⃣ **Icebreaker** - Work-appropriate, light topics
  - 2️⃣ **Casual** - Friendly get-togethers
  - 3️⃣ **Fun** - Playful, hypotheticals
  - 4️⃣ **Spicy** - Deeper, more revealing questions
  - 5️⃣ **Wild** - Silly, absurd, or bold questions

### 📂 Categories
- 🔄 **Would You Rather** - Binary choice questions
- 🔥 **Hot Takes** - Opinion-based prompts
- 💡 **Hypotheticals** - Imaginative "what if" scenarios
- 📖 **Story Time** - Personal anecdote prompts
- ⚖️ **This or That** - Quick preference questions
- 🎯 **Deep Dive** - Thoughtful, reflective questions (levels 3-5)

### 🎄 Seasonal Themes
The app includes special themed questions for:
- 🍂 Thanksgiving (November)
- 🎃 Halloween (October)
- ❄️ Winter Holidays (December)
- 🎉 New Year (January)
- 💝 Valentine's Day (February)
- ☀️ Summer (June-August)
- 🎒 Back to School (September)
- ⭐ Evergreen (Year-round)

### ⏱️ Timer Feature
- Optional countdown timer for each question
- Preset durations: 30 seconds, 1 minute, 2 minutes
- Custom timer configuration
- Visual countdown display
- Pass button to skip questions
- Haptic feedback when time expires

### ⭐ Star/Save Feature
- Save favorite conversation starters
- Access saved questions anytime
- Share individual starters via iOS share sheet
- Persists between app sessions

### 🎨 UI Features
- Beautiful card-based interface
- Swipe left/right to navigate
- Previous/Next buttons
- Color-coded vibe levels (blue → green → yellow → orange → red)
- Progress indicator
- Shuffle and reset deck options
- Responsive design

## How to Use

1. **Open the app** and you'll see the home screen
2. **Select number of players** using the +/- buttons
3. **Choose your vibe level** with the slider
4. **Filter categories** by tapping category chips (optional)
5. **Select themes** - defaults to current seasonal + evergreen
6. **Configure timer** via settings icon (optional)
7. **Tap "Start Game"** to begin
8. **Swipe or tap** arrows to navigate between questions
9. **Tap the star** to save favorite questions
10. **Use the menu** (•••) to shuffle or reset the deck

## Project Structure

```
ConversationStarters/
├── ConversationStartersApp.swift    # Main app entry point
├── Models/
│   ├── ConversationStarter.swift    # Data models
│   └── GameSettings.swift           # Settings model
├── ViewModels/
│   └── GameViewModel.swift          # Game logic
├── Views/
│   ├── HomeView.swift               # Main menu
│   ├── GameView.swift               # Card display
│   ├── SettingsView.swift           # Timer settings
│   └── SavedStartersView.swift      # Saved questions
└── Data/
    └── SampleData.swift             # Question database
```

## Requirements

- iOS 16.0+
- Xcode 14.0+
- SwiftUI

## Installation

1. Open Xcode
2. Create a new iOS App project named "ConversationStarters"
3. Copy all Swift files into your project
4. Build and run on simulator or device

## Customization

### Adding New Questions

Edit `Data/SampleData.swift` and add new `ConversationStarter` objects:

```swift
ConversationStarter(
    text: "Your question here",
    vibeLevel: 3,  // 1-5
    category: .wouldYouRather,
    themes: [.evergreen],
    minPlayers: nil  // optional
)
```

### Modifying Timer Presets

Edit `Models/GameSettings.swift` to change timer preset values.

### Customizing Colors

Update the vibe level color mappings in `HomeView.swift` and `GameView.swift`.

## Tips for Great Conversations

- Start with lower vibe levels to warm up
- Mix different categories for variety
- Use the timer to keep things moving
- Save your favorite questions for future use
- Don't be afraid to skip questions that don't fit the moment

## Privacy

All data is stored locally on your device using UserDefaults. No information is collected or transmitted.

## License

This is a personal project created for entertainment purposes.

## Support

For issues or feature requests, please create an issue in the repository.

---

Enjoy sparking meaningful conversations! 🎉
