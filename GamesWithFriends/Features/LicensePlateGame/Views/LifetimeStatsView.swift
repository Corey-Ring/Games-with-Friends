//
//  LifetimeStatsView.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct LifetimeStatsView: View {
    @Bindable var viewModel: LicensePlateViewModel

    private var stats: LifetimeStats {
        viewModel.lifetimeStats()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Lifetime Statistics")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Across all trips")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()

                // Main Stats
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatBox(
                        value: "\(stats.totalTrips)",
                        label: "Total Trips",
                        icon: "car.fill",
                        color: .blue
                    )

                    StatBox(
                        value: "\(stats.uniquePlatesSpotted)",
                        label: "Unique Plates",
                        icon: "star.fill",
                        color: .orange
                    )

                    StatBox(
                        value: "\(stats.totalPlatesSpotted)",
                        label: "Total Spots",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )

                    if stats.uniquePlatesSpotted > 0 {
                        let percentage = Int((Double(stats.uniquePlatesSpotted) / Double(PlateData.allUSPlates.count)) * 100)
                        StatBox(
                            value: "\(percentage)%",
                            label: "US Coverage",
                            icon: "flag.fill",
                            color: .red
                        )
                    }
                }
                .padding(.horizontal)

                // Most Spotted
                if let mostSpotted = stats.mostSpottedPlateCode,
                   let plate = PlateData.plate(forCode: mostSpotted) {
                    LicensePlateStatsCard(title: "Most Spotted Plate") {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 80, height: 80)

                                Text(plate.code)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text(plate.name)
                                    .font(.headline)

                                Text("Spotted \(stats.mostSpottedCount) times")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if let nickname = plate.nickname {
                                    Text(nickname)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                }

                // Rarest Plate
                if let rarestRarity = stats.rarestRarity {
                    LicensePlateStatsCard(title: "Rarest Tier Spotted") {
                        HStack(spacing: 12) {
                            Image(systemName: rarestRarity.icon)
                                .font(.system(size: 40))
                                .foregroundStyle(Color(rarestRarity.color))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(rarestRarity.rawValue)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color(rarestRarity.color))

                                Text("Worth \(rarestRarity.points) points each")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                }

                // All Trips List
                if !viewModel.trips.isEmpty {
                    LicensePlateStatsCard(title: "Trip History") {
                        VStack(spacing: 12) {
                            ForEach(viewModel.trips) { trip in
                                NavigationLink {
                                    TripHistoryDetailView(trip: trip)
                                } label: {
                                    TripHistoryRow(trip: trip)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Lifetime Achievements
                let allSpotted = viewModel.trips.flatMap { $0.spottedPlates }
                let lifetimeUnlocked = Achievement.unlockedAchievements(with: allSpotted)

                if !lifetimeUnlocked.isEmpty {
                    LicensePlateStatsCard(title: "Lifetime Achievements") {
                        VStack(spacing: 12) {
                            Text("\(lifetimeUnlocked.count) of \(Achievement.allAchievements.count) unlocked")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            ProgressView(
                                value: Double(lifetimeUnlocked.count),
                                total: Double(Achievement.allAchievements.count)
                            )
                            .tint(.blue)

                            NavigationLink {
                                AchievementsView(viewModel: viewModel)
                            } label: {
                                Text("View All Achievements")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Lifetime Stats")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 32, weight: .bold))

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

struct TripHistoryRow: View {
    let trip: RoadTrip

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(trip.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Text(trip.startDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let endDate = trip.endDate {
                        Text("→")
                            .foregroundStyle(.secondary)
                        Text(endDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("• Ongoing")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(trip.totalSpotted)")
                    .font(.headline)
                    .foregroundStyle(.blue)

                Text("plates")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

struct TripHistoryDetailView: View {
    let trip: RoadTrip

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Trip Info
                VStack(alignment: .leading, spacing: 12) {
                    Text(trip.name)
                        .font(.title)
                        .fontWeight(.bold)

                    HStack {
                        Text("Started: \(trip.startDate, style: .date)")
                        if let endDate = trip.endDate {
                            Text("• Ended: \(endDate, style: .date)")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if let notes = trip.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()

                // Spotted Plates
                VStack(alignment: .leading, spacing: 12) {
                    Text("Spotted Plates (\(trip.totalSpotted))")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(trip.spottedPlates.sorted { $0.spottedAt > $1.spottedAt }) { spotted in
                        HStack {
                            Text(spotted.plateCode)
                                .font(.system(.headline, design: .rounded))
                                .frame(width: 50)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(spotted.plateName)
                                    .font(.subheadline)

                                Text(spotted.spottedAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LifetimeStatsView(
            viewModel: LicensePlateViewModel(
                modelContext: ModelContext(
                    try! ModelContainer(for: RoadTrip.self, SpottedPlate.self)
                )
            )
        )
    }
}
