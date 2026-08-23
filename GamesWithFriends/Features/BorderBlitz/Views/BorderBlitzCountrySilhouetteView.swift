//
//  CountrySilhouetteView.swift
//  BorderBlitz
//

import SwiftUI

struct BorderBlitzCountrySilhouetteView: View {
    let country: BorderBlitzCountry

    var body: some View {
        // Recolor only (§2 rules 1 and 2): flat candy fill instead of an alpha
        // wash, and a uniform ink coastline instead of a faded accent hairline.
        // `BorderBlitzCountryShape` — its path parsing, clustering and scaling
        // math — is deliberately untouched.
        let shape = BorderBlitzCountryShape(svgPath: country.svgPath)
        shape
            .fill(BorderBlitzStyle.mapFill)
            .overlay(
                shape
                    .stroke(BorderBlitzStyle.mapOutline,
                            style: StrokeStyle(lineWidth: AppTheme.Retro.strokeWidth,
                                               lineJoin: .round))
            )
    }
}

struct BorderBlitzCountryShape: Shape {
    let svgPath: String

    func path(in rect: CGRect) -> Path {
        let commands = parseSVGPath(svgPath)
        guard !commands.isEmpty else { return Path() }

        // Split commands into subpaths (each M...Z block)
        let subpaths = splitIntoSubpaths(commands)
        guard !subpaths.isEmpty else { return Path() }

        // Compute bounding box for each subpath
        let subpathBounds = subpaths.map { boundingBox(of: $0) }

        // Find the core bounding box by clustering nearby subpaths,
        // starting from the largest one. This prevents distant territories
        // (e.g., remote islands) from shrinking the main landmass.
        let coreBounds = coreClusterBounds(subpathBounds)

        let dataWidth = coreBounds.width
        let dataHeight = coreBounds.height

        guard dataWidth > 0 && dataHeight > 0 else { return Path() }

        // Scale to fit rect, preserving aspect ratio
        let scale = min(rect.width / dataWidth, rect.height / dataHeight) * 0.9
        let offsetX = (rect.width - dataWidth * scale) / 2 + rect.minX
        let offsetY = (rect.height - dataHeight * scale) / 2 + rect.minY

        func transform(_ point: CGPoint) -> CGPoint {
            CGPoint(
                x: (point.x - coreBounds.minX) * scale + offsetX,
                y: (point.y - coreBounds.minY) * scale + offsetY
            )
        }

        var path = Path()
        for cmd in commands {
            switch cmd {
            case .moveTo(let p):
                path.move(to: transform(p))
            case .lineTo(let p):
                path.addLine(to: transform(p))
            case .close:
                path.closeSubpath()
            }
        }

        return path
    }

    /// Splits commands into separate subpaths at each moveTo command.
    private func splitIntoSubpaths(_ commands: [SVGCommand]) -> [[SVGCommand]] {
        var subpaths: [[SVGCommand]] = []
        var current: [SVGCommand] = []

        for cmd in commands {
            if case .moveTo = cmd, !current.isEmpty {
                subpaths.append(current)
                current = []
            }
            current.append(cmd)
        }
        if !current.isEmpty {
            subpaths.append(current)
        }
        return subpaths
    }

    /// Computes the bounding box of a single subpath's points.
    private func boundingBox(of commands: [SVGCommand]) -> CGRect {
        var points: [CGPoint] = []
        for cmd in commands {
            if case .moveTo(let p) = cmd { points.append(p) }
            if case .lineTo(let p) = cmd { points.append(p) }
        }
        guard !points.isEmpty else { return .zero }

        let minX = points.map(\.x).min()!
        let maxX = points.map(\.x).max()!
        let minY = points.map(\.y).min()!
        let maxY = points.map(\.y).max()!
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// Clusters subpath bounding boxes starting from the largest, expanding to
    /// include nearby subpaths. Returns the union bounding box of the cluster.
    private func coreClusterBounds(_ bounds: [CGRect]) -> CGRect {
        guard !bounds.isEmpty else { return .zero }

        // Start with the largest subpath by area
        let sorted = bounds.enumerated().sorted { $0.element.width * $0.element.height > $1.element.width * $1.element.height }
        var cluster = sorted[0].element

        // The merge threshold: a subpath is "nearby" if its center is within
        // 1.5x the current cluster's diagonal
        for (_, rect) in sorted.dropFirst() {
            let clusterDiagonal = sqrt(cluster.width * cluster.width + cluster.height * cluster.height)
            let threshold = max(clusterDiagonal * 1.5, max(cluster.width, cluster.height) * 0.5)

            let center = CGPoint(x: rect.midX, y: rect.midY)
            let clusterCenter = CGPoint(x: cluster.midX, y: cluster.midY)
            let distance = sqrt(pow(center.x - clusterCenter.x, 2) + pow(center.y - clusterCenter.y, 2))

            if distance <= threshold {
                cluster = cluster.union(rect)
            }
        }

        return cluster
    }

    private enum SVGCommand {
        case moveTo(CGPoint)
        case lineTo(CGPoint)
        case close
    }

    private func parseSVGPath(_ d: String) -> [SVGCommand] {
        var commands: [SVGCommand] = []
        let tokens = d.split(separator: " ")
        var i = 0

        while i < tokens.count {
            let token = tokens[i]
            switch token {
            case "M":
                guard i + 2 < tokens.count,
                      let x = Double(tokens[i + 1]),
                      let y = Double(tokens[i + 2]) else {
                    i += 1
                    continue
                }
                commands.append(.moveTo(CGPoint(x: x, y: y)))
                i += 3
            case "L":
                guard i + 2 < tokens.count,
                      let x = Double(tokens[i + 1]),
                      let y = Double(tokens[i + 2]) else {
                    i += 1
                    continue
                }
                commands.append(.lineTo(CGPoint(x: x, y: y)))
                i += 3
            case "Z":
                commands.append(.close)
                i += 1
            default:
                i += 1
            }
        }

        return commands
    }
}
