//
//  PlateGridView.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct PlateGridView: View {
    @Bindable var viewModel: LicensePlateViewModel
    @State private var selectedRegion: PlateRegion?
    @State private var showSpottedOnly = false
    @State private var showUnspottedOnly = false

    var body: some View {
        VStack(spacing: 0) {
            // Filter controls
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedRegion == nil && !showSpottedOnly && !showUnspottedOnly
                    ) {
                        selectedRegion = nil
                        showSpottedOnly = false
                        showUnspottedOnly = false
                    }

                    FilterChip(title: "Spotted", isSelected: showSpottedOnly) {
                        showSpottedOnly.toggle()
                        showUnspottedOnly = false
                        selectedRegion = nil
                    }

                    FilterChip(title: "Unspotted", isSelected: showUnspottedOnly) {
                        showUnspottedOnly.toggle()
                        showSpottedOnly = false
                        selectedRegion = nil
                    }

                    Divider()
                        .frame(height: 20)

                    ForEach(PlateRegion.allCases, id: \.self) { region in
                        if shouldShowRegion(region) {
                            FilterChip(
                                title: region.displayName,
                                icon: region.icon,
                                isSelected: selectedRegion == region
                            ) {
                                if selectedRegion == region {
                                    selectedRegion = nil
                                } else {
                                    selectedRegion = region
                                    showSpottedOnly = false
                                    showUnspottedOnly = false
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.pureWhite)

            // Grid or List
            if viewModel.viewMode == .grid {
                gridView
            } else {
                listView
            }
        }
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160), spacing: 12)
            ], spacing: 12) {
                ForEach(filteredPlates) { plate in
                    PlateGridItem(
                        plate: plate,
                        isSpotted: viewModel.isPlateSpotted(plate)
                    )
                    .onTapGesture {
                        viewModel.selectedPlate = plate
                    }
                }
            }
            .padding()
        }
    }

    private var listView: some View {
        List(filteredPlates) { plate in
            PlateListItem(
                plate: plate,
                isSpotted: viewModel.isPlateSpotted(plate)
            )
            .onTapGesture {
                viewModel.selectedPlate = plate
            }
        }
        .listStyle(.plain)
    }

    private var filteredPlates: [LicensePlate] {
        var plates = viewModel.availablePlates()

        if let region = selectedRegion {
            plates = plates.filter { $0.region == region }
        }

        if showSpottedOnly {
            plates = viewModel.spottedPlates()
        }

        if showUnspottedOnly {
            plates = viewModel.unspottedPlates()
        }

        return plates.sorted { $0.name < $1.name }
    }

    private func shouldShowRegion(_ region: PlateRegion) -> Bool {
        if region == .mexicanState {
            return viewModel.showMexicanStates
        }
        return true
    }
}

struct PlateGridItem: View {
    let plate: LicensePlate
    let isSpotted: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(isSpotted ? AppTheme.success.opacity(0.2) : AppTheme.warmLinen)

                VStack(spacing: AppTheme.Spacing.xs) {
                    Text(plate.code)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(isSpotted ? AppTheme.success : .primary)

                    Image(systemName: plate.rarityTier.icon)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(Color(plate.rarityTier.color))
                }
                .padding()

                if isSpotted {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.success)
                                .font(AppTheme.Typography.subsectionHeader)
                                .padding(AppTheme.Spacing.sm)
                        }
                        Spacer()
                    }
                }
            }
            .frame(height: 100)

            Text(plate.name)
                .font(AppTheme.Typography.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(isSpotted ? .primary : .secondary)
        }
    }
}

struct PlateListItem: View {
    let plate: LicensePlate
    let isSpotted: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Code badge
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .fill(isSpotted ? AppTheme.success.opacity(0.2) : AppTheme.warmLinen)
                    .frame(width: 60, height: 60)

                Text(plate.code)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(isSpotted ? AppTheme.success : .primary)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack {
                    Text(plate.name)
                        .font(AppTheme.Typography.cardTitle)

                    if isSpotted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.success)
                            .font(AppTheme.Typography.caption)
                    }
                }

                HStack(spacing: AppTheme.Spacing.sm) {
                    Label(plate.region.displayName, systemImage: plate.region.icon)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)

                    Image(systemName: plate.rarityTier.icon)
                        .font(AppTheme.Typography.tabLabel)
                        .foregroundStyle(Color(plate.rarityTier.color))

                    Text(plate.rarityTier.rawValue)
                        .font(AppTheme.Typography.tabLabel)
                        .foregroundStyle(Color(plate.rarityTier.color))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

struct FilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(AppTheme.Typography.caption)
                }
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(isSelected ? GameTheme.licensePlate.accentColor : AppTheme.warmLinen)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    PlateGridView(
        viewModel: LicensePlateViewModel(
            modelContext: ModelContext(
                try! ModelContainer(for: RoadTrip.self, SpottedPlate.self)
            )
        )
    )
}
