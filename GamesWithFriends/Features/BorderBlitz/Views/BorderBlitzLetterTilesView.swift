//
//  LetterTilesView.swift
//  BorderBlitz
//

import SwiftUI

struct BorderBlitzLetterTilesView: View {
    let tiles: [BorderBlitzLetterTile]
    private let theme = GameTheme.borderBlitz

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Split into lines if there are spaces
            let lines = splitIntoLines(tiles)

            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(spacing: AppTheme.Spacing.xs) {
                    ForEach(line) { tile in
                        BorderBlitzLetterTileView(tile: tile, accentColor: theme.accentColor)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
    }

    private func splitIntoLines(_ tiles: [BorderBlitzLetterTile]) -> [[BorderBlitzLetterTile]] {
        var lines: [[BorderBlitzLetterTile]] = []
        var currentLine: [BorderBlitzLetterTile] = []

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

struct BorderBlitzLetterTileView: View {
    let tile: BorderBlitzLetterTile
    var accentColor: Color = AppTheme.tealGreen

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .fill(tile.shouldDisplay ? accentColor.opacity(0.15) : AppTheme.mediumGray.opacity(0.12))
                .frame(width: 35, height: 45)

            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .stroke(AppTheme.deepCharcoal.opacity(0.15), lineWidth: 1)
                .frame(width: 35, height: 45)

            if tile.shouldDisplay {
                Text(String(tile.character).uppercased())
                    .font(AppTheme.Typography.sectionHeader)
                    .foregroundColor(AppTheme.deepCharcoal)
            } else {
                Text("_")
                    .font(AppTheme.Typography.sectionHeader)
                    .foregroundColor(AppTheme.mediumGray)
            }
        }
    }
}
