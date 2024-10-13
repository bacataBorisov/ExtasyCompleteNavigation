import SwiftUI

struct RawNavigationData: View {
    
    @Environment(NMEAReader.self) private var navigationReadings
    
    var body: some View {
        List {
            Section(header: Text("Navigation data from Instruments").font(.title)) {
                dataGroup(header: "Depth", value: navigationReadings.depth, unit: " mtrs")
                dataGroup(header: "Heading", value: navigationReadings.hdgForDisplayAndCalculation, unit: "")
                dataGroup(header: "Total Distance Travelled", value: navigationReadings.totalDistance, unit: "")
                dataGroup(header: "Distance Since Last Reset", value: navigationReadings.distSinceReset, unit: "")
                dataGroup(header: "Sea Water Temperature", value: navigationReadings.seaWaterTemperature, unit: "°C")
                dataGroup(header: "Speed (SpeedLog)", value: navigationReadings.boatSpeedLag, unit: " kn")
                dataGroup(header: "AWA", value: navigationReadings.appWindAngle, unit: "°")
                dataGroup(header: "AWS", value: navigationReadings.appWindForce, unit: " kn")
                dataGroup(header: "TWA", value: navigationReadings.trueWindAngle, unit: "°")
                dataGroup(header: "TWS", value: navigationReadings.trueWindForce, unit: " kn")
            }
            .font(.subheadline)
            
            Section(header: Text("GPS Data").font(.title)) {
                dataGroup(header: "Time UTC", value: navigationReadings.utcTime, unit: "")
                dataGroup(header: "Date", value: navigationReadings.gpsDate, unit: "")
                dataGroup(header: "Latitude", value: navigationReadings.lat, unit: "")
                dataGroup(header: "Longitude", value: navigationReadings.lon, unit: "")
                dataGroup(header: "Course Over Ground", value: navigationReadings.courseOverGround, unit: "°")
                dataGroup(header: "Speed Over Ground", value: navigationReadings.speedOverGround, unit: " kn")
                dataGroup(header: "Polar Speed (pSPD)", value: navigationReadings.polarSpeed, unit: " kn")
                dataGroup(header: "Polar VMG", value: navigationReadings.polarVMG, unit: "")
                dataGroup(header: "Current VMC", value: navigationReadings.waypointVMC, unit: "")
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
    RawNavigationData()
        .environment(NMEAReader())
}
