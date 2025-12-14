//
//  LicensePlateViewModel.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import Foundation
import SwiftUI
import SwiftData

@Observable
class LicensePlateViewModel {
    var modelContext: ModelContext
    var trips: [RoadTrip] = []
    var currentTrip: RoadTrip?
    var showMexicanStates: Bool = false
    var familyMembers: [String] = []

    // UI State
    var showingNewTripSheet = false
    var showingSpotPlateSheet = false
    var selectedPlate: LicensePlate?
    var showingAchievements = false
    var showingStats = false
    var showingLifetimeStats = false

    // View preferences
    var viewMode: ViewMode = .grid

    enum ViewMode: String, CaseIterable {
        case grid = "Grid"
        case list = "List"

        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadTrips()
        loadSettings()
    }

    // MARK: - Data Loading

    func loadTrips() {
        let descriptor = FetchDescriptor<RoadTrip>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        trips = (try? modelContext.fetch(descriptor)) ?? []

        // Set current trip to active one or most recent
        if let activeTrip = trips.first(where: { $0.isActive }) {
            currentTrip = activeTrip
        } else if let mostRecent = trips.first {
            currentTrip = mostRecent
        }
    }

    func loadSettings() {
        // Load from UserDefaults
        showMexicanStates = UserDefaults.standard.bool(forKey: "showMexicanStates")
        familyMembers = UserDefaults.standard.stringArray(forKey: "familyMembers") ?? []
    }

    func saveSettings() {
        UserDefaults.standard.set(showMexicanStates, forKey: "showMexicanStates")
        UserDefaults.standard.set(familyMembers, forKey: "familyMembers")
    }

    // MARK: - Trip Management

    func createTrip(name: String, notes: String? = nil) {
        let newTrip = RoadTrip(name: name, startDate: Date(), isActive: true, notes: notes)

        // Deactivate other trips
        trips.forEach { $0.isActive = false }

        modelContext.insert(newTrip)
        try? modelContext.save()

        currentTrip = newTrip
        loadTrips()
    }

    func setActiveTrip(_ trip: RoadTrip) {
        trips.forEach { $0.isActive = false }
        trip.isActive = true
        currentTrip = trip
        try? modelContext.save()
    }

    func deleteTrip(_ trip: RoadTrip) {
        modelContext.delete(trip)
        try? modelContext.save()
        loadTrips()
    }

    func endTrip(_ trip: RoadTrip) {
        trip.endDate = Date()
        trip.isActive = false
        try? modelContext.save()
        loadTrips()
    }

    // MARK: - Plate Management

    func availablePlates() -> [LicensePlate] {
        var plates = PlateData.allUSPlates + PlateData.allCanadianPlates
        if showMexicanStates {
            plates += PlateData.allMexicanStates
        }
        return plates.sorted { $0.name < $1.name }
    }

    func isPlateSpotted(_ plate: LicensePlate) -> Bool {
        guard let trip = currentTrip else { return false }
        return trip.hasSpotted(plateCode: plate.code)
    }

    func spotPlate(
        _ plate: LicensePlate,
        spottedBy: String? = nil,
        locationDescription: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        guard let trip = currentTrip else { return }

        // Don't spot if already spotted
        if trip.hasSpotted(plateCode: plate.code) {
            return
        }

        let spottedPlate = SpottedPlate(
            plateCode: plate.code,
            plateName: plate.name,
            region: plate.region,
            rarityTier: plate.rarityTier,
            spottedAt: Date(),
            locationDescription: locationDescription,
            latitude: latitude,
            longitude: longitude,
            spottedBy: spottedBy,
            trip: trip
        )

        modelContext.insert(spottedPlate)
        trip.spottedPlates.append(spottedPlate)

        try? modelContext.save()
        loadTrips()

        // Check for new achievements
        checkForNewAchievements()
    }

    func unspotPlate(_ plate: LicensePlate) {
        guard let trip = currentTrip else { return }
        guard let spottedPlate = trip.getSpottedPlate(code: plate.code) else { return }

        modelContext.delete(spottedPlate)
        try? modelContext.save()
        loadTrips()
    }

    // MARK: - Statistics

    func tripProgress() -> Double {
        guard let trip = currentTrip else { return 0 }
        let total = availablePlates().count
        guard total > 0 else { return 0 }
        return Double(trip.totalSpotted) / Double(total)
    }

    func usStatesProgress() -> Double {
        guard let trip = currentTrip else { return 0 }
        let total = PlateData.usStates.count + 1 // +1 for DC
        guard total > 0 else { return 0 }
        return Double(trip.usStatesSpotted) / Double(total)
    }

    func rarityBreakdown() -> [(RarityTier, Int)] {
        guard let trip = currentTrip else { return [] }

        var breakdown: [RarityTier: Int] = [
            .common: 0,
            .uncommon: 0,
            .rare: 0,
            .ultraRare: 0
        ]

        for spottedPlate in trip.spottedPlates {
            if let rarity = RarityTier(rawValue: spottedPlate.rarityTier) {
                breakdown[rarity, default: 0] += 1
            }
        }

        return RarityTier.allCases.map { ($0, breakdown[$0] ?? 0) }
    }

    func lifetimeStats() -> LifetimeStats {
        let allSpottedPlates = trips.flatMap { $0.spottedPlates }
        let uniquePlates = Set(allSpottedPlates.map { $0.plateCode })

        var plateCounts: [String: Int] = [:]
        for plate in allSpottedPlates {
            plateCounts[plate.plateCode, default: 0] += 1
        }

        let mostSpotted = plateCounts.max { $0.value > $1.value }
        let rarestPlate = allSpottedPlates
            .compactMap { $0.rarity }
            .max()

        return LifetimeStats(
            totalTrips: trips.count,
            uniquePlatesSpotted: uniquePlates.count,
            totalPlatesSpotted: allSpottedPlates.count,
            mostSpottedPlateCode: mostSpotted?.key,
            mostSpottedCount: mostSpotted?.value ?? 0,
            rarestRarity: rarestPlate
        )
    }

    // MARK: - Achievements

    func checkForNewAchievements() {
        guard let trip = currentTrip else { return }
        let unlocked = Achievement.unlockedAchievements(with: trip.spottedPlates)
        // Could show notification here for newly unlocked achievements
    }

    func unlockedAchievements() -> [Achievement] {
        guard let trip = currentTrip else { return [] }
        return Achievement.unlockedAchievements(with: trip.spottedPlates)
    }

    func lockedAchievements() -> [Achievement] {
        guard let trip = currentTrip else { return Achievement.allAchievements }
        return Achievement.lockedAchievements(with: trip.spottedPlates)
    }

    // MARK: - Family Members

    func addFamilyMember(_ name: String) {
        if !familyMembers.contains(name) {
            familyMembers.append(name)
            saveSettings()
        }
    }

    func removeFamilyMember(_ name: String) {
        familyMembers.removeAll { $0 == name }
        saveSettings()
    }

    // MARK: - Filtering and Sorting

    func plates(for region: PlateRegion) -> [LicensePlate] {
        availablePlates().filter { $0.region == region }
    }

    func spottedPlates() -> [LicensePlate] {
        guard let trip = currentTrip else { return [] }
        let spottedCodes = Set(trip.spottedPlates.map { $0.plateCode })
        return availablePlates().filter { spottedCodes.contains($0.code) }
    }

    func unspottedPlates() -> [LicensePlate] {
        guard let trip = currentTrip else { return availablePlates() }
        let spottedCodes = Set(trip.spottedPlates.map { $0.plateCode })
        return availablePlates().filter { !spottedCodes.contains($0.code) }
    }

    func plates(byRarity rarity: RarityTier) -> [LicensePlate] {
        availablePlates().filter { $0.rarityTier == rarity }
    }
}

// MARK: - Supporting Types

struct LifetimeStats {
    let totalTrips: Int
    let uniquePlatesSpotted: Int
    let totalPlatesSpotted: Int
    let mostSpottedPlateCode: String?
    let mostSpottedCount: Int
    let rarestRarity: RarityTier?
}
