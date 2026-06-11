# Games with Friends

Building connections through games.

## Overview

GamesWithFriends is a native iOS app (SwiftUI + SwiftData) that bundles a growing
collection of quick party and road-trip games behind a single Game Hub. Pick a
game, play a round with the people around you, hand the phone off.

## Games

- **Conversation Starters** — break the ice and spark great conversations
- **Country Letter Challenge** — pick a letter and name every country that starts with it
- **Name 5** — race the clock to name 5 things
- **Border Blitz** — guess countries by their borders
- **Movie Chain** — connect movies through their actors
- **Casting Director** — guess the actor from progressive clues
- **Vibe Check** — get on the same wavelength
- **Border Hop** — a solo geography trainer; navigate the world one border at a time
- **Finish the Line** — race the clock to shout the missing word from iconic quotes

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Getting Started

1. Open `GamesWithFriends.xcodeproj` in Xcode.
2. Build and run on an iOS 17+ simulator or device (⌘R).
3. Pick a game from the hub and play.

## Architecture

- **SwiftUI** for the UI (no UIKit view controllers)
- **MVVM** with the `@Observable` macro (iOS 17 Observation framework)
- **SwiftData** (`@Model`) for persistence — zero external dependencies
- **Protocol-oriented** game registry: each game conforms to `GameDefinition` and
  is registered in `Features/GameHub/GameRegistry.swift`

For the full stack, architecture, coding rules, and "add a new game" workflow, see
[`AGENTS.md`](AGENTS.md) — the single source of truth for this repo.

## Contributing

This is a personal project, but suggestions and feedback are welcome.

## License

All rights reserved.

---

Made with ❤️ for game lovers everywhere.
