//
//  LicensePlate.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import Foundation

struct LicensePlate: Identifiable, Codable, Hashable {
    let id: String  // Same as code
    let code: String
    let name: String
    let region: PlateRegion
    let capital: String
    let nickname: String?
    let rarityTier: RarityTier
    let funFact: String

    init(
        code: String,
        name: String,
        region: PlateRegion,
        capital: String,
        nickname: String? = nil,
        rarityTier: RarityTier,
        funFact: String
    ) {
        self.id = code
        self.code = code
        self.name = name
        self.region = region
        self.capital = capital
        self.nickname = nickname
        self.rarityTier = rarityTier
        self.funFact = funFact
    }

    var displayName: String {
        name
    }

    var fullDisplayName: String {
        if let nickname = nickname {
            return "\(name) - \(nickname)"
        }
        return name
    }
}
