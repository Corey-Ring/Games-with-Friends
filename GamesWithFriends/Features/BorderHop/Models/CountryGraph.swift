import Foundation

struct Route {
    let startId: String
    let destinationId: String
    let optimalPath: [String]
}

class CountryGraph {
    private let countries: [String: BorderHopCountry]
    private let adjacency: [String: Set<String>]

    init(countries: [BorderHopCountry]) {
        var countryMap: [String: BorderHopCountry] = [:]
        var adjMap: [String: Set<String>] = [:]
        for country in countries {
            countryMap[country.id] = country
            adjMap[country.id] = Set(country.neighbors)
        }
        self.countries = countryMap
        self.adjacency = adjMap
    }

    func country(for id: String) -> BorderHopCountry? {
        countries[id]
    }

    func neighbors(of id: String) -> [BorderHopCountry] {
        guard let neighborIds = adjacency[id] else { return [] }
        return neighborIds.compactMap { countries[$0] }
    }

    func neighborIds(of id: String) -> Set<String> {
        adjacency[id] ?? []
    }

    var allCountries: [BorderHopCountry] {
        Array(countries.values)
    }

    var allCountryIds: Set<String> {
        Set(countries.keys)
    }

    // MARK: - BFS Shortest Path

    func shortestPath(from startId: String, to destId: String) -> [String]? {
        guard countries[startId] != nil, countries[destId] != nil else { return nil }
        if startId == destId { return [startId] }

        var queue: [(String, [String])] = [(startId, [startId])]
        var visited: Set<String> = [startId]
        var index = 0

        while index < queue.count {
            let (currentId, path) = queue[index]
            index += 1

            for neighborId in adjacency[currentId] ?? [] {
                if neighborId == destId {
                    return path + [neighborId]
                }
                if !visited.contains(neighborId) {
                    visited.insert(neighborId)
                    queue.append((neighborId, path + [neighborId]))
                }
            }
        }
        return nil
    }

    /// BFS flood fill: all reachable countries from a start with their distances
    func reachableWithDistances(from startId: String) -> [String: Int] {
        var distances: [String: Int] = [startId: 0]
        var queue: [String] = [startId]
        var index = 0

        while index < queue.count {
            let currentId = queue[index]
            let currentDist = distances[currentId]!
            index += 1

            for neighborId in adjacency[currentId] ?? [] {
                if distances[neighborId] == nil {
                    distances[neighborId] = currentDist + 1
                    queue.append(neighborId)
                }
            }
        }
        return distances
    }

    // MARK: - Route Generation

    /// Micro-states that should not be start or destination for easy/medium tiers
    private static let microStates: Set<String> = ["VAT", "MCO", "SMR", "LIE", "AND"]

    func generateRoute(difficulty: BorderHopDifficulty) -> Route? {
        let eligible = countries.values.filter { country in
            // Exclude micro-states from start/dest for easy/medium
            if (difficulty == .easy || difficulty == .medium),
               Self.microStates.contains(country.id) {
                return false
            }
            // Must have at least one neighbor
            return !country.neighbors.isEmpty
        }

        guard !eligible.isEmpty else { return nil }

        // Try up to 50 times to find a valid route
        for _ in 0..<50 {
            guard let start = eligible.randomElement() else { continue }

            let distances = reachableWithDistances(from: start.id)

            // Filter candidates by difficulty rules
            let candidates = distances.compactMap { (id, dist) -> (String, Int)? in
                guard dist >= difficulty.minHops else { return nil }
                guard let dest = countries[id] else { return nil }

                // Skip micro-states as destination
                if (difficulty == .easy || difficulty == .medium),
                   Self.microStates.contains(id) {
                    return nil
                }

                // Region rules
                if difficulty.requireSameRegion {
                    guard dest.region == start.region else { return nil }
                }

                if let pairs = difficulty.allowedRegionPairs {
                    let regionPair = (start.region, dest.region)
                    let reversePair = (dest.region, start.region)
                    let matchesPair = pairs.contains { $0 == regionPair || $0 == reversePair }
                    guard matchesPair else { return nil }
                }

                return (id, dist)
            }

            guard let (destId, _) = candidates.randomElement() else { continue }

            if let path = shortestPath(from: start.id, to: destId) {
                return Route(
                    startId: start.id,
                    destinationId: destId,
                    optimalPath: path
                )
            }
        }

        return nil
    }
}
