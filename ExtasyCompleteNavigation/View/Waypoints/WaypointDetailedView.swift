//
//  WaypointDetailedView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 18.01.24.
//

import SwiftUI
import SwiftData
import MapKit

struct WaypointDetailedView: View {
    
    @Environment(NMEAParser.self) private var navigationReadings

    @Environment(\.dismiss) private var dismiss
    @Query private var waypoints: [Waypoints]
    @Bindable var waypoint: Waypoints
    @Namespace var mapScope
    
    var body: some View {
        NavigationStack{
            List{
                TextField("Waypoint Name", text: $waypoint.title)
                TextField("Latitude", value: $waypoint.lat, format: .number)
                TextField("Longitude", value: $waypoint.lon, format: .number)
                //something with check box - "Show on Map" - to be show on the map but without being VMG target
                Button("Set as VMG Target") {
                    
                    //disable all the previous active targets selected
                    for waypoint in waypoints {
                        waypoint.isTargetSelected = false
                    }
                    //if coordinates are correct enable the new one
                    if  let lat = waypoint.lat,
                        let lon = waypoint.lon
                    {
                        waypoint.isTargetSelected = true // used to be shown on the map
                        
                        //send coordinates for the selected mark
                        let newCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        navigationReadings.vmgProcessor.updateMarkerCoordinate(to: newCoordinate)
                        
                        navigationReadings.isVMGSelected = true //start VMG Calculations
                    }
                }
                Button("Cancel VMG"){
                    
                    navigationReadings.isVMGSelected = false
                    navigationReadings.vmgProcessor.resetVMGCalculations()
                    waypoint.isTargetSelected = false // hide the mark on the map
                    
                    
                }
            }
        }
        .navigationTitle(waypoint.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WaypointDetailedView(waypoint: Waypoints())
            .modelContainer(for: Waypoints.self)
            .environment(NMEAParser())
    }
}
