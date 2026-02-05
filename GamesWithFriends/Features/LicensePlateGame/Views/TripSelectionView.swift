//
//  TripSelectionView.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct TripSelectionView: View {
    @Bindable var viewModel: LicensePlateViewModel
    @State private var showingNewTripSheet = false
    @State private var newTripName = ""
    @State private var newTripNotes = ""

    var body: some View {
        List {
            if let activeTrip = viewModel.currentTrip, activeTrip.isActive {
                Section {
                    TripRowView(trip: activeTrip, isActive: true)
                        .onTapGesture {
                            // Already active, dismiss
                        }
                } header: {
                    Text("Active Trip")
                }
            }

            Section {
                Button {
                    showingNewTripSheet = true
                } label: {
                    Label("Start New Trip", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
            }

            if !viewModel.trips.isEmpty {
                Section("All Trips") {
                    ForEach(viewModel.trips) { trip in
                        TripRowView(trip: trip, isActive: trip.id == viewModel.currentTrip?.id)
                            .onTapGesture {
                                viewModel.setActiveTrip(trip)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deleteTrip(trip)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                if trip.isOngoing {
                                    Button {
                                        viewModel.endTrip(trip)
                                    } label: {
                                        Label("End Trip", systemImage: "flag.checkered")
                                    }
                                    .tint(.orange)
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Select Trip")
        .sheet(isPresented: $showingNewTripSheet) {
            NavigationStack {
                NewTripForm(
                    tripName: $newTripName,
                    tripNotes: $newTripNotes,
                    onCreate: {
                        viewModel.createTrip(name: newTripName, notes: newTripNotes)
                        newTripName = ""
                        newTripNotes = ""
                        showingNewTripSheet = false
                    },
                    onCancel: {
                        showingNewTripSheet = false
                        newTripName = ""
                        newTripNotes = ""
                    }
                )
            }
        }
    }
}

struct TripRowView: View {
    let trip: RoadTrip
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trip.name)
                    .font(.headline)

                Spacer()

                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            HStack {
                Label("\(trip.totalSpotted) spotted", systemImage: "car.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(trip.startDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if trip.totalSpotted > 0 {
                ProgressView(value: Double(trip.totalSpotted), total: Double(PlateData.allPlates.count))
                    .tint(.blue)
            }

            if let notes = trip.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct NewTripForm: View {
    @Binding var tripName: String
    @Binding var tripNotes: String
    let onCreate: () -> Void
    let onCancel: () -> Void

    var body: some View {
        Form {
            Section("Trip Details") {
                TextField("Trip Name", text: $tripName)
                    .autocapitalization(.words)

                TextField("Notes (optional)", text: $tripNotes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Button("Create Trip") {
                    onCreate()
                }
                .disabled(tripName.trimmingCharacters(in: .whitespaces).isEmpty)

                Button("Cancel", role: .cancel) {
                    onCancel()
                }
            }
        }
        .navigationTitle("New Trip")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TripSelectionView(
            viewModel: LicensePlateViewModel(
                modelContext: ModelContext(
                    try! ModelContainer(for: RoadTrip.self, SpottedPlate.self)
                )
            )
        )
    }
}
