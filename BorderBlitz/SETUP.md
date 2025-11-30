# Border Blitz - Xcode Setup Instructions

Since this project was created as individual Swift files, you'll need to create an Xcode project to run it. Follow these steps:

## Option 1: Create New Xcode Project (Recommended)

### Step 1: Create New Project
1. Open Xcode
2. Select "File" → "New" → "Project"
3. Choose "iOS" → "App"
4. Click "Next"

### Step 2: Configure Project
- **Product Name**: `BorderBlitz`
- **Team**: Select your team or leave as "None" for simulator testing
- **Organization Identifier**: `com.yourname` or your preferred identifier
- **Interface**: `SwiftUI`
- **Language**: `Swift`
- **Storage**: Core Data (unchecked)
- **Include Tests**: (optional)

### Step 3: Add Files to Project
1. Delete the default `ContentView.swift` file that Xcode creates
2. Drag all files from the `BorderBlitz/BorderBlitz/` folder into your Xcode project
3. When prompted:
   - ✅ Check "Copy items if needed"
   - ✅ Check "Create groups"
   - ✅ Select your app target

### Step 4: Organize Files (Optional)
Create groups in Xcode to match the folder structure:
- Right-click project → "New Group" → "Models"
- Right-click project → "New Group" → "Views"
- Right-click project → "New Group" → "ViewModels"
- Right-click project → "New Group" → "Data"
- Drag files into appropriate groups

### Step 5: Configure Target
1. Select your project in the navigator
2. Select the "BorderBlitz" target
3. In "General" tab:
   - **Deployment Target**: iOS 15.0 or later
   - **Supported Destinations**: iPhone only (or add iPad)
   - **Supported Orientations**: Portrait

### Step 6: Build and Run
1. Select a simulator (e.g., iPhone 15)
2. Press `Cmd + R` or click the "Run" button
3. The app should build and launch in the simulator

## Option 2: Manual Xcode Project File (Advanced)

If you're familiar with Xcode project structure, you can create a project file manually:

### Create Basic Project Structure
```bash
cd BorderBlitz
mkdir BorderBlitz.xcodeproj
```

### Project.pbxproj Template
Due to the complexity of `.pbxproj` files, it's easier to use Option 1 and let Xcode generate this file.

## Troubleshooting

### Build Errors

**Error: "Cannot find type 'Country' in scope"**
- Make sure all files are added to the target
- Check target membership in File Inspector (right panel)

**Error: "Missing Preview Assets"**
- Create a "Preview Content" group
- Add a "Preview Assets.xcassets" folder

**Error: Module not found**
- All required frameworks (SwiftUI, Combine, CoreGraphics) are part of iOS SDK
- Ensure Deployment Target is iOS 15.0+

### Simulator Issues

**App doesn't appear on simulator**
- Check that scheme is set to your device/simulator
- Try `Product` → `Clean Build Folder` (Cmd + Shift + K)
- Restart Xcode

**Keyboard not appearing**
- In simulator: `I/O` → `Keyboard` → `Toggle Software Keyboard`
- Or press `Cmd + K`

## Project Settings

### Recommended Build Settings
- **Swift Language Version**: Swift 5
- **iOS Deployment Target**: 15.0
- **Build Active Architecture Only** (Debug): Yes

### Capabilities
No special capabilities needed. The app uses only standard iOS frameworks.

### Assets
Create an asset catalog if you want custom app icons:
1. Right-click project → "New File" → "Asset Catalog"
2. Name it `Assets.xcassets`
3. Add app icons in appropriate sizes

## Quick Start Script

Save this as `create_xcode_project.sh` in the `BorderBlitz` folder:

```bash
#!/bin/bash
# This script helps verify all files are present

echo "Border Blitz - File Check"
echo "=========================="
echo ""

files=(
    "BorderBlitz/BorderBlitzApp.swift"
    "BorderBlitz/Models/Country.swift"
    "BorderBlitz/Models/Difficulty.swift"
    "BorderBlitz/Models/LetterTile.swift"
    "BorderBlitz/Models/ScoringConfig.swift"
    "BorderBlitz/ViewModels/GameViewModel.swift"
    "BorderBlitz/Views/GameView.swift"
    "BorderBlitz/Views/MenuView.swift"
    "BorderBlitz/Views/CountrySilhouetteView.swift"
    "BorderBlitz/Views/LetterTilesView.swift"
    "BorderBlitz/Data/CountryDataProvider.swift"
)

all_present=true

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file (MISSING)"
        all_present=false
    fi
done

echo ""
if [ "$all_present" = true ]; then
    echo "All files present! Ready to create Xcode project."
    echo "Follow Option 1 in SETUP.md to create the Xcode project."
else
    echo "Some files are missing. Please ensure all files are present."
fi
```

Make it executable:
```bash
chmod +x create_xcode_project.sh
./create_xcode_project.sh
```

## Next Steps

Once your project is running:
1. Test all difficulty levels
2. Try guessing different countries
3. Check the scoring system
4. Customize countries in `CountryDataProvider.swift`
5. Adjust difficulty settings in `Difficulty.swift`

## Getting Help

If you encounter issues:
1. Check the file structure matches the README
2. Verify all files are added to the target
3. Clean build folder and rebuild
4. Check Xcode console for specific error messages
5. Ensure iOS deployment target is 15.0 or later

Happy coding! 🎮🌍
