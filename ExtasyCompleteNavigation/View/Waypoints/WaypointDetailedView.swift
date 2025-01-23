import SwiftUI

struct WaypointDetailedView: View {
    @Bindable var waypoint: Waypoints
    @Environment(\.dismiss) private var dismiss
    @Environment(NMEAParser.self) private var navigationReadings // Access boat's GPS data
    
    // Store the original latitude and longitude to allow reverting
    @State private var originalLat: Double?
    @State private var originalLon: Double?
    
    var body: some View {
        Form {
            Section(header: Text("Waypoint Details")) {
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
                Button(action: revertToOriginalCoordinates) {
                    Label("Cancel Changes", systemImage: "arrow.uturn.backward")
                        .foregroundColor(.red) // Optional: Red color for emphasis
                }
            }
            
            Section {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            // Store the original coordinates when the view appears
            originalLat = waypoint.lat
            originalLon = waypoint.lon
        }
        .navigationTitle(waypoint.title)
        .navigationBarTitleDisplayMode(.inline)
        .padding()
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
    
    // MARK: - Revert to Original Coordinates
    private func revertToOriginalCoordinates() {
        guard let originalLat = originalLat, let originalLon = originalLon else {
            debugLog("Original coordinates not available.")
            return
        }
        
        waypoint.lat = originalLat
        waypoint.lon = originalLon
    }
}
