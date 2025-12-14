//
//  PlateDetailView.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct PlateDetailView: View {
    let plate: LicensePlate
    @Bindable var viewModel: LicensePlateViewModel
    @State private var showingSpotSheet = false
    @State private var showingUnspotConfirmation = false

    private var isSpotted: Bool {
        viewModel.isPlateSpotted(plate)
    }

    private var spottedPlate: SpottedPlate? {
        viewModel.currentTrip?.getSpottedPlate(code: plate.code)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                VStack(spacing: 16) {
                    Text(plate.code)
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(isSpotted ? .green : .blue)

                    Text(plate.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    if let nickname = plate.nickname {
                        Text(nickname)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Image(systemName: plate.region.icon)
                                .font(.title3)
                            Text(plate.region.displayName)
                                .font(.caption)
                        }

                        Divider()
                            .frame(height: 40)

                        VStack(spacing: 4) {
                            Image(systemName: plate.rarityTier.icon)
                                .font(.title3)
                                .foregroundStyle(Color(plate.rarityTier.color))
                            Text(plate.rarityTier.rawValue)
                                .font(.caption)
                                .foregroundStyle(Color(plate.rarityTier.color))
                        }
                    }
                    .padding(.top, 8)

                    if isSpotted {
                        Label("Spotted", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.regularMaterial)
                )
                .padding(.horizontal)

                // Details
                VStack(alignment: .leading, spacing: 20) {
                    DetailSection(title: "Capital", icon: "building.2.fill") {
                        Text(plate.capital)
                    }

                    DetailSection(title: "Fun Fact", icon: "lightbulb.fill") {
                        Text(plate.funFact)
                    }

                    if let spotted = spottedPlate {
                        Divider()

                        DetailSection(title: "Spotted Information", icon: "clock.fill") {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Date:")
                                        .foregroundStyle(.secondary)
                                    Text(spotted.spottedAt, style: .date)
                                }

                                HStack {
                                    Text("Time:")
                                        .foregroundStyle(.secondary)
                                    Text(spotted.spottedAt, style: .time)
                                }

                                if let spottedBy = spotted.spottedBy {
                                    HStack {
                                        Text("Spotted by:")
                                            .foregroundStyle(.secondary)
                                        Text(spottedBy)
                                    }
                                }

                                if let location = spotted.locationDescription {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Location:")
                                            .foregroundStyle(.secondary)
                                        Text(location)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Action Button
                if isSpotted {
                    Button(role: .destructive) {
                        showingUnspotConfirmation = true
                    } label: {
                        Label("Unspot", systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                } else {
                    Button {
                        showingSpotSheet = true
                    } label: {
                        Label("Mark as Spotted", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSpotSheet) {
            SpotPlateView(plate: plate, viewModel: viewModel)
        }
        .confirmationDialog(
            "Unspot \(plate.name)?",
            isPresented: $showingUnspotConfirmation,
            titleVisibility: .visible
        ) {
            Button("Unspot", role: .destructive) {
                viewModel.unspotPlate(plate)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \(plate.name) from your spotted plates.")
        }
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.blue)

            content
                .font(.body)
        }
    }
}

#Preview {
    NavigationStack {
        PlateDetailView(
            plate: PlateData.usStates[0],
            viewModel: LicensePlateViewModel(
                modelContext: ModelContext(
                    try! ModelContainer(for: RoadTrip.self, SpottedPlate.self)
                )
            )
        )
    }
}
