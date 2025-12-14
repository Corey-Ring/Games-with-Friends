//
//  LicensePlateGame.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import Foundation
import SwiftUI

struct LicensePlateGame: GameDefinition {
    let id = "license-plate-game"
    let name = "License Plate Game"
    let description = "Spot plates from all 50 states and beyond! Track your collection across multiple road trips with persistent data."
    let iconName = "car.fill"
    let accentColor: Color = .blue
    let minPlayers = 1
    let maxPlayers = 10

    var longDescription: String {
        """
        The License Plate Game is a classic road trip activity where players spot license plates from different US states, \
        Canadian provinces, and optionally Mexican states.

        Features:
        • Persistent data across app sessions
        • Track multiple road trips
        • Spot all 50 US states + DC + territories
        • Canadian provinces and territories
        • Optional Mexican states
        • Fun facts about each location
        • Rarity tiers (Common, Uncommon, Rare, Ultra-Rare)
        • Achievements and milestones
        • Family member tracking
        • Lifetime statistics
        • Visual progress tracking

        Perfect for families on summer road trips or anyone who loves collecting!
        """
    }
    
    func makeRootView() -> AnyView {
        AnyView(LicensePlateGameView())
    }
}
