# License Plate Game - Complete Implementation Guide

## Overview

The License Plate Game is a fully-featured iOS app built with SwiftUI that allows users to track license plates spotted during road trips. The app uses SwiftData for persistent storage, ensuring all data survives app sessions and device restarts.

## Features Implemented

### Core Features
- **Persistent Data Storage** using SwiftData
- **Multiple Trip Management** - Create, switch between, and archive trips
- **Comprehensive Plate Database**
  - All 50 US States + District of Columbia
  - 5 US Territories (Puerto Rico, US Virgin Islands, Guam, American Samoa, Northern Mariana Islands)
  - 10 Canadian Provinces
  - 3 Canadian Territories
  - 32 Mexican States (toggleable)
- **Rarity System** - Common, Uncommon, Rare, Ultra-Rare plates
- **Achievement System** - 19+ achievements across 4 categories
- **Family Member Tracking** - Track who spotted each plate
- **Statistics Views** - Trip stats and lifetime statistics
- **Fun Facts** - Educational information about each location

### User Interface
- **Grid View** - Visual grid of all plates with spotted status
- **List View** - Alternative list-based view
- **Plate Detail View** - In-depth information about each plate
- **Spot Plate Flow** - Easy-to-use interface for marking plates
- **Trip Selection** - Manage and switch between trips
- **Settings** - Configure game options and family members

## Project Structure

```
GamesWithFriends/
├── GamesWithFriendsApp.swift           # Main app entry point with SwiftData config
├── ContentView.swift                    # App home screen
├── Core/
│   ├── Protocols/
│   │   └── GameProtocol.swift          # Protocol for all games
│   └── Theme/
│       └── AppTheme.swift              # Centralized styling
└── Features/
    └── LicensePlateGame/
        ├── LicensePlateGame.swift      # GameProtocol conformance
        ├── Models/
        │   ├── Achievement.swift       # Achievement system
        │   ├── LicensePlate.swift      # Plate model
        │   ├── PlateRegion.swift       # Enums for regions & rarity
        │   ├── RoadTrip.swift          # SwiftData trip model
        │   └── SpottedPlate.swift      # SwiftData spotted plate model
        ├── Resources/
        │   └── PlateData.swift         # Complete plate database (all regions)
        ├── ViewModels/
        │   └── LicensePlateViewModel.swift  # Main game logic
        └── Views/
            ├── LicensePlateGameView.swift   # Main container
            ├── TripSelectionView.swift      # Trip management
            ├── PlateGridView.swift          # Grid/list display
            ├── PlateDetailView.swift        # Plate details
            ├── SpotPlateView.swift          # Spot plate flow
            ├── TripStatsView.swift          # Current trip stats
            ├── LifetimeStatsView.swift      # All-time stats
            └── AchievementsView.swift       # Achievement display
```

## Data Models

### SwiftData Models

#### RoadTrip
Represents a single road trip with all spotted plates.

```swift
@Model
class RoadTrip {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    var spottedPlates: [SpottedPlate]
    var notes: String?

    // Computed properties
    var totalSpotted: Int
    var usStatesSpotted: Int
    var canadianProvincesSpotted: Int
    var totalPoints: Int
}
```

#### SpottedPlate
Represents a single spotted license plate with metadata.

```swift
@Model
class SpottedPlate {
    var id: UUID
    var plateCode: String
    var plateName: String
    var region: String
    var rarityTier: String
    var spottedAt: Date
    var locationDescription: String?
    var latitude: Double?
    var longitude: Double?
    var spottedBy: String?
    var trip: RoadTrip?
}
```

### Regular Models

#### LicensePlate
Static data for each plate/region.

```swift
struct LicensePlate: Identifiable, Codable, Hashable {
    let id: String
    let code: String
    let name: String
    let region: PlateRegion
    let capital: String
    let nickname: String?
    let rarityTier: RarityTier
    let funFact: String
}
```

#### PlateRegion & RarityTier
Enums for categorization.

```swift
enum PlateRegion: String, Codable, CaseIterable {
    case usState
    case usTerritory
    case canadianProvince
    case canadianTerritory
    case mexicanState
}

enum RarityTier: String, Codable, CaseIterable {
    case common      // 1 point
    case uncommon    // 2 points
    case rare        // 5 points
    case ultraRare   // 10 points
}
```

## Key Features Deep Dive

### 1. Persistent Data with SwiftData

All trip and spotted plate data is automatically persisted using SwiftData. The app configuration in `GamesWithFriendsApp.swift`:

```swift
@main
struct GamesWithFriendsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [RoadTrip.self, SpottedPlate.self])
    }
}
```

This ensures:
- Data survives app termination
- Automatic iCloud sync (if enabled)
- Efficient querying and updates
- Relationship management

### 2. Rarity System

Plates are categorized by rarity based on population and likelihood of spotting:

- **Common** (13 states): CA, TX, FL, NY, etc. - High population states
- **Uncommon** (25 states): Average population states
- **Rare** (10 states): Low population states like WY, VT, AK
- **Ultra-Rare** (Territories + special): VT, WY, PR, VI, GU, AS, MP, PE, YT, NT, NU

Each rarity tier awards different points:
- Common: 1 point
- Uncommon: 2 points
- Rare: 5 points
- Ultra-Rare: 10 points

### 3. Achievement System

19+ achievements across 4 categories:

#### Progress Achievements
- First Spot
- Getting Started (10 plates)
- Road Warrior (25 plates)
- Halfway There (26 US states)
- The Fifty Club (all 50 states)

#### Rarity Achievements
- Rare Find (first rare plate)
- Ultra Rare (first ultra-rare)
- Unicorn Hunter (5 rare plates)
- The Collector (3 ultra-rare plates)

#### Regional Achievements
- New England Sweep
- Pacific States
- Great Lakes
- Four Corners
- Mountain Time

#### Special Achievements
- Coast to Coast (CA and NY)
- Border Hopper (Canadian plate)
- Continental (US, Canada, AND Mexico)
- The Dakotas (ND and SD)
- Vowel Master (all vowel states)

### 4. Family Mode

Track which family member spotted each plate:
- Add family members in Settings
- Select spotter when marking a plate
- View individual tallies
- Friendly competition tracking

### 5. Statistics

#### Trip Stats
- Overall progress with circular progress view
- Regional breakdown
- Rarity breakdown with point totals
- Recent spots with timestamps
- Achievements unlocked during trip

#### Lifetime Stats
- Total trips taken
- Unique plates spotted across all trips
- Total plate spots (including duplicates)
- Most spotted plate
- Rarest tier ever spotted
- US coverage percentage
- Trip history with details

## Usage Guide

### Getting Started

1. **Launch the App**
   - First time: You'll see a welcome screen
   - Tap "Start New Trip" to create your first trip

2. **Create a Trip**
   - Enter a trip name (e.g., "Summer Road Trip 2025")
   - Optionally add notes
   - Tap "Create Trip"

3. **Spot a Plate**
   - Browse the grid or list view
   - Tap an unspotted plate
   - Review the plate details
   - Tap "Mark as Spotted"
   - Optionally:
     - Select who spotted it
     - Add location notes
   - Tap "Spotted!" to confirm
   - Enjoy the celebration animation and fun fact!

4. **Track Progress**
   - View trip header for quick stats
   - Access menu (3 lines) for:
     - Trip Stats
     - Lifetime Stats
     - Achievements
     - Settings

5. **Manage Trips**
   - Switch trips via menu → "Switch Trip"
   - Create new trips
   - Archive old trips
   - View trip history in Lifetime Stats

### Settings

- **Show Mexican States**: Toggle to include/exclude Mexican plates
- **Family Members**: Add/remove family members for tracking
- **View Mode**: Automatically switches between Grid and List

## Technical Details

### Dependencies
- SwiftUI
- SwiftData
- Foundation

### iOS Version Requirements
- Minimum: iOS 17.0+ (required for SwiftData)
- Recommended: iOS 17.2+

### Performance Considerations

1. **Data Loading**
   - Plate data is static and loaded once
   - Trips are fetched with sorted descriptors
   - Lazy loading for large lists

2. **Memory Management**
   - @Observable for reactive updates
   - Lazy grids for efficient scrolling
   - Filtered arrays computed on-demand

3. **Persistence**
   - SwiftData handles automatic saving
   - Manual saves after critical operations
   - Relationship cascading for deletions

## Accessibility

The app is fully accessible with:
- VoiceOver support for all interactive elements
- Dynamic Type for scalable text
- High contrast mode support
- Alternative list view for users who prefer linear navigation
- Semantic labels for all images and icons

## Future Enhancements (Optional)

Potential features to add:
1. **Map Visualization**
   - Interactive US/Canada maps
   - Visual state highlighting
   - SVG-based state shapes

2. **Location Services**
   - Auto-detect current location
   - GPS coordinates for spots
   - Map integration for viewing spot locations

3. **Sharing**
   - Share trip summary as image
   - Export trip data
   - Social media integration

4. **Photos**
   - Attach photos of spotted plates
   - Photo gallery view
   - Camera integration

5. **Widgets**
   - Home screen widget showing progress
   - Lock screen widget for quick stats

6. **Game Modes**
   - Timed challenges
   - Multiplayer races
   - Custom plate lists (e.g., "Spot all Western states")

## Testing

### Preview Support
All views include SwiftUI previews for development:

```swift
#Preview {
    LicensePlateGameView()
        .modelContainer(for: [RoadTrip.self, SpottedPlate.self], inMemory: true)
}
```

### Test Data
For testing, you can create sample trips and spotted plates programmatically in previews.

## Build Instructions

### Xcode Project Setup

1. Create a new iOS App project in Xcode
2. Set minimum deployment target to iOS 17.0
3. Add all Swift files to the project
4. Ensure file structure matches the layout above
5. Build and run on simulator or device

### File Organization Tips

- Keep the exact folder structure for clarity
- Group files by feature in Xcode navigator
- Use `// MARK:` comments for organization within files

## Data Reference

### Complete Plate Count
- **US States**: 50 + DC = 51
- **US Territories**: 5 (PR, VI, GU, AS, MP)
- **Canadian Provinces**: 10
- **Canadian Territories**: 3
- **Mexican States**: 32 (optional)
- **Total with Mexico**: 101
- **Total without Mexico**: 69

### Regional Groups (for Achievements)
Defined in `PlateData.swift`:
- New England: 6 states
- Mid-Atlantic: 3 states
- South Atlantic: 9 regions
- East South Central: 4 states
- West South Central: 4 states
- East North Central: 5 states
- West North Central: 7 states
- Mountain: 8 states
- Pacific: 5 states
- Four Corners: 4 states
- Great Lakes: 8 states
- Gulf Coast: 5 states

## Credits

Built with SwiftUI and SwiftData for iOS.
Uses SF Symbols for all iconography.
Fun facts sourced from publicly available information.

## License

This project is part of the GamesWithFriends app.

---

**Enjoy your road trip and happy plate spotting!**
