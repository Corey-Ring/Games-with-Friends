//
//  RoadTrip.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import Foundation
import SwiftData

@Model
class RoadTrip {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    @Relationship(deleteRule: .cascade, inverse: \SpottedPlate.trip)
    var spottedPlates: [SpottedPlate]
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = false,
        spottedPlates: [SpottedPlate] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.spottedPlates = spottedPlates
        self.notes = notes
    }

    // Computed properties
    var totalSpotted: Int {
        spottedPlates.count
    }

    var usStatesSpotted: Int {
        spottedPlates.filter { $0.region == PlateRegion.usState.rawValue }.count
    }

    var canadianProvincesSpotted: Int {
        spottedPlates.filter { $0.region == PlateRegion.canadianProvince.rawValue }.count
    }

    var canadianTerritoriesSpotted: Int {
        spottedPlates.filter { $0.region == PlateRegion.canadianTerritory.rawValue }.count
    }

    var usTerritoriesSpotted: Int {
        spottedPlates.filter { $0.region == PlateRegion.usTerritory.rawValue }.count
    }

    var mexicanStatesSpotted: Int {
        spottedPlates.filter { $0.region == PlateRegion.mexicanState.rawValue }.count
    }

    var totalPoints: Int {
        spottedPlates.reduce(0) { sum, plate in
            if let rarity = RarityTier(rawValue: plate.rarityTier) {
                return sum + rarity.points
            }
            return sum
        }
    }

    var isOngoing: Bool {
        endDate == nil
    }

    func hasSpotted(plateCode: String) -> Bool {
        spottedPlates.contains { $0.plateCode == plateCode }
    }

    func getSpottedPlate(code: String) -> SpottedPlate? {
        spottedPlates.first { $0.plateCode == code }
    }
}
