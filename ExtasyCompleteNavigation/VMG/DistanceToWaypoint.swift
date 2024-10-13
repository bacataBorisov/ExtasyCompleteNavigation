//
//  DistanceToWaypoint.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 7.02.24.
//

import SwiftUI
import SwiftData

struct DistanceToWaypoint: View {
    
    @Environment(NMEAReader.self) private var navigationReadings
    
    @Environment(\.modelContext) private var context
    @Bindable var lastUsedUnit: NauticalDistance

    var body: some View {
        GeometryReader{ geometry in
            
            let width = geometry.size.width
            
            ZStack{
                
                Text("DTW")
                    .frame(width: width, height: width, alignment: .topLeading)
                    .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
                    
                
                switch lastUsedUnit.distance {
                case .nauticalMiles:
                    Text("nmi")
                        .frame(width: width, height: width, alignment: .topTrailing)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))

                    Text(String(format: "%.f", (navigationReadings.distance ?? 0) * toNauticalMiles))
                        .frame(width: width, height: width, alignment: .center)
                        .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.4))
                      
                    
                case .nauticalCables:
                    
                    Text("cab")
                        .frame(width: width, height: width, alignment: .topTrailing)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
                        
                    
                    Text(String(format: "%.f", (navigationReadings.distance ?? 0) * toNauticalCables))
                        .frame(width: width, height: width, alignment: .center)
                        .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.4))
                case .meters:
                    Text("mtrs")
                        .frame(width: width, height: width, alignment: .topTrailing)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))

                    Text(String(format: "%.f", navigationReadings.distance ?? 0))
                        .frame(width: width, height: width, alignment: .center)
                        .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.4))
                        
                    
                case .boatLength:
                    Text("bLEN")
                        .frame(width: width, height: width, alignment: .topTrailing)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
                        
                    
                    Text(String(format: "%.f", (navigationReadings.distance ?? 0) * toBoatLengths))
                        .frame(width: width, height: width, alignment: .center)
                        .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.4))
                    
                }
                
            }//END OF ZSTACK
            .minimumScaleFactor(0.2)
            //just toggle the states
            .padding(.top, 5)
            .onTapGesture(perform: {
                switch lastUsedUnit.distance {
                case .nauticalMiles:
                    lastUsedUnit.distance = .nauticalCables
                    context.insert(lastUsedUnit)
                case .nauticalCables:
                    lastUsedUnit.distance = .meters
                    context.insert(lastUsedUnit)
                case .meters:
                    lastUsedUnit.distance = .boatLength
                    context.insert(lastUsedUnit)
                case .boatLength:
                    lastUsedUnit.distance = .nauticalMiles
                    context.insert(lastUsedUnit)
                }
            })
            
        }//END OF GEOMETRY READER
        .aspectRatio(1, contentMode: .fit)
        .foregroundStyle(Color("display_font"))
    }//END OF BODY
}

#Preview {
    DistanceToWaypoint(lastUsedUnit: NauticalDistance())
        .environment(NMEAReader())
        .modelContainer(for: NauticalDistance.self)
}
