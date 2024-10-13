//
//  VMGtoWaypointView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 3.02.24.
//

import SwiftUI

struct VMGtoWaypointView: View {
    //MARK: - View Section Variables
    let tooGoodColor = EllipticalGradient(colors:[Color(UIColor.systemMint), Color(UIColor.systemGreen), Color(UIColor.systemBackground)])
    let tooBadColor = EllipticalGradient(colors:[Color(UIColor.systemRed), Color(UIColor.systemBackground)])
    
    @State var goodResult: Bool = false
    
    @Environment(NMEAReader.self) private var navigationReadings
    
    var cell: MultiDisplayCells
    var valueID: Int
    
    var body: some View {
        
        GeometryReader{ geometry in
            
            let width = geometry.size.width
            
            ZStack{
                Group{
                    Text(cell.name)
                        .frame(width: width, height: width, alignment: .topLeading)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
                    Text(cell.units)
                        .frame(width: width, height: width, alignment: .topTrailing)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
                    
                    
                    if let unwrappedValue = navigationReadings.waypointVMC{
                        Text(String(format: cell.specifier, unwrappedValue))
                            .frame(width: width, height: width, alignment: .center)
                            .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.4))
                    }
                }
                .padding(.top, 5)
            }//END OF ZSTACK
        }//END OF GEOMETRY READER
        //MARK: - Trigger Depth Alarm
        .onChange(of: navigationReadings.waypointVMC) { oldValue , newValue in
            if newValue != nil {
                if let value = newValue, let previousValue = oldValue {
                    //this value here has to be selectable from the settings Menu, also for other values
                    if value > previousValue {
                        goodResult = true
                    } else {
                        goodResult = false
                    }
                }
            }
        }
        .background(goodResult ? tooGoodColor  : tooBadColor)
        .aspectRatio(1, contentMode: .fit)
        .foregroundStyle(Color("display_font"))
    }
}

#Preview {
    VMGtoWaypointView(cell: displayCell[13], valueID: 13)
        .environment(NMEAReader())
}
