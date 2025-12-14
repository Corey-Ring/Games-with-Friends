# Games with Friends
Building connections through games

## Overview

GamesWithFriends is an iOS app built with SwiftUI that brings classic games to your mobile device. Perfect for road trips, family gatherings, and creating lasting memories.

## Features

### License Plate Game
A complete implementation of the classic road trip game where players spot license plates from different regions.

**Key Features:**
- Track plates from all 50 US states, DC, and 5 US territories
- Canadian provinces and territories (10 provinces + 3 territories)
- Optional Mexican states (32 states)
- Persistent data with SwiftData - never lose your progress
- Multiple trip management - track different road trips separately
- Achievement system with 19+ achievements
- Family member tracking for friendly competition
- Rarity tiers (Common, Uncommon, Rare, Ultra-Rare)
- Fun facts about each state/province
- Comprehensive statistics (trip stats + lifetime stats)
- Grid and list view options

See [LICENSE_PLATE_GAME_README.md](LICENSE_PLATE_GAME_README.md) for complete documentation.

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Project Structure

```
GamesWithFriends/
├── GamesWithFriendsApp.swift
├── ContentView.swift
├── Core/
│   ├── Protocols/
│   └── Theme/
└── Features/
    └── LicensePlateGame/
        ├── Models/
        ├── ViewModels/
        ├── Views/
        └── Resources/
```

## Getting Started

1. Open the project in Xcode
2. Build and run on the iOS simulator or a physical device
3. Navigate to "License Plate Game"
4. Create your first road trip
5. Start spotting license plates!

## Architecture

- **SwiftUI** for modern, declarative UI
- **MVVM** pattern for clean separation of concerns
- **SwiftData** for persistent storage
- **@Observable** macro for reactive state management
- **Protocol-oriented** design for extensibility

## Future Games

This architecture is designed to support multiple games. Future additions could include:
- Conversation Starters
- Road Trip Bingo
- 20 Questions
- And more!

## Contributing

This is a personal project, but suggestions and feedback are welcome.

## License

All rights reserved.

---

Made with ❤️ for road trippers and game lovers everywhere.
