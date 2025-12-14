//
//  SpottedPlate.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import Foundation
import SwiftData

@Model
class SpottedPlate {
    var id: UUID
    var plateCode: String
    var plateName: String
    var region: String  // Stored as String for SwiftData compatibility
    var rarityTier: String  // Stored as String for SwiftData compatibility
    var spottedAt: Date
    var locationDescription: String?
    var latitude: Double?
    var longitude: Double?
    var spottedBy: String?
    var trip: RoadTrip?

    init(
        id: UUID = UUID(),
        plateCode: String,
        plateName: String,
        region: PlateRegion,
        rarityTier: RarityTier,
        spottedAt: Date = Date(),
        locationDescription: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        spottedBy: String? = nil,
        trip: RoadTrip? = nil
    ) {
        self.id = id
        self.plateCode = plateCode
        self.plateName = plateName
        self.region = region.rawValue
        self.rarityTier = rarityTier.rawValue
        self.spottedAt = spottedAt
        self.locationDescription = locationDescription
        self.latitude = latitude
        self.longitude = longitude
        self.spottedBy = spottedBy
        self.trip = trip
    }

    var plateRegion: PlateRegion? {
        PlateRegion(rawValue: region)
    }

    var rarity: RarityTier? {
        RarityTier(rawValue: rarityTier)
    }

    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }
}
