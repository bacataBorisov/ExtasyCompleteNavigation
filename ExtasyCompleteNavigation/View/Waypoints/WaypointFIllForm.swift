import SwiftUI

struct WaypointFillForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext // For SwiftData/ModelContainer
    @Environment(NMEAParser.self) private var navigationReadings // Access boat's GPS data
    @State var waypoint: Waypoints // This should be a `@Model` object for SwiftData
    
    var body: some View {
        Form {
            Section(header: Text("Waypoint Information")) {
                TextField("Name", text: $waypoint.title)
                TextField("Latitude", value: $waypoint.lat, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Longitude", value: $waypoint.lon, format: .number)
                    .keyboardType(.decimalPad)
            }
            
            Section {
                Button(action: fillWithBoatLocation) {
                    Label("Use Boat's Location", systemImage: "location.fill")
                }
            }
            
            Section {
                Button("Save") {
                    saveWaypoint()
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .foregroundColor(.red) // Optional: Red color for emphasis

            }
        }
        .navigationTitle("Add Waypoint")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Fill with Boat's Location
    private func fillWithBoatLocation() {
        guard let boatLocation = navigationReadings.gpsData?.boatLocation else {
            debugLog("Boat location not available.")
            return
        }
        
        waypoint.lat = boatLocation.latitude
        waypoint.lon = boatLocation.longitude
    }
    
    // MARK: - Save Waypoint Logic
    private func saveWaypoint() {
        // Add the waypoint to the model context for persistence
        modelContext.insert(waypoint) // Insert new waypoint
        
        do {
            try modelContext.save() // Save the context
            debugLog("Waypoint saved successfully.")
            dismiss() // Close the form
        } catch {
            debugLog("Failed to save waypoint: \(error.localizedDescription)")
        }
    }
}

#Preview {
    WaypointFillForm(waypoint: Waypoints(title: "", lat: nil, lon: nil))
        .modelContainer(for: Waypoints.self)
}
