//
//  SpotPlateView.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct SpotPlateView: View {
    let plate: LicensePlate
    @Bindable var viewModel: LicensePlateViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFamilyMember: String?
    @State private var locationDescription = ""
    @State private var showCelebration = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 12) {
                        Text(plate.code)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.blue)

                        Text(plate.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        if let nickname = plate.nickname {
                            Text(nickname)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 16) {
                            Label(plate.region.displayName, systemImage: plate.region.icon)
                                .font(.caption)

                            Label(plate.rarityTier.rawValue, systemImage: plate.rarityTier.icon)
                                .font(.caption)
                                .foregroundStyle(Color(plate.rarityTier.color))
                        }
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }

                if !viewModel.familyMembers.isEmpty {
                    Section("Who spotted it?") {
                        Picker("Spotter", selection: $selectedFamilyMember) {
                            Text("Not specified").tag(nil as String?)
                            ForEach(viewModel.familyMembers, id: \.self) { member in
                                Text(member).tag(member as String?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("Location (optional)") {
                    TextField("Where did you spot it?", text: $locationDescription)
                        .autocapitalization(.sentences)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Fun Fact", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)

                        Text(plate.funFact)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button {
                        spotPlate()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Spotted!", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Spot Plate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if showCelebration {
                    CelebrationView(plate: plate)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    private func spotPlate() {
        viewModel.spotPlate(
            plate,
            spottedBy: selectedFamilyMember,
            locationDescription: locationDescription.isEmpty ? nil : locationDescription
        )

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showCelebration = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            dismiss()
        }
    }
}

struct CelebrationView: View {
    let plate: LicensePlate

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)

                VStack(spacing: 8) {
                    Text("Spotted!")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(plate.name)
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    if plate.rarityTier == .rare || plate.rarityTier == .ultraRare {
                        HStack(spacing: 4) {
                            Image(systemName: plate.rarityTier.icon)
                            Text(plate.rarityTier.rawValue + "!")
                        }
                        .font(.headline)
                        .foregroundStyle(Color(plate.rarityTier.color))
                        .padding(.top, 8)
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
            )
            .padding(40)
        }
    }
}

#Preview {
    SpotPlateView(
        plate: PlateData.usStates[0],
        viewModel: LicensePlateViewModel(
            modelContext: ModelContext(
                try! ModelContainer(for: RoadTrip.self, SpottedPlate.self)
            )
        )
    )
}
