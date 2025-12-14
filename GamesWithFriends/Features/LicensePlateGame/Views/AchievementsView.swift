//
//  AchievementsView.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Bindable var viewModel: LicensePlateViewModel
    @State private var selectedCategory: Achievement.AchievementCategory?

    private var unlockedAchievements: [Achievement] {
        viewModel.unlockedAchievements()
    }

    private var lockedAchievements: [Achievement] {
        viewModel.lockedAchievements()
    }

    private var filteredUnlocked: [Achievement] {
        if let category = selectedCategory {
            return unlockedAchievements.filter { $0.category == category }
        }
        return unlockedAchievements
    }

    private var filteredLocked: [Achievement] {
        if let category = selectedCategory {
            return lockedAchievements.filter { $0.category == category }
        }
        return lockedAchievements
    }

    var body: some View {
        VStack(spacing: 0) {
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(title: "All", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }

                    ForEach([Achievement.AchievementCategory.progress, .rarity, .regional, .special], id: \.self) { category in
                        FilterChip(
                            title: category.rawValue,
                            isSelected: selectedCategory == category
                        ) {
                            if selectedCategory == category {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // Progress Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(unlockedAchievements.count) of \(Achievement.allAchievements.count)")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Achievements Unlocked")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.2), lineWidth: 6)
                            .frame(width: 60, height: 60)

                        Circle()
                            .trim(from: 0, to: Double(unlockedAchievements.count) / Double(Achievement.allAchievements.count))
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int((Double(unlockedAchievements.count) / Double(Achievement.allAchievements.count)) * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(.systemGray6))

            // Achievement Lists
            List {
                if !filteredUnlocked.isEmpty {
                    Section("Unlocked") {
                        ForEach(filteredUnlocked) { achievement in
                            AchievementDetailRow(achievement: achievement, isUnlocked: true)
                        }
                    }
                }

                if !filteredLocked.isEmpty {
                    Section("Locked") {
                        ForEach(filteredLocked) { achievement in
                            AchievementDetailRow(achievement: achievement, isUnlocked: false)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AchievementDetailRow: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.blue.opacity(0.2) : Color(.systemGray5))
                    .frame(width: 56, height: 56)

                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundStyle(isUnlocked ? .blue : .gray)
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)

                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Label(achievement.category.rawValue, systemImage: "tag.fill")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Status
            if isUnlocked {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.gray)
            }
        }
        .padding(.vertical, 8)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

#Preview {
    NavigationStack {
        AchievementsView(
            viewModel: LicensePlateViewModel(
                modelContext: ModelContext(
                    try! ModelContainer(for: RoadTrip.self, SpottedPlate.self)
                )
            )
        )
    }
}
