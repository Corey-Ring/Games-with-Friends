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
    init() {
        RetroFonts.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            GameHubView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [FinishTheLineRoundResult.self])
    }
}
