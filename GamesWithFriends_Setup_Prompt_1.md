# Games with Friends - iOS App Setup Prompt for Claude Code

## Project Overview

Create a SwiftUI iOS app called "Games with Friends" that serves as a hub for multiple party games. The app should use a modular architecture where each game is self-contained and conforms to a common protocol.

## Target Specifications

- **Platform**: iOS 17.0+
- **Framework**: SwiftUI
- **Architecture**: MVVM with Protocol-based Game Modules
- **Language**: Swift 5.9+

---

## Project Structure

```
GamesWithFriends/
├── GamesWithFriendsApp.swift          # Main app entry point
├── ContentView.swift                   # Root view
├── Core/
│   ├── Protocols/
│   │   └── GameProtocol.swift         # Protocol all games must conform to
│   └── Theme/
│       └── AppTheme.swift             # Shared colors, fonts, dimensions
├── Features/
│   ├── GameHub/
│   │   └── GameHubView.swift          # Main menu with game selection
│   └── PlaceholderGame/
│       └── PlaceholderGame.swift      # Template game for testing
└── Resources/
    └── Assets.xcassets
```

---

## File Contents

### 1. GameProtocol.swift
**Location**: `Core/Protocols/GameProtocol.swift`

```swift
import SwiftUI

// This protocol defines what information every game must provide
protocol GameDefinition: Identifiable {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var iconName: String { get }        // SF Symbol name
    var accentColor: Color { get }
    
    // This creates the game's main view
    @ViewBuilder
    func makeRootView() -> AnyView
}
```

---

### 2. AppTheme.swift
**Location**: `Core/Theme/AppTheme.swift`

```swift
import SwiftUI

// Central place for all app colors and styles
struct AppTheme {
    
    // MARK: - Colors
    
    static let primaryGradient = LinearGradient(
        colors: [Color.blue, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundColor = Color(UIColor.systemGroupedBackground)
    
    // MARK: - Dimensions
    
    static let cornerRadius: CGFloat = 16
    static let padding: CGFloat = 16
    static let cardSpacing: CGFloat = 16
}
```

---

### 3. PlaceholderGame.swift
**Location**: `Features/PlaceholderGame/PlaceholderGame.swift`

```swift
import SwiftUI

// A simple placeholder game for testing
struct PlaceholderGame: GameDefinition {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let accentColor: Color
    
    func makeRootView() -> AnyView {
        AnyView(PlaceholderGameView(gameName: name))
    }
}

// The actual view for the placeholder game
struct PlaceholderGameView: View {
    let gameName: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
                
                Text(gameName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("This game is coming soon!")
                    .foregroundStyle(.secondary)
                
                Button("Back to Games") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 40)
            }
            .navigationTitle(gameName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Preview for Xcode canvas
#Preview {
    PlaceholderGameView(gameName: "Test Game")
}
```

---

### 4. GameHubView.swift
**Location**: `Features/GameHub/GameHubView.swift`

```swift
import SwiftUI

struct GameHubView: View {
    
    // List of all available games
    let games: [any GameDefinition] = [
        PlaceholderGame(
            id: "conversation-starters",
            name: "Conversation Starters",
            description: "Break the ice with fun prompts",
            iconName: "bubble.left.and.bubble.right.fill",
            accentColor: .purple
        ),
        PlaceholderGame(
            id: "border-blitz",
            name: "Border Blitz",
            description: "Identify countries by their shape",
            iconName: "map.fill",
            accentColor: .blue
        ),
        PlaceholderGame(
            id: "trivia",
            name: "Trivia Night",
            description: "Test your knowledge",
            iconName: "questionmark.circle.fill",
            accentColor: .orange
        )
    ]
    
    // Track which game is selected
    @State private var selectedGame: (any GameDefinition)?
    @State private var showingGame = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.cardSpacing) {
                    // Header
                    headerSection
                    
                    // Game cards
                    ForEach(games, id: \.id) { game in
                        GameCard(game: game) {
                            selectedGame = game
                            showingGame = true
                        }
                    }
                }
                .padding(AppTheme.padding)
            }
            .background(AppTheme.backgroundColor)
            .navigationTitle("Games")
            .fullScreenCover(isPresented: $showingGame) {
                if let game = selectedGame {
                    game.makeRootView()
                }
            }
        }
    }
    
    // Header section at the top
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 50))
                .foregroundStyle(AppTheme.primaryGradient)
            
            Text("Games with Friends")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Choose a game to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 20)
    }
}

// Individual game card component
struct GameCard: View {
    let game: any GameDefinition
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Game icon
                Image(systemName: game.iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(game.accentColor.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Game info
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(game.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(AppTheme.padding)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

// Preview
#Preview {
    GameHubView()
}
```

---

### 5. ContentView.swift
**Location**: `ContentView.swift` (root level)

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        GameHubView()
    }
}

#Preview {
    ContentView()
}
```

---

### 6. GamesWithFriendsApp.swift
**Location**: `GamesWithFriendsApp.swift` (root level)

```swift
import SwiftUI

@main
struct GamesWithFriendsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## Verification Checklist

After setup, verify the following:

### Build Verification
- [ ] Project builds without errors (Cmd + B)
- [ ] No warnings related to missing files
- [ ] All 6 Swift files are present and linked to target

### Runtime Verification
- [ ] App launches in simulator (Cmd + R)
- [ ] Game Hub displays with header "Games with Friends"
- [ ] Three game cards are visible:
  - Conversation Starters (purple icon)
  - Border Blitz (blue icon)
  - Trivia Night (orange icon)
- [ ] Tapping a game card opens the placeholder game view
- [ ] "Back to Games" button dismisses and returns to hub

### UI Verification
- [ ] Header shows party popper icon with gradient
- [ ] Game cards have rounded corners and proper spacing
- [ ] Icons display correctly with colored backgrounds
- [ ] Chevron arrows appear on the right side of cards

---

## Common Issues & Solutions

### Issue: "Cannot find 'GameHubView' in scope"
**Solution**: Ensure GameHubView.swift is added to the app target. Select the file → File Inspector (right panel) → check "Target Membership" for GamesWithFriends.

### Issue: "Cannot find 'GameDefinition' in scope"
**Solution**: Ensure GameProtocol.swift is added to the app target.

### Issue: "Cannot find 'AppTheme' in scope"
**Solution**: Ensure AppTheme.swift is added to the app target.

### Issue: Files show in navigator but code doesn't compile
**Solution**: 
1. Select each .swift file
2. Open File Inspector (View → Inspectors → File)
3. Under "Target Membership", ensure the app target is checked

---

## Next Steps After Basic Setup

Once the basic architecture is verified working:

1. **Integrate Conversation Starters Game**
   - Create `Features/ConversationStarters/` folder
   - Move existing game files into this folder
   - Create `ConversationStartersGame.swift` conforming to `GameDefinition`
   - Replace placeholder in GameHubView

2. **Integrate Border Blitz Game**
   - Create `Features/BorderBlitz/` folder
   - Move existing game files into this folder
   - Create `BorderBlitzGame.swift` conforming to `GameDefinition`
   - Replace placeholder in GameHubView

3. **Add Shared Services**
   - Create `Core/Services/PersistenceService.swift` for data storage
   - Create `Core/Services/HapticsService.swift` for haptic feedback
   - Create `Core/Services/AudioService.swift` for sound effects

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         App Entry                            │
│                   GamesWithFriendsApp.swift                  │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                      ContentView.swift                       │
│                    (Shows GameHubView)                       │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                      GameHubView.swift                       │
│              (Lists all games, handles selection)            │
└──────────┬──────────────┬──────────────┬────────────────────┘
           │              │              │
           ▼              ▼              ▼
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │  Game 1  │   │  Game 2  │   │  Game 3  │
    │ (Convo)  │   │ (Border) │   │ (Trivia) │
    └──────────┘   └──────────┘   └──────────┘
           │              │              │
           └──────────────┴──────────────┘
                          │
                          ▼
            ┌─────────────────────────┐
            │     GameDefinition      │
            │       Protocol          │
            │  (Common interface for  │
            │      all games)         │
            └─────────────────────────┘
```

---

## Summary

This setup creates a scalable foundation for a multi-game iOS app where:

- Each game is **self-contained** in its own folder
- All games conform to the **GameDefinition protocol**
- The **GameHub** serves as the central navigation point
- **AppTheme** provides consistent styling across the app
- Adding new games only requires creating a new folder and conforming to the protocol
