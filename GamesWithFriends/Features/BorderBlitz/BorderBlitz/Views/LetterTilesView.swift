//
//  LetterTilesView.swift
//  Border Blitz
//

import SwiftUI

struct LetterTilesView: View {
    let tiles: [LetterTile]

    var body: some View {
        VStack(spacing: 8) {
            // Split into lines if there are spaces
            let lines = splitIntoLines(tiles)

            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(spacing: 4) {
                    ForEach(line) { tile in
                        LetterTileView(tile: tile)
                    }
                }
            }
        }
        .padding()
    }

    private func splitIntoLines(_ tiles: [LetterTile]) -> [[LetterTile]] {
        var lines: [[LetterTile]] = []
        var currentLine: [LetterTile] = []

        for tile in tiles {
            if tile.character == " " {
                if !currentLine.isEmpty {
                    lines.append(currentLine)
                    currentLine = []
                }
            } else {
                currentLine.append(tile)
            }
        }

        if !currentLine.isEmpty {
            lines.append(currentLine)
        }

        return lines.isEmpty ? [[]] : lines
    }
}

struct LetterTileView: View {
    let tile: LetterTile

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(tile.shouldDisplay ? Color.green.opacity(0.3) : Color.gray.opacity(0.2))
                .frame(width: 35, height: 45)

            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                .frame(width: 35, height: 45)

            if tile.shouldDisplay {
                Text(String(tile.character).uppercased())
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            } else {
                Text("_")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LetterTilesView(tiles: [
            LetterTile(character: "I", index: 0, isRevealed: true),
            LetterTile(character: "T", index: 1, isRevealed: true),
            LetterTile(character: "A", index: 2, isRevealed: false),
            LetterTile(character: "L", index: 3, isRevealed: false),
            LetterTile(character: "Y", index: 4, isRevealed: false)
        ])

        LetterTilesView(tiles: [
            LetterTile(character: "S", index: 0, isRevealed: true),
            LetterTile(character: "O", index: 1, isRevealed: false),
            LetterTile(character: "U", index: 2, isRevealed: false),
            LetterTile(character: "T", index: 3, isRevealed: false),
            LetterTile(character: "H", index: 4, isRevealed: false),
            LetterTile(character: " ", index: 5, isRevealed: false),
            LetterTile(character: "K", index: 6, isRevealed: false),
            LetterTile(character: "O", index: 7, isRevealed: false),
            LetterTile(character: "R", index: 8, isRevealed: false),
            LetterTile(character: "E", index: 9, isRevealed: false),
            LetterTile(character: "A", index: 10, isRevealed: false)
        ])
    }
    .padding()
}
