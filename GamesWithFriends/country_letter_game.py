
# Country Letter Guessing Game
# -------------------------------------------------------------
# Play: pick a letter, then guess every country that starts with it.aza
# Type "done" when you want to stop guessing.
#
# Notes:
# - Case-insensitive.
# - Ignores accents and punctuation (e.g., "Cote d Ivoire" is accepted).
# - Accepts common alternate names (e.g., "Ivory Coast" -> "Côte d'Ivoire").
# - Country canon list = UN members + a few widely-used short names + 2 observers.
# -------------------------------------------------------------

import re
import sys
import unicodedata

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

def choose_letter() -> str:
    while True:
        user = input("Pick a letter (A-Z): ").strip().upper()
        if len(user) == 1 and user.isalpha():
            if user in LETTER_INDEX:
                return user
            else:
                print(f"No countries start with '{user}'. Try another letter.")
        else:
            print("Please enter a single letter A-Z.")

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

def play_round():
    letter = choose_letter()
    targets = sorted(LETTER_INDEX[letter])
    remaining = set(targets)
    guessed = []

    print(f"\nYou picked '{letter}'. There are {len(targets)} countries starting with {letter}.")
    print("Start guessing! (Type 'done' when you want to stop.)\n")

    while remaining:
        guess = input("Your guess: ").strip()
        if not guess:
            continue
        if guess.lower() in {"done", "quit", "exit"}:
            break

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
            print(f"  ✓ Correct! {len(guessed)}/{len(targets)} found.")
        else:
            print("  • Already got that one!")

    missed = sorted(remaining)
    print("\nRESULTS")
    print("-------")
    print(f"You found {len(guessed)} out of {len(targets)}.")
    if missed:
        print("You missed:")
        for m in missed:
            print(" - " + m)
    else:
        print("Perfect round — you got them all!")

if __name__ == "__main__":
    try:
        play_round()
    except KeyboardInterrupt:
        print("\nGoodbye!")
