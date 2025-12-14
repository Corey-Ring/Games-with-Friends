//
//  LicensePlateGameView.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct LicensePlateGameView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: LicensePlateViewModel?
    @State private var showingTripSelection = false
    @State private var showingSettings = false

    var body: some View {
        Group {
            if let viewModel = viewModel {
                mainContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = LicensePlateViewModel(modelContext: modelContext)
            }
        }
    }

    @ViewBuilder
    private func mainContent(viewModel: LicensePlateViewModel) -> some View {
        if viewModel.currentTrip == nil {
            noTripView(viewModel: viewModel)
        } else {
            gameView(viewModel: viewModel)
        }
    }

    private func noTripView(viewModel: LicensePlateViewModel) -> some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "car.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                VStack(spacing: 12) {
                    Text("Ready for a Road Trip?")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Create a trip to start spotting license plates from all 50 states and beyond!")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                VStack(spacing: 16) {
                    NavigationLink {
                        TripSelectionView(viewModel: viewModel)
                    } label: {
                        Label("Start New Trip", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if !viewModel.trips.isEmpty {
                        NavigationLink {
                            TripSelectionView(viewModel: viewModel)
                        } label: {
                            Label("Select Existing Trip", systemImage: "list.bullet")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .foregroundStyle(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle("License Plate Game")
        }
    }

    private func gameView(viewModel: LicensePlateViewModel) -> some View {
        let bindableViewModel = Bindable(viewModel)

        return NavigationStack {
            VStack(spacing: 0) {
                // Current Trip Header
                if let trip = viewModel.currentTrip {
                    TripHeaderView(trip: trip, viewModel: viewModel)
                        .padding()
                        .background(Color(.systemGray6))
                }

                // Main Content
                PlateGridView(viewModel: viewModel)
            }
            .navigationTitle("License Plate Game")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showingTripSelection = true
                        } label: {
                            Label("Switch Trip", systemImage: "arrow.left.arrow.right")
                        }

                        Button {
                            viewModel.viewMode = viewModel.viewMode == .grid ? .list : .grid
                        } label: {
                            Label(
                                viewModel.viewMode == .grid ? "List View" : "Grid View",
                                systemImage: viewModel.viewMode == .grid ? "list.bullet" : "square.grid.2x2"
                            )
                        }

                        Divider()

                        NavigationLink {
                            TripStatsView(viewModel: viewModel)
                        } label: {
                            Label("Trip Stats", systemImage: "chart.bar.fill")
                        }

                        NavigationLink {
                            LifetimeStatsView(viewModel: viewModel)
                        } label: {
                            Label("Lifetime Stats", systemImage: "chart.line.uptrend.xyaxis")
                        }

                        NavigationLink {
                            AchievementsView(viewModel: viewModel)
                        } label: {
                            Label("Achievements", systemImage: "trophy.fill")
                        }

                        Divider()

                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
            }
            .sheet(isPresented: $showingTripSelection) {
                NavigationStack {
                    TripSelectionView(viewModel: viewModel)
                }
            }
            .sheet(item: bindableViewModel.selectedPlate) { plate in
                NavigationStack {
                    PlateDetailView(plate: plate, viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    LicensePlateSettingsView(viewModel: viewModel)
                }
            }
        }
    }
}

struct TripHeaderView: View {
    let trip: RoadTrip
    @Bindable var viewModel: LicensePlateViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.name)
                        .font(.headline)

                    Text("Started \(trip.startDate, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(trip.totalSpotted)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)

                    Text("spotted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * viewModel.tripProgress(), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Label("\(trip.usStatesSpotted)/51 US", systemImage: "flag.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                if viewModel.showMexicanStates {
                    Text("\(trip.totalPoints) points")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct LicensePlateSettingsView: View {
    @Bindable var viewModel: LicensePlateViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newMemberName = ""
    @State private var showingAddMember = false

    var body: some View {
        Form {
            Section {
                Toggle("Show Mexican States", isOn: $viewModel.showMexicanStates)
                    .onChange(of: viewModel.showMexicanStates) {
                        viewModel.saveSettings()
                    }
            } header: {
                Text("Game Options")
            } footer: {
                Text("Enable to track license plates from all 32 Mexican states")
            }

            Section {
                ForEach(viewModel.familyMembers, id: \.self) { member in
                    HStack {
                        Text(member)
                        Spacer()
                        Button(role: .destructive) {
                            viewModel.removeFamilyMember(member)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }

                Button {
                    showingAddMember = true
                } label: {
                    Label("Add Family Member", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Family Members")
            } footer: {
                Text("Track who spotted each plate for friendly competition")
            }

            Section("About") {
                LabeledContent("Total Plates Available", value: "\(viewModel.availablePlates().count)")
                LabeledContent("View Mode", value: viewModel.viewMode.rawValue)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert("Add Family Member", isPresented: $showingAddMember) {
            TextField("Name", text: $newMemberName)
                .autocapitalization(.words)

            Button("Add") {
                if !newMemberName.trimmingCharacters(in: .whitespaces).isEmpty {
                    viewModel.addFamilyMember(newMemberName.trimmingCharacters(in: .whitespaces))
                    newMemberName = ""
                }
            }

            Button("Cancel", role: .cancel) {
                newMemberName = ""
            }
        }
    }
}

#Preview {
    LicensePlateGameView()
        .modelContainer(for: [RoadTrip.self, SpottedPlate.self], inMemory: true)
}
