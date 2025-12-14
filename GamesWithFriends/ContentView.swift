//
//  ContentView.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData


struct ContentView: View {
    @State private var selectedGame: Game?

    var body: some View {
        NavigationStack {
            List {
                Section("Road Trip Games") {
                    NavigationLink {
                        LicensePlateGameView()
                    } label: {
                        GameRow(
                            title: "License Plate Game",
                            icon: "car.fill",
                            description: "Spot plates from all 50 states and beyond!"
                        )
                    }
                }
            }
            .navigationTitle("Games with Friends")
        }
    }
}

struct GameRow: View {
    let title: String
    let icon: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

enum Game: Identifiable {
    case licensePlate

    var id: String {
        switch self {
        case .licensePlate: return "licensePlate"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [RoadTrip.self, SpottedPlate.self], inMemory: true)
}
