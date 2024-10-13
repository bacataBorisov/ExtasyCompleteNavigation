//
//  WaypointCoordinatesView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 3.02.24.
//

import SwiftUI
import SwiftData

struct CoordinatesView: View {
    
    @Environment(NMEAReader.self) private var navigationReadings
    @Environment(\.modelContext) private var context
    @Bindable var lastUsedUnit: SwitchCoordinatesView
    
    var body: some View {
        
        GeometryReader{ geometry in
            
            let width = geometry.size.width
            
            ZStack{
                
                switch lastUsedUnit.position {
                case .boatCoordinates:
                    Text("BPOS")
                        .frame(width: width, height: width, alignment: .topLeading)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
                    
                    if let lat = navigationReadings.lat, let lon = navigationReadings.lon {
                        
                        //TODO: - Need to play a little bit with the font size - it has to be dynamic
                        VStack{
                            Text(String(format: "%.4f", lat))
                            Text(String(format: "%.4f", lon))
                        }
                        .frame(width: width, height: width, alignment: .center)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.20))

                    }
                    
                    
                case .waypointCoordinates:
                    Text("WPPOS")
                        .frame(width: width, height: width, alignment: .top)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
                    
                    
                    if let lat = navigationReadings.markerCoordinate?.latitude, let lon = navigationReadings.markerCoordinate?.longitude {
                        
                        //TODO: - Need to play a little bit with the font size - it has to be dynamic
                        VStack{
                            Text(String(format: "%.4f", lat))
                            Text(String(format: "%.4f", lon))
                        }
                        .frame(width: width, height: width, alignment: .center)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.20))

                    }
                }
            }//END OF ZSTACK
            
            .padding(.top, 5)
            .onTapGesture {
                switch lastUsedUnit.position {
                case .boatCoordinates:
                    lastUsedUnit.position = .waypointCoordinates
                    context.insert(lastUsedUnit)
                    
                case .waypointCoordinates:
                    lastUsedUnit.position = .boatCoordinates
                    context.insert(lastUsedUnit)
                    
                }
            }
        }//END OF GEOMETRY READER
        .aspectRatio(1, contentMode: .fit)
        .foregroundStyle(Color("display_font"))
    }
}
    

#Preview {
    CoordinatesView(lastUsedUnit: SwitchCoordinatesView())
        .environment(NMEAReader())
}
