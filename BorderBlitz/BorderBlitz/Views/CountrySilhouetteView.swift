//
//  CountrySilhouetteView.swift
//  Border Blitz
//

import SwiftUI

struct CountrySilhouetteView: View {
    let country: Country
    let size: CGSize

    var body: some View {
        CountryShape(svgPath: country.svgPath)
            .fill(Color.white.opacity(0.85))
            .frame(width: size.width, height: size.height)
    }
}

struct CountryShape: Shape {
    let svgPath: String

    func path(in rect: CGRect) -> Path {
        let commands = parseSVGPath(svgPath)
        guard !commands.isEmpty else { return Path() }

        // Collect all points to compute bounding box
        var allPoints: [CGPoint] = []
        for cmd in commands {
            if case .moveTo(let p) = cmd { allPoints.append(p) }
            if case .lineTo(let p) = cmd { allPoints.append(p) }
        }

        guard !allPoints.isEmpty else { return Path() }

        let minX = allPoints.map(\.x).min()!
        let maxX = allPoints.map(\.x).max()!
        let minY = allPoints.map(\.y).min()!
        let maxY = allPoints.map(\.y).max()!

        let dataWidth = maxX - minX
        let dataHeight = maxY - minY

        guard dataWidth > 0 && dataHeight > 0 else { return Path() }

        // Scale to fit rect, preserving aspect ratio with padding
        let scale = min(rect.width / dataWidth, rect.height / dataHeight) * 0.9
        let offsetX = (rect.width - dataWidth * scale) / 2 + rect.minX
        let offsetY = (rect.height - dataHeight * scale) / 2 + rect.minY

        func transform(_ point: CGPoint) -> CGPoint {
            CGPoint(
                x: (point.x - minX) * scale + offsetX,
                y: (point.y - minY) * scale + offsetY
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

#Preview {
    CountrySilhouetteView(
        country: Country(
            id: "ITA",
            name: "ITALY",
            svgPath: "M 500 0 L 1000 0 L 1000 1000 L 0 1000 L 0 500 Z"
        ),
        size: CGSize(width: 250, height: 250)
    )
}
