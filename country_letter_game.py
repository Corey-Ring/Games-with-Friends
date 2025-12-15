
import argparse
import json
import random
import re
import unicodedata
from pathlib import Path

SCORE_FILE = Path.home() / ".country_letter_game_scores.json"

def _norm(s: str) -> str:
    """Lowercase, strip accents, drop punctuation & extra spaces for robust matching."""
    if s is None:
        return ""
    s = s.lower().strip()
    s = unicodedata.normalize("NFKD", s)
    s = "".join(ch for ch in s if not unicodedata.combining(ch))
    s = re.sub(r"[^a-z0-9\s]", " ", s)   # remove punctuation/symbols
    s = re.sub(r"\s+", " ", s).strip()
    # drop leading 'the ' for inputs like 'the gambia', 'the bahamas'
    if s.startswith("the "):
        s = s[4:]
    return s

# Canonical common-English country names (193 UN members + 2 observers)
COUNTRIES = [
    "Afghanistan","Albania","Algeria","Andorra","Angola","Antigua and Barbuda","Argentina","Armenia",
    "Australia","Austria","Azerbaijan","Bahamas","Bahrain","Bangladesh","Barbados","Belarus","Belgium",
    "Belize","Benin","Bhutan","Bolivia","Bosnia and Herzegovina","Botswana","Brazil","Brunei","Bulgaria",
    "Burkina Faso","Burundi","Cabo Verde","Cambodia","Cameroon","Canada","Central African Republic","Chad",
    "Chile","China","Colombia","Comoros","Congo","Costa Rica","Côte d'Ivoire","Croatia","Cuba","Cyprus",
    "Czechia","Democratic Republic of the Congo","Denmark","Djibouti","Dominica","Dominican Republic",
    "Ecuador","Egypt","El Salvador","Equatorial Guinea","Eritrea","Estonia","Eswatini","Ethiopia","Fiji",
    "Finland","France","Gabon","Gambia","Georgia","Germany","Ghana","Greece","Grenada","Guatemala","Guinea",
    "Guinea-Bissau","Guyana","Haiti","Honduras","Hungary","Iceland","India","Indonesia","Iran","Iraq",
    "Ireland","Israel","Italy","Jamaica","Japan","Jordan","Kazakhstan","Kenya","Kiribati","North Korea",
    "South Korea","Kuwait","Kyrgyzstan","Laos","Latvia","Lebanon","Lesotho","Liberia","Libya",
    "Liechtenstein","Lithuania","Luxembourg","Madagascar","Malawi","Malaysia","Maldives","Mali","Malta",
    "Marshall Islands","Mauritania","Mauritius","Mexico","Micronesia","Moldova","Monaco","Mongolia",
    "Montenegro","Morocco","Mozambique","Myanmar","Namibia","Nauru","Nepal","Netherlands","New Zealand",
    "Nicaragua","Niger","Nigeria","North Macedonia","Norway","Oman","Pakistan","Palau","Palestine","Panama",
    "Papua New Guinea","Paraguay","Peru","Philippines","Poland","Portugal","Qatar","Romania","Russia",
    "Rwanda","Saint Kitts and Nevis","Saint Lucia","Saint Vincent and the Grenadines","Samoa","San Marino",
    "São Tomé and Príncipe","Saudi Arabia","Senegal","Serbia","Seychelles","Sierra Leone","Singapore",
    "Slovakia","Slovenia","Solomon Islands","Somalia","South Africa","South Sudan","Spain","Sri Lanka",
    "Sudan","Suriname","Sweden","Switzerland","Syria","Tajikistan","Tanzania","Thailand","Timor-Leste",
    "Togo","Tonga","Trinidad and Tobago","Tunisia","Turkey","Turkmenistan","Tuvalu","Uganda","Ukraine",
    "United Arab Emirates","United Kingdom","United States","Uruguay","Uzbekistan","Vanuatu","Vatican City",
    "Venezuela","Vietnam","Yemen","Zambia","Zimbabwe"
]

# Accept common alternate names -> canonical display name
ALT = {
    "ivory coast": "Côte d'Ivoire",
    "cote d ivoire": "Côte d'Ivoire",
    "cote d'ivoire": "Côte d'Ivoire",
    "cape verde": "Cabo Verde",
    "east timor": "Timor-Leste",
    "lao pdr": "Laos",
    "lao people s democratic republic": "Laos",
    "burma": "Myanmar",
    "swaziland": "Eswatini",
    "czech republic": "Czechia",
    "vatican": "Vatican City",
    "holy see": "Vatican City",
    "north korea": "North Korea",
    "democratic people s republic of korea": "North Korea",
    "south korea": "South Korea",
    "republic of korea": "South Korea",
    "the bahamas": "Bahamas",
    "the gambia": "Gambia",
    "republic of the congo": "Congo",
    "democratic republic of the congo": "Democratic Republic of the Congo",
    "bolivia plurinational state of": "Bolivia",
    "moldova republic of": "Moldova",
    "russian federation": "Russia",
    "syrian arab republic": "Syria",
    "united states of america": "United States",
    "u s a": "United States",
    "u s": "United States",
    "uk": "United Kingdom",
    "u k": "United Kingdom",
    "united kingdom of great britain and northern ireland": "United Kingdom",
    "myanmar burma": "Myanmar",
    "brunei darussalam": "Brunei",
    "iran islamic republic of": "Iran",
    "kyrgyz republic": "Kyrgyzstan",
    "lao": "Laos",
    "micronesia federated states of": "Micronesia",
    "palestine state of": "Palestine",
    "tanzania united republic of": "Tanzania",
    "venezuela bolivarian republic of": "Venezuela",
    "viet nam": "Vietnam",
    "timor leste": "Timor-Leste",
    "sao tome and principe": "São Tomé and Príncipe",
    "cabo verde": "Cabo Verde",  # allow without diacritics via _norm
    "eswatini kingdom of": "Eswatini",
}

CANON = { _norm(name): name for name in COUNTRIES }
# Merge ALT into the acceptance map, pointing to their canonical display
for alt, canon in ALT.items():
    CANON[_norm(alt)] = canon

# Build letter index from canonical (display) names
from collections import defaultdict

LETTER_INDEX = defaultdict(list)
for c in COUNTRIES:
    display = c
    first_char = display[0].upper()
    if first_char.isalpha():
        LETTER_INDEX[first_char].append(display)

for letter, names in list(LETTER_INDEX.items()):
    LETTER_INDEX[letter] = tuple(sorted(names))

LETTER_CHOICES = tuple(sorted(LETTER_INDEX.keys()))


def _safe_input(prompt: str) -> str | None:
    """Wrap built-in input to return None instead of raising on EOF."""
    try:
        return input(prompt)
    except EOFError:
        return None

def choose_letter() -> str:
    while True:
        user = _safe_input("Pick a letter (A-Z): ")
        if user is None:
            raise EOFError
        user = user.strip().upper()
        if len(user) == 1 and user.isalpha():
            if user in LETTER_INDEX:
                return user
            else:
                print(f"No countries start with '{user}'. Try another letter.")
        else:
            print("Please enter a single letter A-Z.")


def _print_help(letter: str, remaining_count: int):
    print(
        f"Commands: guess country names, 'hint' reveals part of a remaining country, "
        f"'status' shows progress, 'done' quits. Letter = {letter}, "
        f"{remaining_count} remaining."
    )


def _get_hint_level_reveal(country: str, hint_level: int) -> tuple[str, bool]:
    """
    Get the revealed portion of a country name based on hint level.
    hint_level is the number of hints already given (0 = first hint, 1 = second hint, etc.)
    Returns (revealed_string, is_fully_revealed).
    
    Hint progression:
    - Level 0 (first hint): First 3 letters
    - Level 1 (second hint): First 5 letters
    - Level 2 (third hint): First 7 letters
    - Level 3+: Add 2 more letters each time (9, 11, 13...)
    - When reach country_len - 1: Show all but last letter
    - Next: Full reveal
    """
    country_len = len(country)
    
    # Calculate how many letters to reveal
    if hint_level == 0:
        reveal_len = 3
    elif hint_level == 1:
        reveal_len = 5
    elif hint_level == 2:
        reveal_len = 7
    else:
        # Level 3+: 7 + (hint_level - 2) * 2
        reveal_len = 7 + (hint_level - 2) * 2
    
    # Determine what to show based on reveal_len and country length
    # We need to ensure "all but last" is shown before full reveal
    if reveal_len > country_len:
        # Fully revealed (we've already shown "all but last")
        return country, True
    elif reveal_len >= country_len - 1:
        # Show all but last letter
        # If reveal_len == country_len, we still show "all but last" first
        # The next hint will show the full country
        return country[:-1] + "_", False
    
    # Normal progressive reveal
    revealed = country[:reveal_len]
    obscured = revealed + "_" * (country_len - reveal_len)
    return obscured, False


def _show_progressive_hint(
    remaining: set[str],
    current_hinted: str | None,
    hint_levels: dict[str, int],
) -> tuple[str | None, dict[str, int], str | None]:
    """
    Show a progressive hint. Continue with current country if it exists and isn't fully revealed,
    otherwise pick a new random country.
    Returns (new_current_hinted, updated_hint_levels, given_up_country).
    given_up_country is the country name if it was fully revealed (should be marked as give up),
    None otherwise.
    """
    if not remaining:
        print("  💡 Nothing left to hint!")
        return None, hint_levels, None
    
    # If we have a current hinted country and it's still remaining
    if current_hinted and current_hinted in remaining:
        hint_level = hint_levels.get(current_hinted, 0)
        revealed, is_fully_revealed = _get_hint_level_reveal(current_hinted, hint_level)
        
        if is_fully_revealed:
            # This country is fully revealed, show it and mark as give up
            level_display = f" [Hint level {hint_level + 1}]" if hint_level > 0 else ""
            print(f"  💡 Hint: {revealed} ({len(current_hinted)} letters){level_display}")
            hint_levels[current_hinted] = hint_level + 1
            # Return the country name to mark it as given up
            return None, hint_levels, current_hinted
        else:
            # Continue with this country - show hint at current level, then increment
            level_display = f" [Hint level {hint_level + 1}]" if hint_level > 0 else ""
            print(f"  💡 Hint: {revealed} ({len(current_hinted)} letters){level_display}")
            hint_levels[current_hinted] = hint_level + 1
            return current_hinted, hint_levels, None
    
    # Pick a new random country
    current_hinted = random.choice(tuple(remaining))
    hint_level = hint_levels.get(current_hinted, 0)
    revealed, is_fully_revealed = _get_hint_level_reveal(current_hinted, hint_level)
    
    # Check if this new country is already fully revealed (shouldn't happen, but handle it)
    if is_fully_revealed:
        level_display = f" [Hint level {hint_level + 1}]" if hint_level > 0 else ""
        print(f"  💡 Hint: {revealed} ({len(current_hinted)} letters){level_display}")
        hint_levels[current_hinted] = hint_level + 1
        return None, hint_levels, current_hinted
    
    level_display = f" [Hint level {hint_level + 1}]" if hint_level > 0 else ""
    print(f"  💡 Hint: {revealed} ({len(current_hinted)} letters){level_display}")
    hint_levels[current_hinted] = hint_level + 1
    return current_hinted, hint_levels, None


def resolve_guess(raw: str) -> str | None:
    key = _norm(raw)
    if not key:
        return None
    # Direct normalized hit
    if key in CANON:
        return CANON[key]
    # Try some light heuristics for "the X" or extra spaces
    if key.startswith("the "):
        key2 = key[4:]
        if key2 in CANON:
            return CANON[key2]
    return None


def _resolve_letter_arg(letter_arg: str | None, random_letter: bool) -> str | None:
    """Return a validated letter choice derived from CLI flags."""
    if letter_arg and random_letter:
        raise ValueError("Choose either --letter or --random-letter, not both.")
    if random_letter:
        return random.choice(LETTER_CHOICES)
    if letter_arg:
        candidate = letter_arg.strip().upper()
        if len(candidate) != 1 or not candidate.isalpha():
            raise ValueError("--letter expects a single character A-Z.")
        if candidate not in LETTER_INDEX:
            raise ValueError(f"No countries start with '{candidate}'.")
        return candidate
    return None


def _load_scores(path: Path = SCORE_FILE) -> dict:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        if isinstance(data, dict):
            return data
    except FileNotFoundError:
        pass
    except (OSError, json.JSONDecodeError):
        pass
    return {}


def _save_scores(scores: dict, path: Path = SCORE_FILE) -> None:
    try:
        path.write_text(json.dumps(scores, indent=2, sort_keys=True), encoding="utf-8")
    except OSError:
        pass


def _announce_score(
    letter: str,
    found: int,
    total: int,
    scores: dict,
    improved: bool,
    prev_streak: int,
):
    def pct(value: float) -> int:
        return round(value * 100)

    letter_best = scores.get(letter)
    ratio = found / total if total else 0.0
    if improved:
        print(f"New personal best for {letter}: {pct(ratio)}% ({found}/{total}).")
    elif letter_best:
        best_ratio = letter_best.get("ratio", 0.0)
        print(
            f"Personal best for {letter}: {pct(best_ratio)}% "
            f"({letter_best.get('found', 0)}/{letter_best.get('total', total)})."
        )

    streak = scores.get("_perfect_streak", 0)
    if found == total and total:
        if streak == 1:
            print("Perfect streak: 1 round.")
        elif streak > 1:
            print(f"Perfect streak: {streak} rounds.")
    elif prev_streak:
        print("Perfect streak reset.")


def _record_score(letter: str, found: int, total: int, scores: dict):
    ratio = found / total if total else 0.0
    letter_best = scores.get(letter)
    improved = False
    if (
        not letter_best
        or ratio > letter_best.get("ratio", -1.0)
        or (
            ratio == letter_best.get("ratio", 0.0)
            and found > letter_best.get("found", -1)
        )
    ):
        scores[letter] = {"ratio": ratio, "found": found, "total": total}
        improved = True

    prev_streak = scores.get("_perfect_streak", 0)
    streak = prev_streak
    if total and found == total:
        streak += 1
    else:
        streak = 0
    scores["_perfect_streak"] = streak

    _save_scores(scores)
    _announce_score(letter, found, total, scores, improved, prev_streak)


def play_round(letter: str | None = None, scores: dict | None = None) -> tuple[int, int]:
    if letter is None:
        letter = choose_letter()
    targets = LETTER_INDEX[letter]
    remaining = set(targets)
    guessed = []
    give_ups = []
    hint_count = 0
    current_hinted_country: str | None = None
    hint_levels: dict[str, int] = {}

    print(f"\nYou picked '{letter}'. There are {len(targets)} countries starting with {letter}.")
    print("Start guessing! (Type 'done' when you want to stop.)\n")

    while remaining:
        guess = _safe_input("Your guess: ")
        if guess is None:
            break
        guess = guess.strip()
        if not guess:
            continue
        lowered = guess.lower()
        if lowered in {"done", "quit", "exit"}:
            break
        if lowered == "help":
            _print_help(letter, len(remaining))
            continue
        if lowered == "hint":
            if remaining:
                hint_count += 1
                current_hinted_country, hint_levels, given_up = _show_progressive_hint(
                    remaining, current_hinted_country, hint_levels
                )
                # If a country was fully revealed, mark it as a give up
                if given_up:
                    remaining.remove(given_up)
                    give_ups.append(given_up)
                    # Clear hint tracking for this country
                    if current_hinted_country == given_up:
                        current_hinted_country = None
                    if given_up in hint_levels:
                        del hint_levels[given_up]
                    print(f"  ⚠️  {given_up} marked as Give Up (fully revealed via hints)")
            continue
        if lowered == "status":
            base_score = (len(guessed) / len(targets) * 100) if targets else 0
            penalty = hint_count * 5
            final_score = max(0, round(base_score - penalty))
            print(f"  📊 Status:")
            print(f"     Countries guessed: {', '.join(sorted(guessed)) if guessed else '(none)'}")
            if give_ups:
                print(f"     Give ups: {', '.join(sorted(give_ups))}")
            print(f"     Remaining: {len(remaining)}")
            print(f"     Score: {final_score}% ({len(guessed)}/{len(targets)} found, {hint_count} hints used: -{penalty} points)")
            continue

        match = resolve_guess(guess)
        if match is None:
            print("  ✗ Not recognized. Try again.")
            continue

        if match[0].upper() != letter:
            print(f"  ✗ '{match}' doesn't start with {letter}. Keep going!")
            continue

        if match in remaining:
            remaining.remove(match)
            guessed.append(match)
            # Clear hint tracking for this country if it was being hinted
            if current_hinted_country == match:
                current_hinted_country = None
            if match in hint_levels:
                del hint_levels[match]
            print(f"  ✓ Correct! {len(guessed)}/{len(targets)} found.")
        else:
            print("  • Already got that one!")

    missed = sorted(remaining)
    base_score = (len(guessed) / len(targets) * 100) if targets else 0
    penalty = hint_count * 5
    final_score = max(0, round(base_score - penalty))
    
    print("\nRESULTS")
    print("-------")
    print(f"You found {len(guessed)} out of {len(targets)}.")
    if give_ups:
        print(f"Give ups: {len(give_ups)}")
        for g in sorted(give_ups):
            print(" - " + g)
    if hint_count > 0:
        print(f"Score: {final_score}% ({hint_count} hints used: -{penalty} points)")
    else:
        print(f"Score: {round(base_score)}%")
    if missed:
        print("You missed:")
        for m in missed:
            print(" - " + m)
    else:
        print("Perfect round — you got them all!")

    if scores is not None:
        _record_score(letter, len(guessed), len(targets), scores)

    return len(guessed), len(targets)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Country letter guessing game.")
    parser.add_argument(
        "--letter",
        help="Start directly with this letter (skips the letter prompt).",
    )
    parser.add_argument(
        "--random-letter",
        action="store_true",
        help="Pick a random starting letter that has at least one country.",
    )
    parser.add_argument(
        "--rounds",
        type=int,
        default=1,
        help="Number of rounds to play automatically (>=1).",
    )
    args = parser.parse_args(argv)

    scores = _load_scores()

    if args.rounds < 1:
        parser.error("--rounds must be >= 1.")

    try:
        initial_letter = _resolve_letter_arg(args.letter, args.random_letter)
    except ValueError as exc:
        parser.error(str(exc))

    for round_index in range(args.rounds):
        if args.random_letter:
            letter = random.choice(LETTER_CHOICES)
        elif round_index == 0:
            letter = initial_letter
        else:
            letter = None

        play_round(letter, scores)

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (KeyboardInterrupt, EOFError):
        print("\nGoodbye!")
