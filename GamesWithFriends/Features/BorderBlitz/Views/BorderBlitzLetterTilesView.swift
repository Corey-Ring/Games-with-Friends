//
//  LetterTilesView.swift
//  BorderBlitz
//

import SwiftUI

struct BorderBlitzLetterTilesView: View {
    let tiles: [BorderBlitzLetterTile]

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
                                accentColor: BorderBlitzStyle.accent,
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

/// Tile chrome only: flat candy fill, uniform ink rule, Lilita letterform
/// (§2 rules 1/2/4). Sizing math, reveal state and layout are untouched — the
/// two `.frame(width:height:)` calls still take the values the parent computes.
struct BorderBlitzLetterTileView: View {
    let tile: BorderBlitzLetterTile
    var accentColor: Color = BorderBlitzStyle.accent
    var tileWidth: CGFloat = 35
    var tileHeight: CGFloat = 45

    private var cornerRadius: CGFloat { 10 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(tile.shouldDisplay ? accentColor : BorderBlitzStyle.tileHiddenFill)
                .frame(width: tileWidth, height: tileHeight)

            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(AppTheme.Retro.ink, lineWidth: 2)
                .frame(width: tileWidth, height: tileHeight)

            if tile.shouldDisplay {
                // §8: ink on poolBlue passes.
                Text(String(tile.character).uppercased())
                    .font(AppTheme.Retro.Typography.heading(min(tileWidth * 0.55, 20),
                                                            relativeTo: .title3))
                    .foregroundColor(BorderBlitzStyle.chipTextColor(on: accentColor))
            } else {
                // Unfilled placeholder is low-alpha ink, never gray
                // (§4 gotcha 6 / §9 — the pastel grays are retired).
                Text("_")
                    .font(AppTheme.Retro.Typography.heading(min(tileWidth * 0.55, 20),
                                                            relativeTo: .title3))
                    .foregroundColor(BorderBlitzStyle.tilePlaceholder)
            }
        }
    }
}
