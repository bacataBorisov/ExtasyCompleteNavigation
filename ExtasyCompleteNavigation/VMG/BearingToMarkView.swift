//
//  BearingToMarkView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 7.02.24.
//

import SwiftUI
import SwiftData



struct BearingToMarkView: View {
    
    @Environment(NMEAReader.self) private var navigationReadings
    @Environment(\.modelContext) private var context
    
    @Bindable var lastUsedUnit: BearingToMarkUnitsMenu
    
    var body: some View {
        GeometryReader{ geometry in
            
            let width = geometry.size.width
            
            ZStack{
                
                Text("BTW")
                    .frame(width: width, height: width, alignment: .topLeading)
                    .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
                
                
                switch lastUsedUnit.angle {
                case .relativeAngle:
                    Text("°R")
                        .frame(width: width, height: width, alignment: .topTrailing)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
                    
                    
                    Text(String(format: "%.f", navigationReadings.relativeMarkBearing))
                        .frame(width: width, height: width, alignment: .center)
                        .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.4))
                    
                    
                case .trueAngle:
                    Text("°T")
                        .frame(width: width, height: width, alignment: .topTrailing)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
                    
                    
                    Text(String(format: "%.f", navigationReadings.trueMarkBearing))
                        .frame(width: width, height: width, alignment: .center)
                        .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.4))
                }
            }//END OF ZSTACK
            //just toggle the states
            .padding(.top, 5)
            .onTapGesture {
                switch lastUsedUnit.angle {
                case .relativeAngle:
                    lastUsedUnit.angle = .trueAngle
                    context.insert(lastUsedUnit)
                    
                case .trueAngle:
                    lastUsedUnit.angle = .relativeAngle
                    context.insert(lastUsedUnit)
                    
                }
            }
        }//END OF GEOMETRY READER
        .aspectRatio(1, contentMode: .fit)
        .foregroundStyle(Color("display_font"))
    }//END OF BODY
}//END OF STRUCT

#Preview {
    BearingToMarkView(lastUsedUnit: BearingToMarkUnitsMenu())
        .environment(NMEAReader())
        .modelContainer(for: BearingToMarkUnitsMenu.self)
}
