//
//  TripStatsView.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData


struct TripStatsView: View {
    @Bindable var viewModel: LicensePlateViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let trip = viewModel.currentTrip {
                    // Trip Header
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text(trip.name)
                            .font(AppTheme.Typography.screenTitle)
                            .fontWeight(.bold)

                        Text("Started \(trip.startDate, style: .date)")
                            .font(AppTheme.Typography.secondary)
                            .foregroundStyle(.secondary)

                        if let endDate = trip.endDate {
                            Text("Ended \(endDate, style: .date)")
                                .font(AppTheme.Typography.secondary)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Ongoing")
                                .font(AppTheme.Typography.secondary)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding()

                    // Overall Progress
                    LicensePlateStatsCard(title: "Overall Progress") {
                        VStack(spacing: AppTheme.Spacing.md) {
                            CircularProgressView(
                                progress: viewModel.tripProgress(),
                                total: viewModel.availablePlates().count,
                                spotted: trip.totalSpotted,
                                color: .blue
                            )

                            HStack(spacing: 20) {
                                LicensePlateStatItem(
                                    value: "\(trip.totalSpotted)",
                                    label: "Spotted",
                                    icon: "checkmark.circle.fill",
                                    color: .green
                                )

                                Divider()
                                    .frame(height: 40)

                                LicensePlateStatItem(
                                    value: "\(trip.totalPoints)",
                                    label: "Points",
                                    icon: "star.fill",
                                    color: .orange
                                )
                            }
                        }
                    }

                    // Regional Breakdown
                    LicensePlateStatsCard(title: "Regional Progress") {
                        VStack(spacing: 12) {
                            RegionalProgressRow(
                                region: "US States",
                                spotted: trip.usStatesSpotted,
                                total: PlateData.usStates.count + 1,
                                color: .blue
                            )

                            RegionalProgressRow(
                                region: "US Territories",
                                spotted: trip.usTerritoriesSpotted,
                                total: PlateData.usTerritories.count,
                                color: .purple
                            )

                            RegionalProgressRow(
                                region: "Canadian Provinces",
                                spotted: trip.canadianProvincesSpotted,
                                total: PlateData.canadianProvinces.count,
                                color: .red
                            )

                            RegionalProgressRow(
                                region: "Canadian Territories",
                                spotted: trip.canadianTerritoriesSpotted,
                                total: PlateData.canadianTerritories.count,
                                color: .indigo
                            )

                            if viewModel.showMexicanStates {
                                RegionalProgressRow(
                                    region: "Mexican States",
                                    spotted: trip.mexicanStatesSpotted,
                                    total: PlateData.allMexicanStates.count,
                                    color: .green
                                )
                            }
                        }
                    }

                    // Rarity Breakdown
                    LicensePlateStatsCard(title: "Rarity Breakdown") {
                        VStack(spacing: 12) {
                            ForEach(viewModel.rarityBreakdown(), id: \.0) { rarity, count in
                                HStack {
                                    Image(systemName: rarity.icon)
                                        .foregroundStyle(Color(rarity.color))

                                    Text(rarity.rawValue)
                                        .font(AppTheme.Typography.secondary)

                                    Spacer()

                                    Text("\(count)")
                                        .font(AppTheme.Typography.cardTitle)
                                        .foregroundStyle(Color(rarity.color))

                                    Text("(\(count * rarity.points) pts)")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // Recent Spots
                    if !trip.spottedPlates.isEmpty {
                        LicensePlateStatsCard(title: "Recent Spots") {
                            VStack(spacing: 12) {
                                ForEach(trip.spottedPlates.sorted { $0.spottedAt > $1.spottedAt }.prefix(5)) { spotted in
                                    RecentSpotRow(spottedPlate: spotted)
                                }
                            }
                        }
                    }

                    // Achievements
                    let unlocked = viewModel.unlockedAchievements()
                    if !unlocked.isEmpty {
                        LicensePlateStatsCard(title: "Achievements Unlocked") {
                            VStack(spacing: 12) {
                                ForEach(unlocked.prefix(5)) { achievement in
                                    AchievementRow(achievement: achievement, isUnlocked: true)
                                }

                                if unlocked.count > 5 {
                                    NavigationLink {
                                        AchievementsView(viewModel: viewModel)
                                    } label: {
                                        Text("View all \(unlocked.count) achievements")
                                            .font(AppTheme.Typography.caption)
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Active Trip",
                        systemImage: "car.fill",
                        description: Text("Create a trip to start tracking plates")
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Trip Stats")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LicensePlateStatsCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(.secondary)

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(.regularMaterial)
        )
    }
}

struct CircularProgressView: View {
    let progress: Double
    let total: Int
    let spotted: Int
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 12)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0), value: progress)

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("\(spotted)")
                    .font(.system(size: 36, weight: .bold))

                Text("of \(total)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 140, height: 140)
    }
}

struct LicensePlateStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(AppTheme.Typography.sectionHeader)
                .foregroundStyle(color)

            Text(value)
                .font(AppTheme.Typography.sectionHeader)
                .fontWeight(.bold)

            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct RegionalProgressRow: View {
    let region: String
    let spotted: Int
    let total: Int
    let color: Color

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(spotted) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(region)
                    .font(AppTheme.Typography.secondary)
                    .fontWeight(.medium)

                Spacer()

                Text("\(spotted)/\(total)")
                    .font(AppTheme.Typography.secondary)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(color)
        }
    }
}

struct RecentSpotRow: View {
    let spottedPlate: SpottedPlate

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(spottedPlate.plateName)
                    .font(AppTheme.Typography.secondary)
                    .fontWeight(.medium)

                Text(spottedPlate.spottedAt, style: .relative)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)

                if let spottedBy = spottedPlate.spottedBy {
                    Text("by \(spottedBy)")
                        .font(AppTheme.Typography.tabLabel)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text(spottedPlate.plateCode)
                .font(AppTheme.Typography.body)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(AppTheme.Typography.subsectionHeader)
                .foregroundStyle(isUnlocked ? .blue : .gray)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(AppTheme.Typography.secondary)
                    .fontWeight(.medium)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)

                Text(achievement.description)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.gray)
                    .font(AppTheme.Typography.caption)
            }
        }
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

#Preview {
    NavigationStack {
        TripStatsView(
            viewModel: LicensePlateViewModel(
                modelContext: ModelContext(
                    try! ModelContainer(for: RoadTrip.self, SpottedPlate.self)
                )
            )
        )
    }
}
