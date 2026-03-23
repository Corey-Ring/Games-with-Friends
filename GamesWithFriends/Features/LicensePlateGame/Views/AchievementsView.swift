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
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.pureWhite)

            // Progress Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("\(unlockedAchievements.count) of \(Achievement.allAchievements.count)")
                            .font(AppTheme.Typography.sectionHeader)
                            .fontWeight(.bold)

                        Text("Achievements Unlocked")
                            .font(AppTheme.Typography.secondary)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(GameTheme.licensePlate.accentColor.opacity(0.2), lineWidth: 6)
                            .frame(width: 60, height: 60)

                        Circle()
                            .trim(from: 0, to: Double(unlockedAchievements.count) / Double(Achievement.allAchievements.count))
                            .stroke(GameTheme.licensePlate.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int((Double(unlockedAchievements.count) / Double(Achievement.allAchievements.count)) * 100))%")
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.bold)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(AppTheme.warmLinen)

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
        HStack(spacing: AppTheme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? GameTheme.licensePlate.accentColor.opacity(0.2) : AppTheme.warmLinen)
                    .frame(width: 56, height: 56)

                Image(systemName: achievement.icon)
                    .font(AppTheme.Typography.sectionHeader)
                    .foregroundStyle(isUnlocked ? GameTheme.licensePlate.accentColor : AppTheme.mediumGray)
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(achievement.title)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)

                Text(achievement.description)
                    .font(AppTheme.Typography.secondary)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Label(achievement.category.rawValue, systemImage: "tag.fill")
                    .font(AppTheme.Typography.tabLabel)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Status
            if isUnlocked {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(AppTheme.Typography.subsectionHeader)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.gray)
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
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
