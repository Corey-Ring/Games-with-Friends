//
//  GamesWithFriendsApp.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

@main
struct GamesWithFriendsApp: App {
    var body: some Scene {
        WindowGroup {
            GameHubView()
        }
        .modelContainer(for: [RoadTrip.self, SpottedPlate.self])
    }
}
