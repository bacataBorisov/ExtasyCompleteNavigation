//
//  RawNavigationData.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 14.09.23.
//

import SwiftUI


struct RawNavigationData: View {
    
    @Environment(NMEAReader.self) private var navigationReadings
    
    var body: some View {
        
        //Data from instruments
        List{
            Text("Navigation data from Instruments")
                .font(.title)
            Group{
                if let depth = navigationReadings.depth {
                    Text("Depth: \(depth)")
                } else {
                    Text("Depth: --- ")
                }
                if let heading = navigationReadings.hdgForDisplayAndCalculation {
                    Text("Heading: \(heading)")
                } else {
                    Text("Heading: --- ")
                }
                if let travelledDistance = navigationReadings.totalDistance {
                    Text("Total Distance Travelled: \(travelledDistance)")
                } else {
                    Text("Total Distance Travelled: ----- ")
                }
                if let distanceSinceReset = navigationReadings.distSinceReset {
                    Text("Distance Since Last Reset: \(distanceSinceReset)")
                } else {
                    Text("Distance Since Last Reset: ----- ")
                }
                if let waterTemp = navigationReadings.seaWaterTemperature {
                    Text("Sea Water Temperature: \(waterTemp)")
                } else {
                    Text("Sea Water Temperature: --.-")
                }
                if let boatSpeed = navigationReadings.boatSpeedLag {
                    Text("Speed (SpeedLog): \(boatSpeed)")
                } else {
                    Text("Speed (SppedLog): --.--")
                }
                if let appWingAngle = navigationReadings.appWindAngle {
                    Text("AWA: \(appWingAngle)")
                } else {
                    Text("AWA: ---")
                }
                if let appWingSpeed = navigationReadings.appWindForce {
                    Text("AWS: \(appWingSpeed)")
                } else {
                    Text("AWS: --.-")
                }
                if let trueWingAngle = navigationReadings.trueWindAngle {
                    Text("TWA: \(trueWingAngle)")
                } else {
                    Text("TWA: ---")
                }
                if let trueWingSpeed = navigationReadings.trueWindForce {
                    Text("TWS: \(trueWingSpeed)")
                } else {
                    Text("TWS: --.-")
                }
                
            }
            .font(.subheadline)
            
            Text("GPS Data")
                .font(.title)
            Group{
                if let utcTime = navigationReadings.utcTime {
                    Text("Time UTC: \(utcTime)")
                } else {
                    Text("Time UTC: --:--:--")
                }
                if let date = navigationReadings.gpsDate {
                    Text("Date: \(date)")
                } else {
                    Text("Date: --/---/----")
                }
                if let lat = navigationReadings.lat {
                    Text("Latitude: \(lat)")
                } else {
                    Text("Latitude: --.----")
                }
                if let lon = navigationReadings.lon {
                    Text("Longtitude: .2f\(lon)")
                } else {
                    Text("Longtitude: --.----")
                }
                if let cog = navigationReadings.courseOverGround {
                    Text("Course Over Ground: \(cog)")
                } else {
                    Text("Course Over Ground: ---")
                }
                if let sog = navigationReadings.speedOverGround {
                    Text("Speed Over Ground: \(sog)")
                } else {
                    Text("Speed Over Ground: --.--")
                }
                if let polarSpeed = navigationReadings.polarSpeed {
                    Text("Polar Speed (pSPD): \(polarSpeed)")
                } else {
                    Text("Polar Speed (pSPD): --.--")
                }
                if let polarVMG = navigationReadings.polarVMG {
                    Text("Polar VMG: \(polarVMG)")
                } else {
                    Text("Polar VMG: --.-")
                }
                if let curVMC = navigationReadings.waypointVMC {
                    Text("Current VMC: \(curVMC)")
                } else {
                    Text("Current VMC: --.-")
                }
            }
            .font(.subheadline)
        }
        //END OF VSTACK
        .navigationTitle("Raw Navigation Data")
    }//END OF BODY
}//END OF STRUCT

#Preview {
    RawNavigationData()
        .environment(NMEAReader())
}
