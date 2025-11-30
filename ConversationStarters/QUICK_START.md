# Quick Start Guide - Conversation Starters

## Setting Up the Xcode Project

### Method 1: Manual Setup (Recommended)

1. **Open Xcode** (version 14.0 or later)

2. **Create New Project**
   - File → New → Project
   - Choose "iOS" → "App"
   - Click "Next"

3. **Configure Project**
   - Product Name: `ConversationStarters`
   - Team: Select your team
   - Organization Identifier: `com.yourname.conversationstarters`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Click "Next" and choose a location

4. **Add Source Files**
   - Delete the default `ContentView.swift` file
   - Drag and drop all files from the ConversationStarters folder into your Xcode project:
     - `ConversationStartersApp.swift`
     - `Models/` folder
     - `ViewModels/` folder
     - `Views/` folder
     - `Data/` folder

5. **Configure Target**
   - Select your project in the navigator
   - Select the "ConversationStarters" target
   - Set "Minimum Deployments" to iOS 16.0 or later

6. **Build and Run**
   - Select a simulator or device
   - Press Cmd+R or click the Run button
   - The app should launch successfully!

### Method 2: Using Provided Files

If you have the complete file structure:

1. Open Terminal
2. Navigate to the ConversationStarters directory
3. The project is ready to import into Xcode

## Minimum Requirements

- **macOS**: 12.0 (Monterey) or later
- **Xcode**: 14.0 or later
- **iOS Deployment Target**: 16.0 or later
- **SwiftUI**: Included with iOS 16+

## Testing the App

### On Simulator
1. In Xcode, select any iPhone simulator (iPhone 14 recommended)
2. Press Cmd+R to build and run
3. Wait for the simulator to launch

### On Physical Device
1. Connect your iPhone via USB
2. Select your device from the device menu
3. You may need to trust the developer certificate on your device
4. Press Cmd+R to build and run

## First Run Walkthrough

1. **Home Screen**
   - You'll see the Conversation Starters logo
   - Default settings: 2 players, Vibe Level 3

2. **Customize Settings**
   - Tap +/- to adjust player count
   - Slide the vibe level selector
   - Tap category chips to filter (purple = selected)
   - Tap theme chips to select seasonal content (blue = selected)

3. **Start Playing**
   - Tap "Start Game" button
   - Cards will appear with questions
   - Swipe left/right or use arrow buttons to navigate

4. **Try Features**
   - Tap the ⭐ star to save favorites
   - Tap the ⚙️ gear for timer settings
   - Tap the ⭐ filled star (top left) to view saved questions
   - Use the ••• menu in game for shuffle/reset

## Troubleshooting

### Build Errors

**"Cannot find type 'ConversationStarter'"**
- Make sure all files in the Models folder are added to the target
- Check that files are part of the ConversationStarters target in File Inspector

**"No such module 'SwiftUI'"**
- Ensure iOS Deployment Target is set to 16.0 or later
- Clean build folder (Cmd+Shift+K) and rebuild

### Runtime Issues

**App crashes on launch**
- Check the console for error messages
- Verify all @StateObject and @ObservedObject are properly initialized
- Make sure Info.plist has required permissions

**Empty state shows "No Starters Available"**
- At least one category must be selected
- At least one theme must be selected
- Check that vibe level filters aren't excluding all questions

**Timer not working**
- Enable timer in Settings (gear icon)
- Select a timer duration
- Timer auto-starts when you view a new card

## Adding Your Own Questions

1. Open `Data/SampleData.swift`
2. Add new entries to the `allStarters` array:

```swift
ConversationStarter(
    text: "What's your dream vacation destination?",
    vibeLevel: 2,
    category: .storyTime,
    themes: [.evergreen, .summer]
),
```

3. Build and run to see your new questions!

## Tips for Development

- Use Live Preview in Xcode for faster iteration
- Test on different screen sizes (iPhone SE, iPhone 14 Pro Max)
- Check both light and dark mode
- Test with different vibe levels and filter combinations

## Next Steps

- Customize colors and fonts to match your style
- Add more conversation starters
- Implement additional categories
- Create custom seasonal themes
- Add sound effects or animations

## Getting Help

- Check the main README.md for detailed documentation
- Review Apple's SwiftUI documentation
- Search for specific error messages in Xcode's documentation

---

Happy coding and enjoy the conversations! 🎉
