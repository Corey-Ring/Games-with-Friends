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
                VStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Lifetime Statistics")
                        .font(AppTheme.Typography.screenTitle)
                        .fontWeight(.bold)

                    Text("Across all trips")
                        .font(AppTheme.Typography.secondary)
                        .foregroundStyle(.secondary)
                }
                .padding()

                // Main Stats
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppTheme.Spacing.md) {
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
                        HStack(spacing: AppTheme.Spacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .fill(GameTheme.licensePlate.accentColor.opacity(0.1))
                                    .frame(width: 80, height: 80)

                                Text(plate.code)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text(plate.name)
                                    .font(AppTheme.Typography.cardTitle)

                                Text("Spotted \(stats.mostSpottedCount) times")
                                    .font(AppTheme.Typography.secondary)
                                    .foregroundStyle(.secondary)

                                if let nickname = plate.nickname {
                                    Text(nickname)
                                        .font(AppTheme.Typography.caption)
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

                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text(rarestRarity.rawValue)
                                    .font(AppTheme.Typography.subsectionHeader)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color(rarestRarity.color))

                                Text("Worth \(rarestRarity.points) points each")
                                    .font(AppTheme.Typography.caption)
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
                                .font(AppTheme.Typography.secondary)
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
                                    .font(AppTheme.Typography.secondary)
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
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
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
                    .font(AppTheme.Typography.secondary)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(trip.startDate, style: .date)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)

                    if let endDate = trip.endDate {
                        Text("→")
                            .foregroundStyle(.secondary)
                        Text(endDate, style: .date)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("• Ongoing")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                Text("\(trip.totalSpotted)")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(.blue)

                Text("plates")
                    .font(AppTheme.Typography.tabLabel)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(AppTheme.Typography.caption)
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
                        .font(AppTheme.Typography.screenTitle)
                        .fontWeight(.bold)

                    HStack {
                        Text("Started: \(trip.startDate, style: .date)")
                        if let endDate = trip.endDate {
                            Text("• Ended: \(endDate, style: .date)")
                        }
                    }
                    .font(AppTheme.Typography.secondary)
                    .foregroundStyle(.secondary)

                    if let notes = trip.notes, !notes.isEmpty {
                        Text(notes)
                            .font(AppTheme.Typography.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.warmLinen)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                    }
                }
                .padding()

                // Spotted Plates
                VStack(alignment: .leading, spacing: 12) {
                    Text("Spotted Plates (\(trip.totalSpotted))")
                        .font(AppTheme.Typography.cardTitle)
                        .padding(.horizontal)

                    ForEach(trip.spottedPlates.sorted { $0.spottedAt > $1.spottedAt }) { spotted in
                        HStack {
                            Text(spotted.plateCode)
                                .font(AppTheme.Typography.cardTitle)
                                .frame(width: 50)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(spotted.plateName)
                                    .font(AppTheme.Typography.secondary)

                                Text(spotted.spottedAt, style: .date)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(AppTheme.warmLinen)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
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
