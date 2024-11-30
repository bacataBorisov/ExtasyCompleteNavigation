
//
//  WaypointDetailedView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 18.01.24.
//

import SwiftUI
import SwiftData

struct WaypointFIllForm: View {
    

    @Environment(\.dismiss) private var dismiss
    @Bindable var waypoint: Waypoints
    @Environment(\.modelContext) private var modelContext
    @Environment(NMEAParser.self) private var navigationReadings
    
    
    var body: some View {
        NavigationStack{
            List{
                TextField("Waypoint Name", text: $waypoint.title)
                TextField("Latitude", value: $waypoint.lat, format: .number)
                TextField("Longitude", value: $waypoint.lon, format: .number)
                Button("Capture Boat's Coordinates") {

                    if let gpsData = navigationReadings.gpsData {
                        waypoint.lat = gpsData.latitude
                        waypoint.lon = gpsData.longitude
                    }
                }
                Button("Cancel", role: .destructive) {
                    dismiss()
                }
            }
        }
        .navigationTitle("Add New Waypoint")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {

                    modelContext.insert(waypoint)
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WaypointFIllForm(waypoint: Waypoints())
            .modelContainer(for: Waypoints.self)
            .environment(NMEAParser())
    }
}
