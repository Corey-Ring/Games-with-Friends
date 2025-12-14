# License Plate Game - Quick Start Guide

## Building the App in Xcode

### Step 1: Create Xcode Project

1. Open Xcode
2. File → New → Project
3. Choose "iOS" → "App"
4. Configure:
   - Product Name: `GamesWithFriends`
   - Team: Your team
   - Organization Identifier: Your identifier
   - Interface: **SwiftUI**
   - Storage: **None** (we'll add SwiftData manually)
   - Language: **Swift**
   - Minimum Deployment: **iOS 17.0**

### Step 2: Add Files to Project

#### Method 1: Drag and Drop
1. In Finder, navigate to your project directory
2. Drag the entire folder structure into Xcode's Navigator
3. Ensure "Copy items if needed" is checked
4. Ensure "Create groups" is selected
5. Click Finish

#### Method 2: Add Files Manually
1. Right-click on the project in Navigator
2. New Group → Name it appropriately (e.g., "Core", "Features")
3. Right-click on the group → Add Files to "GamesWithFriends"
4. Navigate to and select your Swift files
5. Repeat for all files and folders

### Step 3: Organize Files in Xcode

Your project navigator should look like this:

```
GamesWithFriends
├── GamesWithFriendsApp.swift
├── ContentView.swift
├── Core
│   ├── Protocols
│   │   └── GameProtocol.swift
│   └── Theme
│       └── AppTheme.swift
└── Features
    └── LicensePlateGame
        ├── LicensePlateGame.swift
        ├── Models
        │   ├── Achievement.swift
        │   ├── LicensePlate.swift
        │   ├── PlateRegion.swift
        │   ├── RoadTrip.swift
        │   └── SpottedPlate.swift
        ├── Resources
        │   └── PlateData.swift
        ├── ViewModels
        │   └── LicensePlateViewModel.swift
        └── Views
            ├── AchievementsView.swift
            ├── LicensePlateGameView.swift
            ├── LifetimeStatsView.swift
            ├── PlateDetailView.swift
            ├── PlateGridView.swift
            ├── SpotPlateView.swift
            ├── TripSelectionView.swift
            └── TripStatsView.swift
```

### Step 4: Verify Project Settings

1. Click on the project name at the top of the Navigator
2. Under "Targets" → "GamesWithFriends" → "General":
   - Minimum Deployments: iOS 17.0 or later
3. Under "Build Phases":
   - Ensure all .swift files are in "Compile Sources"
4. Under "Signing & Capabilities":
   - Select your development team
   - Automatic signing is recommended

### Step 5: Build and Run

1. Select a simulator (e.g., "iPhone 15 Pro") from the device menu
2. Click the Play button or press Cmd+R
3. Wait for the build to complete
4. The app should launch in the simulator

## First Run Experience

When the app launches for the first time:

1. You'll see the main menu with "License Plate Game"
2. Tap on "License Plate Game"
3. You'll see the welcome screen: "Ready for a Road Trip?"
4. Tap "Start New Trip"
5. Enter a trip name (e.g., "Summer 2025 Road Trip")
6. Optionally add notes
7. Tap "Create Trip"
8. You'll see the plate grid - start spotting!

## Testing the App

### Creating a Sample Trip

1. Start a new trip called "Test Trip"
2. Spot a few plates to test functionality:
   - Tap on "CA" (California)
   - Review the detail view
   - Tap "Mark as Spotted"
   - See the celebration animation
   - Repeat with a few more states

### Testing Features

#### Trip Stats
1. Tap the menu icon (3 horizontal lines)
2. Select "Trip Stats"
3. Verify you see:
   - Overall progress
   - Regional breakdown
   - Rarity breakdown
   - Recent spots

#### Achievements
1. Menu → "Achievements"
2. You should see "First Spot" unlocked after spotting your first plate
3. See other locked achievements

#### Settings
1. Menu → "Settings"
2. Try adding a family member
3. Toggle "Show Mexican States" on/off
4. Go back and verify Mexican states appear/disappear

#### Switching Trips
1. Menu → "Switch Trip"
2. Create a second trip
3. Switch between trips
4. Verify spotted plates are separate per trip

### Testing Persistence

1. Spot a few plates
2. Close the app completely (swipe up in app switcher)
3. Relaunch the app
4. Navigate to License Plate Game
5. Verify all spotted plates are still there

## Common Build Issues

### Issue: "Cannot find type 'RoadTrip' in scope"
**Solution:** Ensure `RoadTrip.swift` is in "Compile Sources" under Build Phases

### Issue: "@Observable requires iOS 17.0 or later"
**Solution:** Set Minimum Deployment to iOS 17.0 in project settings

### Issue: SwiftData import error
**Solution:** SwiftData is built into iOS 17+, no additional imports needed

### Issue: Preview crashes
**Solution:** Previews use in-memory model containers. Ensure preview code includes:
```swift
.modelContainer(for: [RoadTrip.self, SpottedPlate.self], inMemory: true)
```

### Issue: "Modifying state during view update"
**Solution:** This is usually from updating @State in the body. Move updates to .onAppear or button actions

## Testing on Device

### Prerequisites
1. Physical iPhone or iPad running iOS 17.0+
2. Apple Developer account (free or paid)
3. Device connected via USB or WiFi

### Steps
1. Connect your device
2. Select your device from the device menu (instead of simulator)
3. Xcode may ask you to register the device - follow prompts
4. Build and run (Cmd+R)
5. First time: Trust the developer certificate on device
   - Settings → General → VPN & Device Management
   - Tap on your developer account
   - Tap "Trust"
6. App should launch on device

### Testing Persistence on Device
1. Run the app
2. Create a trip and spot some plates
3. Close the app
4. Disconnect device from computer
5. Wait a few minutes
6. Relaunch the app
7. Verify all data is still there

## Performance Testing

### Recommended Tests

1. **Large Trip Test**
   - Spot 40+ plates in a single trip
   - Verify scrolling is smooth
   - Check stats view performance

2. **Multiple Trips Test**
   - Create 10+ trips
   - Switch between them
   - Verify no lag or crashes

3. **Memory Test**
   - Run the app
   - Navigate through all views
   - Check Xcode's memory graph for leaks
   - Memory usage should be reasonable (<100MB)

## Debugging Tips

### Enable Debug Logging

Add to `LicensePlateViewModel.swift`:

```swift
func spotPlate(...) {
    print("Spotting plate: \(plate.code)")
    // ... rest of function
}
```

### View SwiftData Database

Use Xcode's Database Inspector:
1. Run app in simulator
2. Debug → View Memory Graph
3. Filter for "RoadTrip" or "SpottedPlate"
4. Inspect object properties

### Testing Edge Cases

1. **Empty Trip**: Create trip without spotting any plates
2. **All Spotted**: Spot all 51 US plates (time-consuming but thorough)
3. **Delete Active Trip**: Delete the currently active trip
4. **Rapid Tapping**: Quickly tap multiple plates to test threading
5. **Long Names**: Add family member with very long name

## Next Steps

Once the app is working:

1. **Customize**: Edit fun facts, add more achievements, customize UI colors
2. **Extend**: Add map view, photos, or other features from the prompt
3. **Polish**: Add animations, haptics, sound effects
4. **Test**: Get friends/family to beta test on real road trips
5. **Deploy**: Submit to App Store (requires paid developer account)

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [WWDC SwiftData Videos](https://developer.apple.com/videos/play/wwdc2023/10187/)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

## Support

If you encounter issues:
1. Check console logs in Xcode for error messages
2. Verify all files are properly added to project
3. Clean build folder (Shift+Cmd+K) and rebuild
4. Delete derived data if needed
5. Restart Xcode and/or simulator

---

**Happy coding and happy road tripping!**
