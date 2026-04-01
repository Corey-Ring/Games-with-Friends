//
//  LetterTilesView.swift
//  BorderBlitz
//

import SwiftUI

struct BorderBlitzLetterTilesView: View {
    let tiles: [BorderBlitzLetterTile]
    private let theme = GameTheme.borderBlitz

    var body: some View {
        GeometryReader { geometry in
            let lines = splitIntoLines(tiles)
            let maxTilesInLine = lines.map(\.count).max() ?? 1
            let availableWidth = geometry.size.width - AppTheme.Spacing.md * 2
            let spacing = AppTheme.Spacing.xs
            let maxTileWidth = (availableWidth - spacing * CGFloat(maxTilesInLine - 1)) / CGFloat(maxTilesInLine)
            let tileWidth = min(maxTileWidth, 35)
            let tileHeight = tileWidth * (45 / 35)

            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    HStack(spacing: spacing) {
                        ForEach(line) { tile in
                            BorderBlitzLetterTileView(
                                tile: tile,
                                accentColor: theme.accentColor,
                                tileWidth: tileWidth,
                                tileHeight: tileHeight
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.Spacing.md)
        }
        .frame(height: tileSectionHeight)
    }

    private var tileSectionHeight: CGFloat {
        let lines = splitIntoLines(tiles)
        let lineCount = CGFloat(max(lines.count, 1))
        return lineCount * 45 + (lineCount - 1) * AppTheme.Spacing.sm
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
    var tileWidth: CGFloat = 35
    var tileHeight: CGFloat = 45

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .fill(tile.shouldDisplay ? accentColor.opacity(0.15) : AppTheme.mediumGray.opacity(0.12))
                .frame(width: tileWidth, height: tileHeight)

            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .stroke(AppTheme.deepCharcoal.opacity(0.15), lineWidth: 1)
                .frame(width: tileWidth, height: tileHeight)

            if tile.shouldDisplay {
                Text(String(tile.character).uppercased())
                    .font(.system(size: min(tileWidth * 0.55, 20), weight: .bold))
                    .foregroundColor(AppTheme.deepCharcoal)
            } else {
                Text("_")
                    .font(.system(size: min(tileWidth * 0.55, 20), weight: .bold))
                    .foregroundColor(AppTheme.mediumGray)
            }
        }
    }
}
