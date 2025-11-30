//
//  Country.swift
//  Border Blitz
//

import Foundation
import CoreGraphics

struct Country: Identifiable, Codable {
    let id: String
    let name: String
    let borderPoints: [CGPoint]

    /// Alternate names that should be accepted as correct answers
    var alternateNames: [String] = []

    /// Normalized name for comparison (lowercase, no special chars)
    var normalizedName: String {
        name.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    /// Get all acceptable answers (main name + alternates)
    var acceptableAnswers: [String] {
        ([name] + alternateNames).map { answer in
            answer.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .joined()
        }
    }

    /// Check if a guess matches this country
    func isMatch(_ guess: String) -> Bool {
        let normalizedGuess = guess.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()

        return acceptableAnswers.contains(normalizedGuess)
    }
}

// MARK: - CGPoint Codable Extension
extension CGPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}
