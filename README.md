# Games with Friends

A collection of educational geography games to build shared trivia muscles with friends and family.

## 🎮 Available Games

### 1. Border Blitz (iOS)
**A fast-paced country identification game for iPhone**

Identify countries from their geographic borders as letters reveal one by one. Race against the clock and score points based on speed and accuracy!

- **Platform**: iOS (SwiftUI)
- **Location**: `BorderBlitz/`
- **Type**: Single-player, timed challenge
- **Features**:
  - 15 countries with recognizable silhouettes
  - 4 difficulty levels (Easy to Expert)
  - Progressive letter reveal system
  - Advanced scoring with streaks and bonuses
  - Beautiful SwiftUI interface

[**📖 Read the full Border Blitz README →**](BorderBlitz/README.md)

### 2. Country Letter Guessing Game
**Pick a letter and recall every country that starts with it**

Available in two versions for maximum accessibility:

- **Web Version**: Modern, single-file HTML game with a clean UI, perfect for quick games in any browser
- **Python CLI Version**: Terminal-based game with advanced features like hints, scoring, and multi-round sessions

Both versions accept common alternate spellings and handle case/accent variations.

## Features
- **Case- and accent-insensitive matching** with generous alternate-name support (e.g., `Ivory Coast` → `Côte d'Ivoire`)
- **195 countries** from UN members plus common observer/short names
- **Mobile-responsive** design (web version)
- **Real-time progress tracking** with visual feedback

### Python CLI Version Additional Features
- Interactive prompts with helper commands: `hint`, `status`, `help`, and `done`
- CLI flags to start on a specific letter, pick random letters, or play several rounds automatically
- Personal bests and perfect-round streak tracking, persisted to `~/.country_letter_game_scores.json`
- Unittests covering the normalization and lookup helpers

## Getting Started

### Web Version (Recommended for Quick Games)

Simply open `country_letter_game.html` in any modern web browser:

```bash
# Option 1: Double-click the file
open country_letter_game.html

# Option 2: Use a local server (optional)
python3 -m http.server 8000
# Then visit http://localhost:8000/country_letter_game.html
```

**Web Version Features:**
- Single HTML file with embedded CSS and JavaScript (no dependencies)
- Modern, clean UI with gradient background
- Letter selection buttons (A-Z)
- Input field with auto-focus
- Progress display (X/Y found) and remaining count
- Visual feedback with ✓/✗ icons
- Results screen showing missed countries
- "Perfect round" message when all countries are found
- "Play Again" button
- Fully mobile-responsive

**Note:** Both versions use the same country database (195 countries) and matching logic, so alternate names work the same way in both.

### Python CLI Version

**Requirements:**
- Python 3.9+ (tested with the system's `python3`)

**Setup:**
```bash
git clone <repo-url>
cd Games-with-Friends
```
No extra dependencies are required; everything uses the standard library.

## Running the Python Game
```bash
# Classic interactive session (prompts for a letter each round)
python3 country_letter_game.py

# Jump straight to a particular letter
python3 country_letter_game.py --letter G

# Let the game choose random valid letters for three consecutive rounds
python3 country_letter_game.py --random-letter --rounds 3
```

During a round you can enter:
- Country names (required) — duplicates are ignored with a friendly reminder.
- `help` — recap the available commands and remaining count.
- `status` — see progress without revealing answers.
- `hint` — reveal the first few letters of a remaining country.
- `done`/`quit`/`exit` — stop early and reveal the misses.

Score data (best percentages per letter plus perfect-round streaks) lives at `~/.country_letter_game_scores.json`. Delete that file if you want a fresh start.

## Repository Structure
```
Games-with-Friends/
├── BorderBlitz/                    # iOS country border identification game
│   ├── BorderBlitz/               # Source code
│   │   ├── Models/               # Data models (Country, Difficulty, Scoring)
│   │   ├── Views/                # SwiftUI views
│   │   ├── ViewModels/           # Game state management
│   │   └── Data/                 # Country border data
│   ├── README.md                 # Border Blitz documentation
│   └── SETUP.md                  # Xcode setup instructions
├── country_letter_game.html       # Web version (single file, no dependencies)
├── country_letter_game.py         # Python CLI version
│   ├── _norm                     # Normalizes user input
│   ├── COUNTRIES / LETTER_INDEX  # Country database and lookup
│   ├── play_round                # Round orchestration
│   └── main                      # CLI flags and round loops
└── tests/
    └── test_country_letter_game.py  # Unit tests for normalization and lookup
```

## Development
- Run tests: `python3 -m unittest discover -s tests`
- Optional micro-benchmark (mirrors what we use before/after changes):
  ```bash
  python3 -m timeit -s "from country_letter_game import resolve_guess" "resolve_guess('Ivory Coast')"
  ```
- Data source: the `COUNTRIES` list contains all UN members plus a couple of common observer/short names; alternates are mapped via the `ALT` dictionary.

## License
No license has been specified yet. Add one if you plan to share or distribute the project.
