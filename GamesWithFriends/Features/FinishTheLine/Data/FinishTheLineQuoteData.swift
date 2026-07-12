//
//  FinishTheLineQuoteData.swift
//  GamesWithFriends
//
//  Curated content library for Finish the Line.
//
//  Curation rules (see FinishTheLine_PRD.md §5):
//  1. At least one person in the room will shout this.
//  2. Short-phrase fair use — hooks, catchphrases, punchlines only.
//  3. PG-13 ceiling — no profanity, no violence-glorifying quotes.
//  4. Every completion must be 1–4 spoken words, clearly recognizable by
//     the iOS Speech framework.
//  5. Alternates list common misspoken variants to keep fuzzy matching forgiving.
//
//  Distribution target (guidelines, not rigid):
//    Silver Screen 60 · Small Screen 40 · Animated 30 · Pitch Perfect 25
//    Songs & Jingles 20 · Storytime 15 · Play Time 10 → ~200 total
//    50% Easy · 35% Medium · 15% Hard
//

import Foundation

enum FinishTheLineQuoteData {

    static let allQuotes: [Quote] = silverScreen
        + smallScreen
        + animated
        + pitchPerfect
        + songsAndJingles
        + storytime
        + playTime

    // MARK: - Silver Screen

    static let silverScreen: [Quote] = [
        // Easy
        Quote(id: "sw-1977-force", setup: "May the force be ___ you", fullLine: "May the force be with you", missingWord: "with", alternates: ["with ya"], source: "Star Wars: A New Hope", category: .silverScreen, decade: .seventies, difficulty: .easy, blankPosition: .middle),
        Quote(id: "fg-1994-chocolates", setup: "Life is like a box of ___", fullLine: "Life is like a box of chocolates", missingWord: "chocolates", alternates: ["chocolate"], source: "Forrest Gump", category: .silverScreen, decade: .nineties, difficulty: .easy),
        Quote(id: "t-1984-back", setup: "I'll be ___", fullLine: "I'll be back", missingWord: "back", source: "The Terminator", category: .silverScreen, decade: .eighties, difficulty: .easy),
        Quote(id: "t2-1991-baby", setup: "Hasta la vista, ___", fullLine: "Hasta la vista, baby", missingWord: "baby", source: "Terminator 2", category: .silverScreen, decade: .nineties, difficulty: .easy),
        Quote(id: "jm-1996-money", setup: "Show me the ___!", fullLine: "Show me the money!", missingWord: "money", source: "Jerry Maguire", category: .silverScreen, decade: .nineties, difficulty: .easy),
        Quote(id: "wk-1939-toto", setup: "Toto, I've a feeling we're not in Kansas ___", fullLine: "Toto, I've a feeling we're not in Kansas anymore", missingWord: "anymore", alternates: ["any more"], source: "The Wizard of Oz", category: .silverScreen, decade: .timeless, difficulty: .easy),
        Quote(id: "jaws-1975-boat", setup: "You're gonna need a bigger ___", fullLine: "You're gonna need a bigger boat", missingWord: "boat", alternates: ["boat mate"], source: "Jaws", category: .silverScreen, decade: .seventies, difficulty: .easy),
        Quote(id: "et-1982-home", setup: "E.T. phone ___", fullLine: "E.T. phone home", missingWord: "home", source: "E.T. the Extra-Terrestrial", category: .silverScreen, decade: .eighties, difficulty: .easy),
        Quote(id: "tm-1986-speed", setup: "I feel the need, the need for ___", fullLine: "I feel the need, the need for speed", missingWord: "speed", source: "Top Gun", category: .silverScreen, decade: .eighties, difficulty: .easy),
        Quote(id: "rocky-1976-adrian", setup: "Yo, ___!", fullLine: "Yo, Adrian!", missingWord: "Adrian", alternates: ["adrienne"], source: "Rocky", category: .silverScreen, decade: .seventies, difficulty: .easy),
        Quote(id: "fn-1999-rule", setup: "The first rule of Fight Club is: you do not ___ about Fight Club", fullLine: "You do not talk about Fight Club", missingWord: "talk", alternates: ["talk about it"], source: "Fight Club", category: .silverScreen, decade: .nineties, difficulty: .easy, blankPosition: .middle),
        Quote(id: "shining-1980-johnny", setup: "Here's ___!", fullLine: "Here's Johnny!", missingWord: "Johnny", alternates: ["johnnie"], source: "The Shining", category: .silverScreen, decade: .eighties, difficulty: .easy),
        Quote(id: "tm-1986-maverick", setup: "Talk to me, ___", fullLine: "Talk to me, Goose", missingWord: "Goose", source: "Top Gun", category: .silverScreen, decade: .eighties, difficulty: .medium),
        Quote(id: "lotr-2001-shall", setup: "You shall not ___!", fullLine: "You shall not pass!", missingWord: "pass", source: "The Lord of the Rings: The Fellowship of the Ring", category: .silverScreen, decade: .twoThousands, difficulty: .easy),
        Quote(id: "dw-1989-build", setup: "If you build it, he will ___", fullLine: "If you build it, he will come", missingWord: "come", source: "Field of Dreams", category: .silverScreen, decade: .eighties, difficulty: .easy),
        Quote(id: "jp-1993-life", setup: "Life, uh, finds a ___", fullLine: "Life, uh, finds a way", missingWord: "way", source: "Jurassic Park", category: .silverScreen, decade: .nineties, difficulty: .easy),
        Quote(id: "pf-1994-royale", setup: "You know what a Frenchman calls a Quarter Pounder with Cheese? A Royale with ___", fullLine: "Royale with Cheese", missingWord: "cheese", source: "Pulp Fiction", category: .silverScreen, decade: .nineties, difficulty: .easy),
        Quote(id: "harry-2001-wizard", setup: "You're a wizard, ___", fullLine: "You're a wizard, Harry", missingWord: "Harry", alternates: ["harry potter"], source: "Harry Potter and the Sorcerer's Stone", category: .silverScreen, decade: .twoThousands, difficulty: .easy),
        Quote(id: "pc-2003-rum", setup: "Why is the rum always ___?", fullLine: "Why is the rum always gone?", missingWord: "gone", source: "Pirates of the Caribbean", category: .silverScreen, decade: .twoThousands, difficulty: .medium),
        Quote(id: "nv-2008-phonecall", setup: "I will look for you, I will find you, and I will ___ you", fullLine: "I will find you, and I will kill you", missingWord: "kill", source: "Taken", category: .silverScreen, decade: .twentyTens, difficulty: .medium),
        Quote(id: "av-2019-snap", setup: "I am ___", fullLine: "I am Iron Man", missingWord: "Iron Man", alternates: ["ironman", "iron man"], source: "Avengers: Endgame", category: .silverScreen, decade: .twentyTens, difficulty: .easy),
        Quote(id: "lb-1998-rug", setup: "That rug really tied the room ___", fullLine: "That rug really tied the room together", missingWord: "together", source: "The Big Lebowski", category: .silverScreen, decade: .nineties, difficulty: .hard),
        Quote(id: "bv-1995-freedom", setup: "They may take our lives, but they'll never take our ___!", fullLine: "They'll never take our freedom!", missingWord: "freedom", source: "Braveheart", category: .silverScreen, decade: .nineties, difficulty: .easy),
        Quote(id: "tits-1997-king", setup: "I'm the king of the ___!", fullLine: "I'm the king of the world!", missingWord: "world", source: "Titanic", category: .silverScreen, decade: .nineties, difficulty: .easy),
        Quote(id: "nd-2004-tots", setup: "Napoleon, give me some of your ___", fullLine: "Give me some of your tots", missingWord: "tots", alternates: ["tater tots"], source: "Napoleon Dynamite", category: .silverScreen, decade: .twoThousands, difficulty: .medium),
        Quote(id: "sr-2002-power", setup: "With great power comes great ___", fullLine: "With great power comes great responsibility", missingWord: "responsibility", source: "Spider-Man", category: .silverScreen, decade: .twoThousands, difficulty: .easy),
        Quote(id: "gb-1984-call", setup: "Who you gonna ___?", fullLine: "Who you gonna call?", missingWord: "call", source: "Ghostbusters", category: .silverScreen, decade: .eighties, difficulty: .easy),
        Quote(id: "bttf-1985-roads", setup: "Where we're going, we don't need ___", fullLine: "Where we're going, we don't need roads", missingWord: "roads", source: "Back to the Future", category: .silverScreen, decade: .eighties, difficulty: .easy),
        Quote(id: "fg-1994-run", setup: "Run, Forrest, ___!", fullLine: "Run, Forrest, run!", missingWord: "run", source: "Forrest Gump", category: .silverScreen, decade: .nineties, difficulty: .easy),
        Quote(id: "jb-1964-martini", setup: "Shaken, not ___", fullLine: "Shaken, not stirred", missingWord: "stirred", source: "James Bond", category: .silverScreen, decade: .timeless, difficulty: .easy),
        Quote(id: "kk-1984-wax", setup: "Wax on, wax ___", fullLine: "Wax on, wax off", missingWord: "off", alternates: ["wax off"], source: "The Karate Kid", category: .silverScreen, decade: .eighties, difficulty: .easy),

        // Medium
        Quote(id: "afgm-1992-truth", setup: "You can't handle the ___!", fullLine: "You can't handle the truth!", missingWord: "truth", source: "A Few Good Men", category: .silverScreen, decade: .nineties, difficulty: .medium),
        Quote(id: "cb-1942-kid", setup: "Here's looking at you, ___", fullLine: "Here's looking at you, kid", missingWord: "kid", source: "Casablanca", category: .silverScreen, decade: .timeless, difficulty: .medium),
        Quote(id: "dd-1987-corner", setup: "Nobody puts Baby in a ___", fullLine: "Nobody puts Baby in a corner", missingWord: "corner", source: "Dirty Dancing", category: .silverScreen, decade: .eighties, difficulty: .medium),
        Quote(id: "ss-1999-people", setup: "I see dead ___", fullLine: "I see dead people", missingWord: "people", source: "The Sixth Sense", category: .silverScreen, decade: .nineties, difficulty: .medium),
        Quote(id: "psy-1960-mother", setup: "A boy's best friend is his ___", fullLine: "A boy's best friend is his mother", missingWord: "mother", source: "Psycho", category: .silverScreen, decade: .timeless, difficulty: .medium),
        Quote(id: "gf-1972-refuse", setup: "I'm gonna make him an offer he can't ___", fullLine: "I'm gonna make him an offer he can't refuse", missingWord: "refuse", source: "The Godfather", category: .silverScreen, decade: .seventies, difficulty: .medium),
        Quote(id: "tn-1976-me", setup: "You talkin' to ___?", fullLine: "You talkin' to me?", missingWord: "me", source: "Taxi Driver", category: .silverScreen, decade: .seventies, difficulty: .medium),
        Quote(id: "tpb-1987-means", setup: "Inconceivable! That word — you keep using it. I do not think it means what you think it ___", fullLine: "I do not think it means what you think it means", missingWord: "means", source: "The Princess Bride", category: .silverScreen, decade: .eighties, difficulty: .medium),
        Quote(id: "tpb-1987-father", setup: "Hello. My name is Inigo Montoya. You killed my father. Prepare to ___", fullLine: "Prepare to die", missingWord: "die", source: "The Princess Bride", category: .silverScreen, decade: .eighties, difficulty: .medium),
        Quote(id: "db-1999-real", setup: "There is no ___", fullLine: "There is no spoon", missingWord: "spoon", source: "The Matrix", category: .silverScreen, decade: .nineties, difficulty: .medium),
        Quote(id: "gwh-1997-fault", setup: "It's not your ___", fullLine: "It's not your fault", missingWord: "fault", source: "Good Will Hunting", category: .silverScreen, decade: .nineties, difficulty: .medium),
        Quote(id: "apoc-1979-napalm", setup: "I love the smell of napalm in the ___", fullLine: "I love the smell of napalm in the morning", missingWord: "morning", source: "Apocalypse Now", category: .silverScreen, decade: .seventies, difficulty: .medium),
        Quote(id: "zl-2009-cardio", setup: "Rule number one: ___", fullLine: "Rule number one: cardio", missingWord: "cardio", source: "Zombieland", category: .silverScreen, decade: .twoThousands, difficulty: .medium),
        Quote(id: "jm-1996-hello", setup: "You had me at ___", fullLine: "You had me at hello", missingWord: "hello", source: "Jerry Maguire", category: .silverScreen, decade: .nineties, difficulty: .medium),
        Quote(id: "bs-1983-world", setup: "Say hello to my little ___", fullLine: "Say hello to my little friend", missingWord: "friend", source: "Scarface", category: .silverScreen, decade: .eighties, difficulty: .medium),
        Quote(id: "slih-1959-perfect", setup: "Nobody's ___", fullLine: "Nobody's perfect", missingWord: "perfect", source: "Some Like It Hot", category: .silverScreen, decade: .timeless, difficulty: .medium),
        Quote(id: "pm-1990-woman", setup: "Big mistake. Big. ___.", fullLine: "Big mistake. Big. Huge.", missingWord: "Huge", alternates: ["huge"], source: "Pretty Woman", category: .silverScreen, decade: .nineties, difficulty: .medium),
        Quote(id: "ca-1986-crocodile", setup: "That's not a knife. That's a ___", fullLine: "That's a knife", missingWord: "knife", source: "Crocodile Dundee", category: .silverScreen, decade: .eighties, difficulty: .medium),
        Quote(id: "lotr-2002-precious", setup: "My ___", fullLine: "My precious", missingWord: "precious", source: "The Lord of the Rings: The Two Towers", category: .silverScreen, decade: .twoThousands, difficulty: .medium),
        Quote(id: "a13-1995-houston", setup: "Houston, we have a ___", fullLine: "Houston, we have a problem", missingWord: "problem", source: "Apollo 13", category: .silverScreen, decade: .nineties, difficulty: .easy),
        Quote(id: "300-2006-sparta", setup: "This is ___!", fullLine: "This is Sparta!", missingWord: "Sparta", alternates: ["sparta"], source: "300", category: .silverScreen, decade: .twoThousands, difficulty: .easy),
        Quote(id: "ii-2010-dream", setup: "You mustn't be afraid to dream a little ___", fullLine: "Dream a little bigger, darling", missingWord: "bigger", source: "Inception", category: .silverScreen, decade: .twentyTens, difficulty: .medium),

        // Hard
        Quote(id: "ck-1941-rosebud", setup: "___", fullLine: "Rosebud", missingWord: "Rosebud", alternates: ["rose bud"], source: "Citizen Kane", category: .silverScreen, decade: .timeless, difficulty: .hard, blankPosition: .start),
        Quote(id: "ch-1974-forget", setup: "Forget it, Jake. It's ___", fullLine: "Forget it, Jake. It's Chinatown", missingWord: "Chinatown", alternates: ["china town"], source: "Chinatown", category: .silverScreen, decade: .seventies, difficulty: .hard),
        Quote(id: "aabs-1950-seatbelts", setup: "Fasten your seatbelts. It's going to be a bumpy ___", fullLine: "It's going to be a bumpy night", missingWord: "night", source: "All About Eve", category: .silverScreen, decade: .timeless, difficulty: .hard),
        Quote(id: "tg-1939-damn", setup: "Frankly, my dear, I don't give a ___", fullLine: "Frankly, my dear, I don't give a damn", missingWord: "damn", alternates: ["dang", "darn"], source: "Gone with the Wind", category: .silverScreen, decade: .timeless, difficulty: .medium),
        Quote(id: "whms-1989-having", setup: "I'll have what she's ___", fullLine: "I'll have what she's having", missingWord: "having", source: "When Harry Met Sally", category: .silverScreen, decade: .eighties, difficulty: .medium),
        Quote(id: "dk-2008-clown", setup: "Why so ___?", fullLine: "Why so serious?", missingWord: "serious", source: "The Dark Knight", category: .silverScreen, decade: .twoThousands, difficulty: .easy),
        Quote(id: "nbk-2007-old", setup: "What's the most you've ever lost on a coin ___?", fullLine: "What's the most you've ever lost on a coin toss?", missingWord: "toss", source: "No Country for Old Men", category: .silverScreen, decade: .twoThousands, difficulty: .hard),
        Quote(id: "tp-1976-mad", setup: "I'm as mad as hell, and I'm not going to take this ___!", fullLine: "I'm not going to take this anymore!", missingWord: "anymore", alternates: ["any more"], source: "Network", category: .silverScreen, decade: .seventies, difficulty: .hard),
    ]

    // MARK: - Small Screen

    static let smallScreen: [Quote] = [
        // Easy
        Quote(id: "fr-1994-doin", setup: "How you ___?", fullLine: "How you doin'?", missingWord: "doin", alternates: ["doing", "doin'"], source: "Friends", category: .smallScreen, decade: .nineties, difficulty: .easy),
        Quote(id: "got-2011-coming", setup: "Winter is ___", fullLine: "Winter is coming", missingWord: "coming", source: "Game of Thrones", category: .smallScreen, decade: .twentyTens, difficulty: .easy),
        Quote(id: "sp-1989-doh", setup: "___!", fullLine: "D'oh!", missingWord: "D'oh", alternates: ["doh", "duh"], source: "The Simpsons", category: .smallScreen, decade: .eighties, difficulty: .easy, blankPosition: .start),
        Quote(id: "ft-1960-doo", setup: "Yabba dabba ___!", fullLine: "Yabba dabba doo!", missingWord: "doo", alternates: ["do"], source: "The Flintstones", category: .smallScreen, decade: .timeless, difficulty: .easy),
        Quote(id: "wwm-1999-final", setup: "Is that your final ___?", fullLine: "Is that your final answer?", missingWord: "answer", alternates: ["final answer"], source: "Who Wants to Be a Millionaire", category: .smallScreen, decade: .twoThousands, difficulty: .easy),
        Quote(id: "seinfeld-1989-soup", setup: "No soup for ___!", fullLine: "No soup for you!", missingWord: "you", source: "Seinfeld", category: .smallScreen, decade: .nineties, difficulty: .easy),
        Quote(id: "tb-2007-bazinga", setup: "___!", fullLine: "Bazinga!", missingWord: "Bazinga", alternates: ["bazinga"], source: "The Big Bang Theory", category: .smallScreen, decade: .twoThousands, difficulty: .easy, blankPosition: .start),
        Quote(id: "seinfeld-1989-yada", setup: "Yada yada ___", fullLine: "Yada yada yada", missingWord: "yada", source: "Seinfeld", category: .smallScreen, decade: .nineties, difficulty: .easy),
        Quote(id: "poh-2001-survivor", setup: "The tribe has ___", fullLine: "The tribe has spoken", missingWord: "spoken", source: "Survivor", category: .smallScreen, decade: .twoThousands, difficulty: .easy),
        Quote(id: "ai-2002-dawg", setup: "For me, for you, dawg, that was a little pitchy, ___", fullLine: "A little pitchy, dawg", missingWord: "dawg", alternates: ["dog"], source: "American Idol", category: .smallScreen, decade: .twoThousands, difficulty: .medium),
        Quote(id: "sb-1999-ready", setup: "Are you ready, ___?", fullLine: "Are you ready, kids?", missingWord: "kids", source: "SpongeBob SquarePants", category: .smallScreen, decade: .nineties, difficulty: .easy),
        Quote(id: "bb-2008-danger", setup: "I am the ___", fullLine: "I am the danger", missingWord: "danger", source: "Breaking Bad", category: .smallScreen, decade: .twoThousands, difficulty: .medium),
        Quote(id: "sp-1997-killed", setup: "Oh my God, they killed ___!", fullLine: "They killed Kenny!", missingWord: "Kenny", alternates: ["kenny"], source: "South Park", category: .smallScreen, decade: .nineties, difficulty: .easy),
        Quote(id: "xf-1993-truth", setup: "The truth is out ___", fullLine: "The truth is out there", missingWord: "there", source: "The X-Files", category: .smallScreen, decade: .nineties, difficulty: .easy),
        Quote(id: "off-2005-identity", setup: "Bears. Beets. Battlestar ___", fullLine: "Battlestar Galactica", missingWord: "Galactica", alternates: ["galactica"], source: "The Office", category: .smallScreen, decade: .twoThousands, difficulty: .medium),
        Quote(id: "fr-1994-break", setup: "We were on a ___!", fullLine: "We were on a break!", missingWord: "break", source: "Friends", category: .smallScreen, decade: .nineties, difficulty: .easy),
        Quote(id: "snl-1975-live", setup: "Live from New York, it's Saturday ___!", fullLine: "Live from New York, it's Saturday Night!", missingWord: "Night", alternates: ["saturday night", "saturday night live"], source: "Saturday Night Live", category: .smallScreen, decade: .timeless, difficulty: .easy),
        Quote(id: "sb-1999-mayo", setup: "Is mayonnaise an ___?", fullLine: "Is mayonnaise an instrument?", missingWord: "instrument", source: "SpongeBob SquarePants", category: .smallScreen, decade: .nineties, difficulty: .medium),

        // Medium
        Quote(id: "bb-2008-knock", setup: "I am the one who ___", fullLine: "I am the one who knocks", missingWord: "knocks", source: "Breaking Bad", category: .smallScreen, decade: .twoThousands, difficulty: .medium),
        Quote(id: "fr-1994-lobster", setup: "She's your ___", fullLine: "She's your lobster", missingWord: "lobster", source: "Friends", category: .smallScreen, decade: .nineties, difficulty: .medium),
        Quote(id: "off-2005-submit", setup: "I declare ___!", fullLine: "I declare bankruptcy!", missingWord: "bankruptcy", source: "The Office", category: .smallScreen, decade: .twoThousands, difficulty: .medium),
        Quote(id: "hi-2005-wait", setup: "Legen — wait for it — ___", fullLine: "Legen — wait for it — dary", missingWord: "dary", alternates: ["dairy", "legendary"], source: "How I Met Your Mother", category: .smallScreen, decade: .twoThousands, difficulty: .medium),
        Quote(id: "fr-1995-smelly", setup: "Smelly ___, smelly ___, what are they feeding you?", fullLine: "Smelly cat, smelly cat, what are they feeding you?", missingWord: "cat", alternates: ["smelly cat"], source: "Friends", category: .smallScreen, decade: .nineties, difficulty: .easy, blankPosition: .middle),
        Quote(id: "tb-2007-rock", setup: "Rock, paper, scissors, lizard, ___", fullLine: "Rock, paper, scissors, lizard, Spock", missingWord: "Spock", alternates: ["spock"], source: "The Big Bang Theory", category: .smallScreen, decade: .twoThousands, difficulty: .medium),
        Quote(id: "bb-2012-name", setup: "Say my ___", fullLine: "Say my name", missingWord: "name", source: "Breaking Bad", category: .smallScreen, decade: .twentyTens, difficulty: .medium),
        Quote(id: "wl-2001-goodbye", setup: "You are the weakest link. ___!", fullLine: "You are the weakest link. Goodbye!", missingWord: "Goodbye", alternates: ["good bye"], source: "Weakest Link", category: .smallScreen, decade: .twoThousands, difficulty: .easy),
        Quote(id: "tp-1990-coffee", setup: "Damn fine cup of ___", fullLine: "Damn fine cup of coffee", missingWord: "coffee", source: "Twin Peaks", category: .smallScreen, decade: .nineties, difficulty: .medium),
        Quote(id: "bf-1993-bingo", setup: "Bingo was his ___", fullLine: "Bingo was his name-o", missingWord: "name-o", alternates: ["name o", "nameo", "name"], source: "Bingo (nursery rhyme)", category: .smallScreen, decade: .timeless, difficulty: .easy),
        Quote(id: "mr-1985-mister", setup: "Whatchu talkin' 'bout, ___?", fullLine: "Whatchu talkin' 'bout, Willis?", missingWord: "Willis", alternates: ["willis"], source: "Diff'rent Strokes", category: .smallScreen, decade: .eighties, difficulty: .medium),
        Quote(id: "off-2005-beet", setup: "Identity theft is not a ___", fullLine: "Identity theft is not a joke", missingWord: "joke", source: "The Office", category: .smallScreen, decade: .twoThousands, difficulty: .medium),
        Quote(id: "stg-2016-upside", setup: "Welcome to the ___ Down", fullLine: "Welcome to the Upside Down", missingWord: "Upside", alternates: ["upside"], source: "Stranger Things", category: .smallScreen, decade: .twentyTens, difficulty: .medium),
        Quote(id: "at-1983-fool", setup: "I pity the ___", fullLine: "I pity the fool", missingWord: "fool", source: "The A-Team (Mr. T)", category: .smallScreen, decade: .eighties, difficulty: .medium),
        Quote(id: "snl-1975-cowbell", setup: "I need more ___", fullLine: "I need more cowbell", missingWord: "cowbell", source: "Saturday Night Live", category: .smallScreen, decade: .timeless, difficulty: .medium),

        // Hard
        Quote(id: "st-1966-life", setup: "Live long and ___", fullLine: "Live long and prosper", missingWord: "prosper", source: "Star Trek", category: .smallScreen, decade: .timeless, difficulty: .easy),
        Quote(id: "sp-1970-expect", setup: "Nobody expects the Spanish ___", fullLine: "Nobody expects the Spanish Inquisition", missingWord: "Inquisition", alternates: ["inquisition"], source: "Monty Python's Flying Circus", category: .smallScreen, decade: .seventies, difficulty: .hard),
        Quote(id: "fra-1993-seattle", setup: "Goodnight, ___", fullLine: "Goodnight, Seattle", missingWord: "Seattle", alternates: ["seattle"], source: "Frasier", category: .smallScreen, decade: .nineties, difficulty: .hard),
        Quote(id: "cb-1982-drink", setup: "Where everybody knows your ___", fullLine: "Where everybody knows your name", missingWord: "name", source: "Cheers", category: .smallScreen, decade: .eighties, difficulty: .medium),
        Quote(id: "sf-1998-carrie", setup: "Hello, ___!", fullLine: "Hello, lover", missingWord: "lover", source: "Sex and the City", category: .smallScreen, decade: .nineties, difficulty: .hard),
        Quote(id: "off-2005-scranton", setup: "Bears eat ___", fullLine: "Bears eat beets", missingWord: "beets", alternates: ["beats"], source: "The Office", category: .smallScreen, decade: .twoThousands, difficulty: .medium),
    ]

    // MARK: - Animated

    static let animated: [Quote] = [
        Quote(id: "ts-1995-beyond", setup: "To infinity and ___!", fullLine: "To infinity and beyond!", missingWord: "beyond", source: "Toy Story", category: .animated, decade: .nineties, difficulty: .easy),
        Quote(id: "fn-2003-swim", setup: "Just keep ___", fullLine: "Just keep swimming", missingWord: "swimming", source: "Finding Nemo", category: .animated, decade: .twoThousands, difficulty: .easy),
        Quote(id: "lk-1994-matata", setup: "Hakuna ___", fullLine: "Hakuna matata", missingWord: "matata", alternates: ["ma tata", "matata!"], source: "The Lion King", category: .animated, decade: .nineties, difficulty: .easy),
        Quote(id: "fz-2013-letgo", setup: "Let it ___", fullLine: "Let it go", missingWord: "go", source: "Frozen", category: .animated, decade: .twentyTens, difficulty: .easy),
        Quote(id: "bb-1991-tale", setup: "Tale as old as ___", fullLine: "Tale as old as time", missingWord: "time", source: "Beauty and the Beast", category: .animated, decade: .nineties, difficulty: .easy),
        Quote(id: "al-1992-whole", setup: "A whole new ___", fullLine: "A whole new world", missingWord: "world", source: "Aladdin", category: .animated, decade: .nineties, difficulty: .easy),
        Quote(id: "lm-1989-part", setup: "I wanna be where the people ___", fullLine: "Where the people are", missingWord: "are", source: "The Little Mermaid", category: .animated, decade: .eighties, difficulty: .easy),
        Quote(id: "mi-2001-help", setup: "Put that thing back where it came from, or so help ___", fullLine: "Put that thing back where it came from, or so help me", missingWord: "me", alternates: ["so help me"], source: "Monsters, Inc.", category: .animated, decade: .twoThousands, difficulty: .medium),
        Quote(id: "up-2009-squirrel", setup: "___!", fullLine: "Squirrel!", missingWord: "Squirrel", alternates: ["squirrel"], source: "Up", category: .animated, decade: .twoThousands, difficulty: .easy, blankPosition: .start),
        Quote(id: "fz-2013-hugs", setup: "Hi, I'm Olaf and I like warm ___", fullLine: "I'm Olaf and I like warm hugs", missingWord: "hugs", alternates: ["hug", "warm hugs"], source: "Frozen", category: .animated, decade: .twentyTens, difficulty: .easy),
        Quote(id: "sk-2001-onion", setup: "Ogres are like ___", fullLine: "Ogres are like onions", missingWord: "onions", alternates: ["onion"], source: "Shrek", category: .animated, decade: .twoThousands, difficulty: .easy),
        Quote(id: "sk-2001-swamp", setup: "Get out of my ___!", fullLine: "Get out of my swamp!", missingWord: "swamp", source: "Shrek", category: .animated, decade: .twoThousands, difficulty: .easy),
        Quote(id: "moana-2016-far", setup: "How far I'll ___", fullLine: "How far I'll go", missingWord: "go", source: "Moana", category: .animated, decade: .twentyTens, difficulty: .easy),
        Quote(id: "en-2015-inside", setup: "Take her to the ___", fullLine: "Take her to the moon for me", missingWord: "moon", source: "Inside Out", category: .animated, decade: .twentyTens, difficulty: .medium),
        Quote(id: "lk-1994-kingdom", setup: "Everything the light touches is our ___", fullLine: "Everything the light touches is our kingdom", missingWord: "kingdom", source: "The Lion King", category: .animated, decade: .nineties, difficulty: .easy),
        Quote(id: "dm-2010-fluffy", setup: "It's so ___!", fullLine: "It's so fluffy!", missingWord: "fluffy", source: "Despicable Me", category: .animated, decade: .twentyTens, difficulty: .easy),
        Quote(id: "tan-2010-dream", setup: "I've got a ___", fullLine: "I've got a dream", missingWord: "dream", source: "Tangled", category: .animated, decade: .twentyTens, difficulty: .easy),
        Quote(id: "rtt-2007-cook", setup: "Anyone can ___", fullLine: "Anyone can cook", missingWord: "cook", source: "Ratatouille", category: .animated, decade: .twoThousands, difficulty: .medium),
        Quote(id: "bg-1998-honor", setup: "A girl worth fighting ___", fullLine: "A girl worth fighting for", missingWord: "for", source: "Mulan", category: .animated, decade: .nineties, difficulty: .medium),
        Quote(id: "inc-2004-normal", setup: "When everyone's super... ___ will be", fullLine: "When everyone's super, no one will be", missingWord: "no one", alternates: ["nobody"], source: "The Incredibles", category: .animated, decade: .twoThousands, difficulty: .medium, blankPosition: .middle),
        Quote(id: "kfp-2008-secret", setup: "There is no secret ___", fullLine: "There is no secret ingredient", missingWord: "ingredient", alternates: ["secret ingredient"], source: "Kung Fu Panda", category: .animated, decade: .twoThousands, difficulty: .medium),
        Quote(id: "lg-2014-awesome", setup: "Everything is ___!", fullLine: "Everything is awesome!", missingWord: "awesome", source: "The Lego Movie", category: .animated, decade: .twentyTens, difficulty: .easy),
        Quote(id: "lk-1994-king", setup: "Oh, I just can't wait to be ___", fullLine: "Oh, I just can't wait to be king", missingWord: "king", source: "The Lion King", category: .animated, decade: .nineties, difficulty: .easy),
        Quote(id: "ts-1995-sky", setup: "Reach for the ___!", fullLine: "Reach for the sky!", missingWord: "sky", source: "Toy Story", category: .animated, decade: .nineties, difficulty: .easy),
        Quote(id: "al-1992-wish", setup: "Your wish is my ___", fullLine: "Your wish is my command", missingWord: "command", source: "Aladdin", category: .animated, decade: .nineties, difficulty: .medium),
        Quote(id: "pin-1940-guide", setup: "Always let your conscience be your ___", fullLine: "Always let your conscience be your guide", missingWord: "guide", source: "Pinocchio", category: .animated, decade: .timeless, difficulty: .hard),
        Quote(id: "lk-1994-worries", setup: "It means no ___ for the rest of your days", fullLine: "It means no worries for the rest of your days", missingWord: "worries", alternates: ["no worries"], source: "The Lion King", category: .animated, decade: .nineties, difficulty: .easy, blankPosition: .middle),
        Quote(id: "pnf-2007-day", setup: "Hey, where's ___?", fullLine: "Hey, where's Perry?", missingWord: "Perry", alternates: ["perry", "ferry"], source: "Phineas and Ferb", category: .animated, decade: .twoThousands, difficulty: .medium),
        Quote(id: "bluey-2018-real", setup: "For real ___?", fullLine: "For real life?", missingWord: "life", alternates: ["real life", "for real life"], source: "Bluey", category: .animated, decade: .twentyTwenties, difficulty: .easy),
        Quote(id: "enc-2021-bruno", setup: "We don't talk about ___", fullLine: "We don't talk about Bruno", missingWord: "Bruno", alternates: ["bruno no no no"], source: "Encanto", category: .animated, decade: .twentyTwenties, difficulty: .easy),
    ]

    // MARK: - Pitch Perfect (slogans & taglines)

    static let pitchPerfect: [Quote] = [
        Quote(id: "nk-ads-it", setup: "Just do ___", fullLine: "Just do it", missingWord: "it", source: "Nike", category: .pitchPerfect, decade: .timeless, difficulty: .easy),
        Quote(id: "md-2003-lovin", setup: "I'm ___ it", fullLine: "I'm lovin' it", missingWord: "lovin", alternates: ["loving", "lovin'"], source: "McDonald's", category: .pitchPerfect, decade: .twoThousands, difficulty: .easy, blankPosition: .middle),
        Quote(id: "milk-1993-got", setup: "Got ___?", fullLine: "Got milk?", missingWord: "milk", source: "Got Milk? campaign", category: .pitchPerfect, decade: .nineties, difficulty: .easy),
        Quote(id: "lor-2003-worth", setup: "Because you're worth ___", fullLine: "Because you're worth it", missingWord: "it", source: "L'Oréal", category: .pitchPerfect, decade: .timeless, difficulty: .easy),
        Quote(id: "ap-1997-think", setup: "Think ___", fullLine: "Think different", missingWord: "different", source: "Apple", category: .pitchPerfect, decade: .nineties, difficulty: .easy),
        Quote(id: "mt-2008-priceless", setup: "For everything else, there's ___", fullLine: "For everything else, there's Mastercard", missingWord: "Mastercard", alternates: ["mastercard"], source: "MasterCard", category: .pitchPerfect, decade: .timeless, difficulty: .medium),
        Quote(id: "sb-1971-world", setup: "I'd like to buy the world a ___", fullLine: "I'd like to buy the world a Coke", missingWord: "Coke", alternates: ["coke"], source: "Coca-Cola", category: .pitchPerfect, decade: .seventies, difficulty: .medium),
        Quote(id: "dg-1995-diamonds", setup: "A diamond is ___", fullLine: "A diamond is forever", missingWord: "forever", source: "De Beers", category: .pitchPerfect, decade: .timeless, difficulty: .medium),
        Quote(id: "sb-2007-mmm", setup: "Finger lickin' ___", fullLine: "Finger lickin' good", missingWord: "good", source: "KFC", category: .pitchPerfect, decade: .timeless, difficulty: .easy),
        Quote(id: "vz-2002-now", setup: "Can you hear me ___?", fullLine: "Can you hear me now?", missingWord: "now", source: "Verizon", category: .pitchPerfect, decade: .twoThousands, difficulty: .medium),
        Quote(id: "skit-1985-rainbow", setup: "Taste the ___", fullLine: "Taste the rainbow", missingWord: "rainbow", source: "Skittles", category: .pitchPerfect, decade: .eighties, difficulty: .easy),
        Quote(id: "bud-1999-wassup", setup: "___?!", fullLine: "Wassup?!", missingWord: "Wassup", alternates: ["wassup", "whassup", "what's up", "whats up"], source: "Budweiser", category: .pitchPerfect, decade: .nineties, difficulty: .medium, blankPosition: .start),
        Quote(id: "sub-2000-fresh", setup: "Eat ___", fullLine: "Eat fresh", missingWord: "fresh", source: "Subway", category: .pitchPerfect, decade: .twoThousands, difficulty: .easy),
        Quote(id: "dp-2001-america", setup: "America runs on ___", fullLine: "America runs on Dunkin'", missingWord: "Dunkin", alternates: ["dunkin", "dunkin'", "duncan"], source: "Dunkin' Donuts", category: .pitchPerfect, decade: .twoThousands, difficulty: .medium),
        Quote(id: "mb-2000-best", setup: "Melts in your mouth, not in your ___", fullLine: "Not in your hands", missingWord: "hands", alternates: ["hand"], source: "M&M's", category: .pitchPerfect, decade: .timeless, difficulty: .medium),
        Quote(id: "reb-2000-rise", setup: "Red Bull gives you ___", fullLine: "Red Bull gives you wings", missingWord: "wings", alternates: ["wing"], source: "Red Bull", category: .pitchPerfect, decade: .twoThousands, difficulty: .easy),
        Quote(id: "snk-2010-hungry", setup: "You're not you when you're ___", fullLine: "You're not you when you're hungry", missingWord: "hungry", source: "Snickers", category: .pitchPerfect, decade: .twentyTens, difficulty: .medium),
        Quote(id: "toys-1980-kid", setup: "I don't wanna grow up, I'm a ___ kid", fullLine: "I'm a Toys R Us kid", missingWord: "Toys R Us", alternates: ["toys r us", "toys are us"], source: "Toys R Us", category: .pitchPerfect, decade: .eighties, difficulty: .medium),
        Quote(id: "whats-1984-beef", setup: "Where's the ___?", fullLine: "Where's the beef?", missingWord: "beef", source: "Wendy's", category: .pitchPerfect, decade: .eighties, difficulty: .medium),
        Quote(id: "plop-1953-fizz", setup: "Plop, plop, fizz, ___", fullLine: "Plop, plop, fizz, fizz", missingWord: "fizz", source: "Alka-Seltzer", category: .pitchPerfect, decade: .timeless, difficulty: .hard),
        Quote(id: "ml-1955-please", setup: "I'm cuckoo for ___ Puffs!", fullLine: "Cuckoo for Cocoa Puffs", missingWord: "Cocoa", alternates: ["cocoa"], source: "Cocoa Puffs", category: .pitchPerfect, decade: .timeless, difficulty: .easy),
        Quote(id: "hb-1985-hb", setup: "Have it your ___", fullLine: "Have it your way", missingWord: "way", source: "Burger King", category: .pitchPerfect, decade: .eighties, difficulty: .easy),
        Quote(id: "dsvl-1970-dm", setup: "Don't leave home without ___", fullLine: "Don't leave home without it", missingWord: "it", source: "American Express", category: .pitchPerfect, decade: .seventies, difficulty: .medium),
        Quote(id: "bnd-1980-pt", setup: "The best a man can ___", fullLine: "The best a man can get", missingWord: "get", source: "Gillette", category: .pitchPerfect, decade: .eighties, difficulty: .medium),
        Quote(id: "eb-1985-eb", setup: "Tony the Tiger says they're ___!", fullLine: "They're grrreat!", missingWord: "great", alternates: ["grrreat"], source: "Frosted Flakes (Tony the Tiger)", category: .pitchPerfect, decade: .timeless, difficulty: .easy),
    ]

    // MARK: - Songs & Jingles

    static let songsAndJingles: [Quote] = [
        Quote(id: "abba-1976-dancing", setup: "You can dance, you can jive, having the time of your ___", fullLine: "Time of your life", missingWord: "life", source: "ABBA — Dancing Queen", category: .songsAndJingles, decade: .seventies, difficulty: .medium),
        Quote(id: "q-1975-bohemian", setup: "Is this the real life, is this just ___?", fullLine: "Is this just fantasy?", missingWord: "fantasy", source: "Queen — Bohemian Rhapsody", category: .songsAndJingles, decade: .seventies, difficulty: .easy),
        Quote(id: "bj-1983-billie", setup: "Billie Jean is not my ___", fullLine: "Billie Jean is not my lover", missingWord: "lover", source: "Michael Jackson — Billie Jean", category: .songsAndJingles, decade: .eighties, difficulty: .easy),
        Quote(id: "jt-1982-eye", setup: "It's the eye of the ___", fullLine: "Eye of the tiger", missingWord: "tiger", source: "Survivor — Eye of the Tiger", category: .songsAndJingles, decade: .eighties, difficulty: .easy),
        Quote(id: "ws-1981-dont", setup: "Don't stop ___", fullLine: "Don't stop believin'", missingWord: "believin", alternates: ["believing", "believin'"], source: "Journey — Don't Stop Believin'", category: .songsAndJingles, decade: .eighties, difficulty: .easy),
        Quote(id: "ni-1991-spirit", setup: "Smells like ___ spirit", fullLine: "Smells like teen spirit", missingWord: "teen", source: "Nirvana — Smells Like Teen Spirit", category: .songsAndJingles, decade: .nineties, difficulty: .easy),
        Quote(id: "sp-1998-hit", setup: "Hit me, baby, one more ___", fullLine: "Hit me baby one more time", missingWord: "time", source: "Britney Spears — Baby One More Time", category: .songsAndJingles, decade: .nineties, difficulty: .easy),
        Quote(id: "bs-1984-born", setup: "Born in the ___", fullLine: "Born in the USA", missingWord: "USA", alternates: ["U.S.A.", "usa"], source: "Bruce Springsteen — Born in the U.S.A.", category: .songsAndJingles, decade: .eighties, difficulty: .easy),
        Quote(id: "wm-1988-gonna", setup: "Never gonna give you ___", fullLine: "Never gonna give you up", missingWord: "up", source: "Rick Astley — Never Gonna Give You Up", category: .songsAndJingles, decade: .eighties, difficulty: .easy),
        Quote(id: "sc-1969-caroline", setup: "Sweet Caroline, ___", fullLine: "Sweet Caroline, bum bum bum", missingWord: "bum bum bum", alternates: ["bum bum", "ba ba ba", "ba ba"], source: "Neil Diamond — Sweet Caroline", category: .songsAndJingles, decade: .timeless, difficulty: .medium),
        Quote(id: "bb-2006-sexy", setup: "I'm bringing sexy ___", fullLine: "I'm bringing sexy back", missingWord: "back", source: "Justin Timberlake — SexyBack", category: .songsAndJingles, decade: .twoThousands, difficulty: .easy),
        Quote(id: "wh-1992-love", setup: "And I will always love ___", fullLine: "And I will always love you", missingWord: "you", source: "Whitney Houston — I Will Always Love You", category: .songsAndJingles, decade: .nineties, difficulty: .easy),
        Quote(id: "ts-2014-haters", setup: "'Cause the players gonna play, and the haters gonna ___", fullLine: "And the haters gonna hate", missingWord: "hate", alternates: ["hate hate hate", "hate hate hate hate hate"], source: "Taylor Swift — Shake It Off", category: .songsAndJingles, decade: .twentyTens, difficulty: .easy),
        Quote(id: "lz-1971-heaven", setup: "There's a lady who's sure all that glitters is ___", fullLine: "All that glitters is gold", missingWord: "gold", source: "Led Zeppelin — Stairway to Heaven", category: .songsAndJingles, decade: .seventies, difficulty: .medium),
        Quote(id: "ab-1974-waterloo", setup: "My my, at Waterloo Napoleon did ___", fullLine: "Napoleon did surrender", missingWord: "surrender", source: "ABBA — Waterloo", category: .songsAndJingles, decade: .seventies, difficulty: .hard),
        Quote(id: "kw-2004-gold", setup: "She take my money, when I'm in ___", fullLine: "When I'm in need", missingWord: "need", source: "Kanye West — Gold Digger", category: .songsAndJingles, decade: .twoThousands, difficulty: .medium),
        Quote(id: "bm-2000-dogs", setup: "Who let the dogs ___?", fullLine: "Who let the dogs out?", missingWord: "out", source: "Baha Men — Who Let the Dogs Out", category: .songsAndJingles, decade: .twoThousands, difficulty: .easy),
        Quote(id: "ad-2015-hello", setup: "Hello from the other ___", fullLine: "Hello from the other side", missingWord: "side", alternates: ["other side"], source: "Adele — Hello", category: .songsAndJingles, decade: .twentyTens, difficulty: .easy),
        Quote(id: "lg-2009-romance", setup: "Caught in a bad ___", fullLine: "Caught in a bad romance", missingWord: "romance", alternates: ["bad romance"], source: "Lady Gaga — Bad Romance", category: .songsAndJingles, decade: .twentyTens, difficulty: .medium),
        Quote(id: "mc-2014-uptown", setup: "Uptown ___ you up", fullLine: "Uptown funk you up", missingWord: "funk", source: "Mark Ronson — Uptown Funk", category: .songsAndJingles, decade: .twentyTens, difficulty: .easy),
        Quote(id: "rpj-1984-ghost", setup: "I ain't afraid of no ___", fullLine: "I ain't afraid of no ghost", missingWord: "ghost", alternates: ["ghosts"], source: "Ray Parker Jr. — Ghostbusters", category: .songsAndJingles, decade: .eighties, difficulty: .easy),
    ]

    // MARK: - Storytime (Literary)

    static let storytime: [Quote] = [
        Quote(id: "md-ishmael", setup: "Call me ___", fullLine: "Call me Ishmael", missingWord: "Ishmael", alternates: ["ishmael", "ishmeal"], source: "Moby Dick — Herman Melville", category: .storytime, decade: .timeless, difficulty: .medium),
        Quote(id: "tott-times", setup: "It was the best of times, it was the worst of ___", fullLine: "It was the worst of times", missingWord: "times", source: "A Tale of Two Cities — Charles Dickens", category: .storytime, decade: .timeless, difficulty: .easy),
        Quote(id: "pp-1813-truth", setup: "It is a truth universally ___", fullLine: "It is a truth universally acknowledged", missingWord: "acknowledged", source: "Pride and Prejudice — Jane Austen", category: .storytime, decade: .timeless, difficulty: .hard),
        Quote(id: "1984-orwell", setup: "Big Brother is watching ___", fullLine: "Big Brother is watching you", missingWord: "you", source: "1984 — George Orwell", category: .storytime, decade: .timeless, difficulty: .easy),
        Quote(id: "ana-1877-happy", setup: "All happy families are alike; each unhappy family is unhappy in its own ___", fullLine: "In its own way", missingWord: "way", source: "Anna Karenina — Leo Tolstoy", category: .storytime, decade: .timeless, difficulty: .hard),
        Quote(id: "c-1951-ear", setup: "If you really want to hear about it, the first thing you'll probably want to know is where I was ___", fullLine: "Where I was born", missingWord: "born", source: "The Catcher in the Rye — J.D. Salinger", category: .storytime, decade: .timeless, difficulty: .hard),
        Quote(id: "ra-1845-nevermore", setup: "Quoth the Raven, ___", fullLine: "Quoth the Raven, Nevermore", missingWord: "Nevermore", alternates: ["nevermore", "never more"], source: "The Raven — Edgar Allan Poe", category: .storytime, decade: .timeless, difficulty: .medium),
        Quote(id: "hm-1938-last", setup: "Last night I dreamt I went to ___ again", fullLine: "Last night I dreamt I went to Manderley again", missingWord: "Manderley", alternates: ["manderley", "manderlee"], source: "Rebecca — Daphne du Maurier", category: .storytime, decade: .timeless, difficulty: .hard),
        Quote(id: "goj-word", setup: "In the beginning was the ___", fullLine: "In the beginning was the Word", missingWord: "Word", alternates: ["word"], source: "The Gospel of John", category: .storytime, decade: .timeless, difficulty: .medium),
        Quote(id: "p-1902-dust", setup: "All children, except one, grow ___", fullLine: "All children, except one, grow up", missingWord: "up", source: "Peter Pan — J.M. Barrie", category: .storytime, decade: .timeless, difficulty: .hard),
        Quote(id: "ds-1960-ham", setup: "I do not like green eggs and ___", fullLine: "I do not like green eggs and ham", missingWord: "ham", alternates: ["green eggs and ham"], source: "Green Eggs and Ham — Dr. Seuss", category: .storytime, decade: .timeless, difficulty: .easy),
        Quote(id: "gb-1925-green", setup: "So we beat on, boats against the current, borne back ceaselessly into the ___", fullLine: "Borne back ceaselessly into the past", missingWord: "past", source: "The Great Gatsby — F. Scott Fitzgerald", category: .storytime, decade: .timeless, difficulty: .hard),
        Quote(id: "h-1937-hole", setup: "In a hole in the ground there lived a ___", fullLine: "In a hole in the ground there lived a hobbit", missingWord: "hobbit", source: "The Hobbit — J.R.R. Tolkien", category: .storytime, decade: .timeless, difficulty: .medium),
        Quote(id: "ch-1952-web", setup: "Some ___", fullLine: "Some pig", missingWord: "pig", source: "Charlotte's Web — E.B. White", category: .storytime, decade: .timeless, difficulty: .medium),
    ]

    // MARK: - Play Time (Video Games)

    static let playTime: [Quote] = [
        Quote(id: "zl-1986-alone", setup: "It's dangerous to go ___", fullLine: "It's dangerous to go alone", missingWord: "alone", source: "The Legend of Zelda", category: .playTime, decade: .eighties, difficulty: .easy),
        Quote(id: "pr-2007-lie", setup: "The cake is a ___", fullLine: "The cake is a lie", missingWord: "lie", source: "Portal", category: .playTime, decade: .twoThousands, difficulty: .easy),
        Quote(id: "mk-1992-him", setup: "Finish ___!", fullLine: "Finish him!", missingWord: "him", source: "Mortal Kombat", category: .playTime, decade: .nineties, difficulty: .easy),
        Quote(id: "sm-1985-castle", setup: "Thank you, Mario! But our princess is in another ___", fullLine: "Our princess is in another castle", missingWord: "castle", source: "Super Mario Bros.", category: .playTime, decade: .eighties, difficulty: .medium),
        Quote(id: "mgs-1998-snake", setup: "Snake? ___? SNAAAAAKE!", fullLine: "Snake? Snake? SNAAAAAKE!", missingWord: "Snake", alternates: ["snake"], source: "Metal Gear Solid", category: .playTime, decade: .nineties, difficulty: .medium),
        Quote(id: "sf64-1997-barrel", setup: "Do a barrel ___!", fullLine: "Do a barrel roll!", missingWord: "roll", alternates: ["barrel roll"], source: "Star Fox 64", category: .playTime, decade: .nineties, difficulty: .medium),
        Quote(id: "sa-1991-sanic", setup: "Gotta go ___!", fullLine: "Gotta go fast!", missingWord: "fast", source: "Sonic the Hedgehog", category: .playTime, decade: .nineties, difficulty: .easy),
        Quote(id: "sm64-1996-mario", setup: "It's-a me, ___!", fullLine: "It's-a me, Mario!", missingWord: "Mario", alternates: ["mario"], source: "Super Mario 64", category: .playTime, decade: .nineties, difficulty: .easy),
        Quote(id: "po-1996-catch", setup: "Gotta catch 'em ___", fullLine: "Gotta catch 'em all", missingWord: "all", source: "Pokémon", category: .playTime, decade: .nineties, difficulty: .easy),
        Quote(id: "fo-1997-war", setup: "War. War never ___", fullLine: "War never changes", missingWord: "changes", source: "Fallout", category: .playTime, decade: .nineties, difficulty: .medium),
    ]
}
