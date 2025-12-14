import Foundation

class ConversationStarterData {
    static let allStarters: [ConversationStarter] = [
        // VIBE LEVEL 1 - Icebreaker
        ConversationStarter(text: "Would you rather have the ability to speak all languages or play all musical instruments?", vibeLevel: 1, category: .wouldYouRather),
        ConversationStarter(text: "Coffee is overrated", vibeLevel: 1, category: .hotTakes),
        ConversationStarter(text: "If you could have dinner with any historical figure, who would it be?", vibeLevel: 1, category: .hypotheticals),
        ConversationStarter(text: "Share about a time you learned something new at work", vibeLevel: 1, category: .storyTime),
        ConversationStarter(text: "Morning person or night owl?", vibeLevel: 1, category: .thisOrThat),
        ConversationStarter(text: "Beach vacation or mountain retreat?", vibeLevel: 1, category: .thisOrThat),
        ConversationStarter(text: "What's a skill you'd like to learn in the next year?", vibeLevel: 1, category: .deepDive),

        // VIBE LEVEL 2 - Casual
        ConversationStarter(text: "Would you rather always be 10 minutes late or 20 minutes early?", vibeLevel: 2, category: .wouldYouRather),
        ConversationStarter(text: "Pineapple belongs on pizza", vibeLevel: 2, category: .hotTakes),
        ConversationStarter(text: "If you could master any hobby instantly, what would you choose?", vibeLevel: 2, category: .hypotheticals),
        ConversationStarter(text: "Tell us about your most memorable vacation", vibeLevel: 2, category: .storyTime),
        ConversationStarter(text: "Dogs or cats?", vibeLevel: 2, category: .thisOrThat),
        ConversationStarter(text: "What's something small that always makes you happy?", vibeLevel: 2, category: .deepDive),
        ConversationStarter(text: "Netflix binge or movie marathon?", vibeLevel: 2, category: .thisOrThat),

        // VIBE LEVEL 3 - Fun
        ConversationStarter(text: "Would you rather fight 100 duck-sized horses or 1 horse-sized duck?", vibeLevel: 3, category: .wouldYouRather),
        ConversationStarter(text: "Reality TV is actually quality entertainment", vibeLevel: 3, category: .hotTakes),
        ConversationStarter(text: "If you could swap lives with anyone for a day, who would it be and why?", vibeLevel: 3, category: .hypotheticals),
        ConversationStarter(text: "What's the most embarrassing thing that happened to you in school?", vibeLevel: 3, category: .storyTime),
        ConversationStarter(text: "Time travel to the past or future?", vibeLevel: 3, category: .thisOrThat),
        ConversationStarter(text: "What's a belief you had as a child that you later realized was wrong?", vibeLevel: 3, category: .deepDive),
        ConversationStarter(text: "Invisibility or ability to fly?", vibeLevel: 3, category: .wouldYouRather),

        // VIBE LEVEL 4 - Spicy
        ConversationStarter(text: "Would you rather know how you die or when you die?", vibeLevel: 4, category: .wouldYouRather),
        ConversationStarter(text: "Social media has made us worse communicators", vibeLevel: 4, category: .hotTakes),
        ConversationStarter(text: "If you could read minds but never turn it off, would you want to?", vibeLevel: 4, category: .hypotheticals),
        ConversationStarter(text: "Share a time when you stood up for something you believed in", vibeLevel: 4, category: .storyTime),
        ConversationStarter(text: "Brutal honesty or white lies to protect feelings?", vibeLevel: 4, category: .thisOrThat),
        ConversationStarter(text: "What's something about yourself that most people misunderstand?", vibeLevel: 4, category: .deepDive),
        ConversationStarter(text: "What's a opinion you have that would surprise people who know you?", vibeLevel: 4, category: .deepDive),

        // VIBE LEVEL 5 - Wild
        ConversationStarter(text: "Would you rather be famous but hated or unknown but loved by those close to you?", vibeLevel: 5, category: .wouldYouRather),
        ConversationStarter(text: "We should bring back dueling as a way to settle arguments", vibeLevel: 5, category: .hotTakes),
        ConversationStarter(text: "If you had to delete all but 3 apps from your phone, which would you keep?", vibeLevel: 5, category: .hypotheticals),
        ConversationStarter(text: "What's the wildest thing you've ever done on impulse?", vibeLevel: 5, category: .storyTime),
        ConversationStarter(text: "Live in a world with no music or no movies?", vibeLevel: 5, category: .thisOrThat),
        ConversationStarter(text: "What's a secret you've kept that you've never told anyone?", vibeLevel: 5, category: .deepDive),
        ConversationStarter(text: "If you could eliminate one thing from existence, what would it be?", vibeLevel: 5, category: .hypotheticals),

        // THANKSGIVING themed
        ConversationStarter(text: "Would you rather host Thanksgiving or be a guest?", vibeLevel: 2, category: .wouldYouRather, themes: [.thanksgiving]),
        ConversationStarter(text: "What family tradition are you most grateful for?", vibeLevel: 2, category: .deepDive, themes: [.thanksgiving]),
        ConversationStarter(text: "Share your most memorable Thanksgiving moment", vibeLevel: 2, category: .storyTime, themes: [.thanksgiving]),
        ConversationStarter(text: "Mashed potatoes or sweet potato casserole?", vibeLevel: 1, category: .thisOrThat, themes: [.thanksgiving]),

        // HALLOWEEN themed
        ConversationStarter(text: "Would you rather spend the night in a haunted house or a cemetery?", vibeLevel: 3, category: .wouldYouRather, themes: [.halloween]),
        ConversationStarter(text: "Candy corn is actually good", vibeLevel: 2, category: .hotTakes, themes: [.halloween]),
        ConversationStarter(text: "Share your scariest Halloween experience", vibeLevel: 3, category: .storyTime, themes: [.halloween]),
        ConversationStarter(text: "Trick or treat?", vibeLevel: 1, category: .thisOrThat, themes: [.halloween]),

        // WINTER HOLIDAYS themed
        ConversationStarter(text: "Would you rather have it snow every day in December or never snow at all?", vibeLevel: 2, category: .wouldYouRather, themes: [.winterHolidays]),
        ConversationStarter(text: "What's your favorite holiday tradition?", vibeLevel: 2, category: .deepDive, themes: [.winterHolidays]),
        ConversationStarter(text: "Real Christmas tree or artificial?", vibeLevel: 1, category: .thisOrThat, themes: [.winterHolidays]),
        ConversationStarter(text: "Share your most memorable holiday gift", vibeLevel: 2, category: .storyTime, themes: [.winterHolidays]),

        // NEW YEAR themed
        ConversationStarter(text: "Would you rather relive the past year or skip ahead to next year?", vibeLevel: 3, category: .wouldYouRather, themes: [.newYear]),
        ConversationStarter(text: "New Year's resolutions are pointless", vibeLevel: 2, category: .hotTakes, themes: [.newYear]),
        ConversationStarter(text: "What's one thing you want to accomplish in the new year?", vibeLevel: 2, category: .deepDive, themes: [.newYear]),

        // VALENTINE'S DAY themed
        ConversationStarter(text: "Would you rather have a romantic dinner at home or at a fancy restaurant?", vibeLevel: 2, category: .wouldYouRather, themes: [.valentines]),
        ConversationStarter(text: "Valentine's Day is just a commercial holiday", vibeLevel: 2, category: .hotTakes, themes: [.valentines]),
        ConversationStarter(text: "Share your most memorable date", vibeLevel: 3, category: .storyTime, themes: [.valentines]),
        ConversationStarter(text: "Chocolates or flowers?", vibeLevel: 1, category: .thisOrThat, themes: [.valentines]),

        // SUMMER themed
        ConversationStarter(text: "Would you rather spend summer at the beach or exploring a new city?", vibeLevel: 2, category: .wouldYouRather, themes: [.summer]),
        ConversationStarter(text: "Summer is the best season", vibeLevel: 2, category: .hotTakes, themes: [.summer]),
        ConversationStarter(text: "Share your best summer adventure", vibeLevel: 2, category: .storyTime, themes: [.summer]),
        ConversationStarter(text: "Pool or ocean?", vibeLevel: 1, category: .thisOrThat, themes: [.summer]),

        // BACK TO SCHOOL themed
        ConversationStarter(text: "Would you rather go back to high school or relive your college years?", vibeLevel: 3, category: .wouldYouRather, themes: [.backToSchool]),
        ConversationStarter(text: "School was the best time of my life", vibeLevel: 3, category: .hotTakes, themes: [.backToSchool]),
        ConversationStarter(text: "Share your most memorable school moment", vibeLevel: 2, category: .storyTime, themes: [.backToSchool]),

        // More variety across all levels
        ConversationStarter(text: "Would you rather always have to sing instead of speak or dance everywhere you go?", vibeLevel: 3, category: .wouldYouRather),
        ConversationStarter(text: "If you could have any superpower but it only works on Tuesdays, what would it be?", vibeLevel: 3, category: .hypotheticals),
        ConversationStarter(text: "Cereal is a soup", vibeLevel: 3, category: .hotTakes),
        ConversationStarter(text: "What's the weirdest food combination you actually enjoy?", vibeLevel: 2, category: .storyTime),
        ConversationStarter(text: "Would you rather have unlimited battery life on all devices or free WiFi everywhere?", vibeLevel: 2, category: .wouldYouRather),
        ConversationStarter(text: "Texting or phone calls?", vibeLevel: 2, category: .thisOrThat),
        ConversationStarter(text: "What accomplishment are you most proud of?", vibeLevel: 3, category: .deepDive),
        ConversationStarter(text: "If you could undo one decision from your past, would you?", vibeLevel: 4, category: .deepDive),
        ConversationStarter(text: "Would you rather know all the mysteries of the universe or have unlimited wealth?", vibeLevel: 4, category: .wouldYouRather),
        ConversationStarter(text: "Aliens definitely exist and have visited Earth", vibeLevel: 3, category: .hotTakes),
        ConversationStarter(text: "If you could live in any fictional universe, which would you choose?", vibeLevel: 3, category: .hypotheticals),
        ConversationStarter(text: "Early bird gets the worm or slow and steady wins the race?", vibeLevel: 2, category: .thisOrThat),
        ConversationStarter(text: "Share a time when you failed but learned something valuable", vibeLevel: 3, category: .storyTime),
        ConversationStarter(text: "Would you rather be able to teleport or time travel?", vibeLevel: 3, category: .wouldYouRather),
        ConversationStarter(text: "Money can buy happiness", vibeLevel: 4, category: .hotTakes),
        ConversationStarter(text: "What's the best advice you've ever received?", vibeLevel: 3, category: .deepDive),
        ConversationStarter(text: "If you could change one thing about the world, what would it be?", vibeLevel: 4, category: .hypotheticals),
        ConversationStarter(text: "Book or movie adaptation?", vibeLevel: 2, category: .thisOrThat),
        ConversationStarter(text: "Would you rather live without the internet or without air conditioning/heating?", vibeLevel: 3, category: .wouldYouRather),
        ConversationStarter(text: "Share your biggest pet peeve", vibeLevel: 2, category: .storyTime),
        ConversationStarter(text: "Everyone should be required to work in customer service at least once", vibeLevel: 3, category: .hotTakes),
        ConversationStarter(text: "What's something you believe that most people don't?", vibeLevel: 4, category: .deepDive),
        ConversationStarter(text: "If you had to live in one place for the rest of your life, where would it be?", vibeLevel: 3, category: .hypotheticals),
        ConversationStarter(text: "Sunrise or sunset?", vibeLevel: 2, category: .thisOrThat),
        ConversationStarter(text: "Would you rather have no taste or no smell?", vibeLevel: 3, category: .wouldYouRather, minPlayers: 2),
        ConversationStarter(text: "Going to the movies alone is better than going with people", vibeLevel: 3, category: .hotTakes),
        ConversationStarter(text: "Share your most irrational fear", vibeLevel: 3, category: .storyTime),
        ConversationStarter(text: "What's one thing you wish you had known at age 18?", vibeLevel: 3, category: .deepDive),
        ConversationStarter(text: "If animals could talk, which species would be the rudest?", vibeLevel: 3, category: .hypotheticals),
        ConversationStarter(text: "Plan everything or go with the flow?", vibeLevel: 2, category: .thisOrThat),
        ConversationStarter(text: "Would you rather relive the same day for a year or lose a year of your life?", vibeLevel: 4, category: .wouldYouRather),
        ConversationStarter(text: "Cats are better than dogs", vibeLevel: 2, category: .hotTakes),
        ConversationStarter(text: "Describe yourself using only three words", vibeLevel: 2, category: .storyTime),
        ConversationStarter(text: "What motivates you to get out of bed every morning?", vibeLevel: 3, category: .deepDive),
        ConversationStarter(text: "If you could be famous for one thing, what would it be?", vibeLevel: 3, category: .hypotheticals),
        ConversationStarter(text: "Save money or spend on experiences?", vibeLevel: 2, category: .thisOrThat),
    ]
}
