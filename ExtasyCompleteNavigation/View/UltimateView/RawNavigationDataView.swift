/*
 This view will remain as it is. Since it is very simple, I will not incorporate a separate ViewModel or it. In case it gets more complex, consider creating a ViewModel for it.
 
 VB - 15-Nov-2024
 
 */

import SwiftUI

struct RawNavigationDataView: View {
    
    @Environment(NMEAParser.self) private var navigationReadings
    
    var body: some View {
        List {
            Section(header: Text("Navigation data from Instruments").font(.title)) {
                dataGroup(header: "Depth", value: navigationReadings.hydroData?.depth, unit: " mtrs")
                dataGroup(header: "Heading", value: navigationReadings.compassData?.normalizedHeading, unit: "")
                dataGroup(header: "Total Distance Travelled", value: navigationReadings.hydroData?.totalDistance, unit: "")
                dataGroup(header: "Distance Since Last Reset", value: navigationReadings.hydroData?.distSinceReset, unit: "")
                dataGroup(header: "Sea Water Temperature", value: navigationReadings.hydroData?.seaWaterTemperature, unit: "°C")
                dataGroup(header: "Speed (SpeedLog)", value: navigationReadings.hydroData?.boatSpeedLag, unit: " kn")
                dataGroup(header: "AWA", value: navigationReadings.windData?.apparentWindAngle, unit: "°")
                dataGroup(header: "AWS", value: navigationReadings.windData?.apparentWindForce, unit: " kn")
                dataGroup(header: "TWA", value: navigationReadings.windData?.trueWindAngle, unit: "°")
                dataGroup(header: "TWS", value: navigationReadings.windData?.trueWindForce, unit: " kn")
                dataGroup(header: "Polar Speed (pSPD)", value: navigationReadings.vmgData?.polarSpeed, unit: " kn")
                dataGroup(header: "Polar VMG", value: navigationReadings.vmgData?.polarVMG, unit: "")
                dataGroup(header: "Opt Angle UpWind", value: navigationReadings.vmgData?.optimalUpTWA, unit: "°")
                dataGroup(header: "Opt Angle DownWind", value: navigationReadings.vmgData?.optimalDnTWA, unit: "°")
                dataGroup(header: "Max VMG UpWind", value: navigationReadings.vmgData?.maxUpVMG, unit: " kn")
                dataGroup(header: "Max VMG DownWind", value: navigationReadings.vmgData?.maxDnVMG, unit: " kn")



            }
            .font(.subheadline)
            
            Section(header: Text("GPS Data").font(.title)) {
                dataGroup(header: "Time UTC", value: navigationReadings.gpsData?.utcTime, unit: "")
                dataGroup(header: "Date", value: navigationReadings.gpsData?.gpsDate, unit: "")
                dataGroup(header: "Latitude", value: navigationReadings.gpsData?.latitude, unit: "")
                dataGroup(header: "Longitude", value: navigationReadings.gpsData?.longitude, unit: "")
                dataGroup(header: "Course Over Ground", value: navigationReadings.gpsData?.courseOverGround, unit: "°")
                dataGroup(header: "Speed Over Ground", value: navigationReadings.gpsData?.speedOverGround, unit: " kn")
                dataGroup(header: "Current VMC", value: navigationReadings.waypointData?.currentTackVMC, unit: "")
                dataGroup(header: "Distance to Waypoint", value: navigationReadings.waypointData?.distanceToMark, unit: "")
                dataGroup(header: "ETA to Waypoint", value: navigationReadings.waypointData?.etaToWaypoint, unit: "")
                dataGroup(header: "ETA to Next Tack", value: navigationReadings.waypointData?.etaToNextTack, unit: "")

            }
            .font(.subheadline)
        }
        .navigationTitle("Raw Navigation Data")
    }
    
    private func dataGroup<T>(header: String, value: T?, unit: String) -> some View {
        Group {
            if let value = value {
                Text("\(header): \(value)\(unit)")
            } else {
                Text("\(header): ---")
            }
        }
    }
}

#Preview {
    RawNavigationDataView()
        .environment(NMEAParser())
}
