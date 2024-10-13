//
//  VMGView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 14.01.24.
//

import SwiftUI
import CoreLocation
import SwiftData

struct VMGView: View {
    
    @Environment(NMEAReader.self) private var navigationReadings
    
    @Query private var lastUsedSettings: [NauticalDistance]
    @Query private var lastMarkAngle: [BearingToMarkUnitsMenu]
    @Query private var lastUsedDistanceForTack: [NextTackNauticalDistance]
    @Query private var lastUsedPoisiton: [SwitchCoordinatesView]
    
    var body: some View {
        GeometryReader { geometry in
            
            ZStack{
                HorizontalLine()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color("line_start"), Color("line_mid"), Color("line_end")]), startPoint: .leading, endPoint: .trailing))
                HorizontalLine()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color("line_start"), Color("line_mid"), Color("line_end")]), startPoint: .leading, endPoint: .trailing))
                    .rotationEffect(Angle(degrees: 180))
                HorizontalLine()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color("line_start"), Color("line_mid"), Color("line_end")]), startPoint: .leading, endPoint: .trailing))
                    .rotationEffect(Angle(degrees: 90))
                HorizontalLine()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color("line_start"), Color("line_mid"), Color("line_end")]), startPoint: .leading, endPoint: .trailing))
                    .rotationEffect(Angle(degrees: 270))
            }
            VStack{
                HStack{
                    BearingToMarkView(lastUsedUnit: lastMarkAngle.last ?? BearingToMarkUnitsMenu(angle: .relativeAngle))
                    
                    DistanceToWaypoint(lastUsedUnit: lastUsedSettings.last ?? NauticalDistance(distance: .boatLength))
                    
                    EstimatedTimeArrivalView(cell: displayCell[17], valueID: 17)
                    
                }
                HStack{
                    SmallDisplayCell(cell: displayCell[12], valueID: 12)
                    VMGtoWaypointView(cell: displayCell[13], valueID: 13)
                    SmallDisplayCell(cell: displayCell[14], valueID: 14)
                }
                HStack
                {
                    NextTackETAView(cell: displayCell[18], valueID: 18)
                    NextTackDistanceView(lastUsedUnit: lastUsedDistanceForTack.last ?? NextTackNauticalDistance(distance: .meters))
                    
                    CoordinatesView(lastUsedUnit: lastUsedPoisiton.last ??
                                    SwitchCoordinatesView(position: .waypointCoordinates))
                    
                }
            }
        }//END OF GEOMETRY READER
        .aspectRatio(1, contentMode: .fit)
    }//END OF BODY
}//END OF STRUCT


#Preview {
    
    VMGView()
        .environment(NMEAReader())
        .modelContainer(for: [
            //Matrix.self,
            UserSettingsMenu.self,
            NauticalDistance.self,
            BearingToMarkUnitsMenu.self,
            NextTackNauticalDistance.self,
            SwitchCoordinatesView.self
            //UltimateMatrix.self,
            //Waypoints.self
        ])
}
