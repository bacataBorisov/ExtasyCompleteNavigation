import SwiftUI
import SwiftData
import CoreLocation

struct WaypointListView: View {
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var waypoints: [Waypoints]
    @State private var isAddingWaypoint = false
    @State private var selectedWaypoint: Waypoints?

    private var sortedWaypoints: [Waypoints] {
        waypoints.sorted { $0.title.lowercased() < $1.title.lowercased() }
    }

    var body: some View {
        VStack(spacing: 4) {
            if DeviceType.isIPhone {
                ZStack {
                    Text("Waypoints")
                        .font(.title3)
                        .frame(maxWidth: .infinity, alignment: .center)
                    HStack {
                        Button(action: { isAddingWaypoint.toggle() }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .padding()
                        }
                        .accessibilityLabel("Add Waypoint")
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            if waypoints.isEmpty {
                emptyStateView()
            } else {
                waypointListView()
            }
        }
        .if(DeviceType.isIPad) { view in
            view
                .navigationTitle("Waypoints")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { isAddingWaypoint.toggle() }) {
                            Image(systemName: "plus")
                                .font(.title2)
                        }
                        .accessibilityLabel("Add Waypoint")
                    }
                }
        }
        .sheet(isPresented: $isAddingWaypoint) {
            WaypointFillForm(waypoint: Waypoints())
        }
        .sheet(item: $selectedWaypoint) { waypoint in
            WaypointDetailedView(waypoint: waypoint)
        }
        .onChange(of: waypoints.count) {
            refreshView()
            debugLog("Waypoints updated, refreshing view.")
        }
    }

    private func refreshView() {
        displayedWaypoints = Array(sortedWaypoints.prefix(batchSize))
        currentBatchIndex = displayedWaypoints.count
    }

    // MARK: - Empty State View
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack {
            Image(systemName: "map.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No waypoints added yet.")
                .font(.title3)
                .foregroundColor(.secondary)
            Button(action: { isAddingWaypoint.toggle() }) {
                Text("Add Waypoint")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Waypoints List
    @ViewBuilder
    private func waypointListView() -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(sortedWaypoints, id: \.self) { waypoint in
                    waypointRow(waypoint)
                        .padding(.horizontal)
                        .contentShape(Rectangle()) // Ensure tappable area
                        .contextMenu {
                            waypointContextMenu(waypoint)
                        }

                    // Divider between rows
                    Divider()
                        .frame(height: 1)
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.systemBackground)) // Apply system background color
        .onAppear {
            loadInitialWaypoints()
        }
    }

    // MARK: - State for Pagination
    @State private var displayedWaypoints: [Waypoints] = []
    @State private var currentBatchIndex = 0
    private let batchSize = 50  // Number of waypoints to load at a time

    // MARK: - Pagination Logic
    private func loadInitialWaypoints() {
        displayedWaypoints = Array(sortedWaypoints.prefix(batchSize))
        currentBatchIndex = displayedWaypoints.count
    }

    private func loadMoreWaypointsIfNeeded(currentIndex: Int) {
        guard currentIndex == displayedWaypoints.count - 1 else { return }

        // Ensure we do not go out of bounds
        guard currentBatchIndex < sortedWaypoints.count else { return }

        let nextBatchEnd = min(currentBatchIndex + batchSize, sortedWaypoints.count)

        // Safely create the next batch range
        if currentBatchIndex < nextBatchEnd {
            let nextBatch = sortedWaypoints[currentBatchIndex..<nextBatchEnd]

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                displayedWaypoints.append(contentsOf: nextBatch)
                currentBatchIndex = nextBatchEnd
            }
        }
    }

    // MARK: - Waypoint Row
    private func waypointRow(_ waypoint: Waypoints) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(waypoint.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                if navigationReadings.gpsData?.isTargetSelected == true,
                   waypoint.lat == navigationReadings.gpsData?.waypointLocation?.latitude,
                   waypoint.lon == navigationReadings.gpsData?.waypointLocation?.longitude {
                    Text("Selected Target")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            Spacer()
        }
        .padding(.all, 10)
        .background(navigationReadings.gpsData?.isTargetSelected == true &&
                    waypoint.lat == navigationReadings.gpsData?.waypointLocation?.latitude &&
                    waypoint.lon == navigationReadings.gpsData?.waypointLocation?.longitude ? Color.green.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Context Menu
    private func waypointContextMenu(_ waypoint: Waypoints) -> some View {
        Group {
            Button {
                selectTarget(for: waypoint)
            } label: {
                Label("Select Target", systemImage: "scope")
            }

            if navigationReadings.gpsData?.isTargetSelected == true &&
                waypoint.lat == navigationReadings.gpsData?.waypointLocation?.latitude &&
                waypoint.lon == navigationReadings.gpsData?.waypointLocation?.longitude {
                Button {
                    deselectWaypoint()
                } label: {
                    Label("Deselect Target", systemImage: "xmark.circle")
                }
            }

            Button {
                selectedWaypoint = waypoint
            } label: {
                Label("View Info", systemImage: "info.circle")
            }

            Button(role: .destructive) {
                modelContext.delete(waypoint)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Target Selection Logic
    private func selectTarget(for waypoint: Waypoints) {
        guard let lat = waypoint.lat, let lon = waypoint.lon else {
            debugLog("Invalid waypoint coordinates. Selection aborted.")
            return
        }

        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        navigationReadings.waypointProcessor.resetWaypointCalculations()
        navigationReadings.gpsProcessor.updateMarker(to: coordinate, waypoint.title)
        navigationReadings.gpsData?.isTargetSelected = true
    }

    private func deselectWaypoint() {
        navigationReadings.waypointProcessor.resetWaypointCalculations()
        navigationReadings.gpsProcessor.gpsData.waypointLocation = nil
        navigationReadings.gpsProcessor.disableMarker()
    }
}

#Preview {
    WaypointListView()
        .environment(NMEAParser())
        .modelContainer(for: Waypoints.self)
}
