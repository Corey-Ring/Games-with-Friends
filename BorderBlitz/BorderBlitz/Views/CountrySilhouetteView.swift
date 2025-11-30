//
//  CountrySilhouetteView.swift
//  Border Blitz
//

import SwiftUI

struct CountrySilhouetteView: View {
    let country: Country
    let size: CGSize

    var body: some View {
        GeometryReader { geometry in
            CountryShape(borderPoints: country.borderPoints)
                .fill(Color.blue.opacity(0.8))
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(width: size.width, height: size.height)
    }
}

struct CountryShape: Shape {
    let borderPoints: [CGPoint]

    func path(in rect: CGRect) -> Path {
        guard !borderPoints.isEmpty else {
            return Path()
        }

        var path = Path()

        // Normalize points to fit within the rect
        let normalized = normalizePoints(borderPoints, to: rect.size)

        // Start path
        path.move(to: normalized[0])

        // Draw lines between all points
        for point in normalized.dropFirst() {
            path.addLine(to: point)
        }

        // Close the path
        path.closeSubpath()

        return path
    }

    private func normalizePoints(_ points: [CGPoint], to size: CGSize) -> [CGPoint] {
        guard !points.isEmpty else { return [] }

        // Find bounds of the points
        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 1
        let minY = points.map { $0.y }.min() ?? 0
        let maxY = points.map { $0.y }.max() ?? 1

        let width = maxX - minX
        let height = maxY - minY

        guard width > 0 && height > 0 else { return points }

        // Scale to fit, maintaining aspect ratio
        let scale = min(size.width / width, size.height / height) * 0.9

        // Center the shape
        let offsetX = (size.width - (width * scale)) / 2
        let offsetY = (size.height - (height * scale)) / 2

        return points.map { point in
            CGPoint(
                x: (point.x - minX) * scale + offsetX,
                y: (point.y - minY) * scale + offsetY
            )
        }
    }
}

#Preview {
    CountrySilhouetteView(
        country: Country(
            id: "ITA",
            name: "ITALY",
            borderPoints: [
                CGPoint(x: 0, y: 0),
                CGPoint(x: 100, y: 0),
                CGPoint(x: 100, y: 200),
                CGPoint(x: 0, y: 200)
            ]
        ),
        size: CGSize(width: 300, height: 300)
    )
}
