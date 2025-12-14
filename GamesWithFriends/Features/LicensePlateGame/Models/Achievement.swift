//
//  Achievement.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import Foundation

struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requirement: AchievementRequirement
    let category: AchievementCategory

    enum AchievementCategory: String, Codable {
        case progress = "Progress"
        case rarity = "Rarity"
        case regional = "Regional"
        case special = "Special"
    }

    enum AchievementRequirement: Codable, Hashable {
        case spotCount(Int)
        case spotRare(Int)
        case spotUltraRare(Int)
        case spotRegion([String])
        case spotBoth(String, String)
        case spotAllRegions
        case custom(String)
    }

    func isUnlocked(with spottedPlates: [SpottedPlate]) -> Bool {
        switch requirement {
        case .spotCount(let count):
            return spottedPlates.count >= count

        case .spotRare(let count):
            return spottedPlates.filter { $0.rarityTier == RarityTier.rare.rawValue }.count >= count

        case .spotUltraRare(let count):
            return spottedPlates.filter { $0.rarityTier == RarityTier.ultraRare.rawValue }.count >= count

        case .spotRegion(let codes):
            let spottedCodes = Set(spottedPlates.map { $0.plateCode })
            return codes.allSatisfy { spottedCodes.contains($0) }

        case .spotBoth(let code1, let code2):
            let spottedCodes = Set(spottedPlates.map { $0.plateCode })
            return spottedCodes.contains(code1) && spottedCodes.contains(code2)

        case .spotAllRegions:
            let regions = Set(spottedPlates.map { $0.region })
            return regions.contains(PlateRegion.usState.rawValue) &&
                   (regions.contains(PlateRegion.canadianProvince.rawValue) ||
                    regions.contains(PlateRegion.canadianTerritory.rawValue)) &&
                   regions.contains(PlateRegion.mexicanState.rawValue)

        case .custom(let id):
            return checkCustomRequirement(id: id, spottedPlates: spottedPlates)
        }
    }

    private func checkCustomRequirement(id: String, spottedPlates: [SpottedPlate]) -> Bool {
        let spottedCodes = Set(spottedPlates.map { $0.plateCode })

        switch id {
        case "vowel_states":
            let vowelStates = ["AL", "AK", "AZ", "AR", "ID", "IL", "IN", "IA", "OH", "OK", "OR", "UT"]
            return vowelStates.allSatisfy { spottedCodes.contains($0) }
        default:
            return false
        }
    }
}

// MARK: - Achievement Data

extension Achievement {
    static let allAchievements: [Achievement] = [
        // Progress Achievements
        Achievement(id: "first_spot", title: "First Spot", description: "Spot your first license plate",
                   icon: "target", requirement: .spotCount(1), category: .progress),

        Achievement(id: "getting_started", title: "Getting Started", description: "Spot 10 license plates",
                   icon: "car.fill", requirement: .spotCount(10), category: .progress),

        Achievement(id: "road_warrior", title: "Road Warrior", description: "Spot 25 plates in one trip",
                   icon: "road.lanes", requirement: .spotCount(25), category: .progress),

        Achievement(id: "halfway_there", title: "Halfway There", description: "Spot 26 US states (half of 50)",
                   icon: "flag.fill", requirement: .spotCount(26), category: .progress),

        Achievement(id: "fifty_club", title: "The Fifty Club", description: "Spot all 50 US states",
                   icon: "star.circle.fill", requirement: .spotCount(50), category: .progress),

        // Rarity Achievements
        Achievement(id: "rare_find", title: "Rare Find", description: "Spot your first rare plate",
                   icon: "star.fill", requirement: .spotRare(1), category: .rarity),

        Achievement(id: "ultra_rare", title: "Ultra Rare", description: "Spot an ultra-rare plate",
                   icon: "crown.fill", requirement: .spotUltraRare(1), category: .rarity),

        Achievement(id: "unicorn_hunter", title: "Unicorn Hunter", description: "Spot 5 rare plates",
                   icon: "sparkles", requirement: .spotRare(5), category: .rarity),

        Achievement(id: "collector", title: "The Collector", description: "Spot 3 ultra-rare plates",
                   icon: "trophy.fill", requirement: .spotUltraRare(3), category: .rarity),

        // Regional Achievements
        Achievement(id: "new_england", title: "New England Sweep", description: "Spot all 6 New England states",
                   icon: "leaf.fill", requirement: .spotRegion(["CT", "MA", "ME", "NH", "RI", "VT"]), category: .regional),

        Achievement(id: "pacific_states", title: "Pacific States", description: "Spot all Pacific states",
                   icon: "water.waves", requirement: .spotRegion(["WA", "OR", "CA", "AK", "HI"]), category: .regional),

        Achievement(id: "great_lakes", title: "Great Lakes", description: "Spot all Great Lakes states",
                   icon: "drop.fill", requirement: .spotRegion(["IL", "IN", "MI", "MN", "NY", "OH", "PA", "WI"]), category: .regional),

        Achievement(id: "four_corners", title: "Four Corners", description: "Spot all Four Corners states",
                   icon: "square.grid.2x2.fill", requirement: .spotRegion(["AZ", "CO", "NM", "UT"]), category: .regional),

        Achievement(id: "mountain_time", title: "Mountain Time", description: "Spot all Mountain timezone states",
                   icon: "mountain.2.fill", requirement: .spotRegion(["AZ", "CO", "ID", "MT", "NM", "NV", "UT", "WY"]), category: .regional),

        // Special Achievements
        Achievement(id: "coast_to_coast", title: "Coast to Coast", description: "Spot plates from both CA and NY",
                   icon: "globe.americas.fill", requirement: .spotBoth("CA", "NY"), category: .special),

        Achievement(id: "border_hopper", title: "Border Hopper", description: "Spot a Canadian plate",
                   icon: "leaf.fill", requirement: .spotRegion(["ON", "QC", "BC", "AB", "MB", "SK", "NS", "NB", "NL", "PE", "YT", "NT", "NU"]), category: .special),

        Achievement(id: "continental", title: "Continental", description: "Spot plates from US, Canada, AND Mexico",
                   icon: "globe.americas", requirement: .spotAllRegions, category: .special),

        Achievement(id: "the_dakotas", title: "The Dakotas", description: "Spot both North and South Dakota",
                   icon: "wind", requirement: .spotBoth("ND", "SD"), category: .special),

        Achievement(id: "vowel_states", title: "Vowel Master", description: "Spot all states starting with vowels",
                   icon: "textformat.abc", requirement: .custom("vowel_states"), category: .special)
    ]

    static func unlockedAchievements(with spottedPlates: [SpottedPlate]) -> [Achievement] {
        allAchievements.filter { $0.isUnlocked(with: spottedPlates) }
    }

    static func lockedAchievements(with spottedPlates: [SpottedPlate]) -> [Achievement] {
        allAchievements.filter { !$0.isUnlocked(with: spottedPlates) }
    }
}
