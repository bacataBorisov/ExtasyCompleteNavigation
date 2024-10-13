//
//  Depth.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 19.09.23.
//

import SwiftUI
import SwiftData

struct BigDisplayCell: View {
    

    let alarmGradient = EllipticalGradient(colors:[Color(UIColor.systemRed), Color(UIColor.systemPink), Color(UIColor.systemBackground)])
    let nonAlarmGradient = EllipticalGradient(colors:[Color(UIColor.systemBackground), Color(UIColor.systemBackground)])
    
    @State var triggerAlarm: Bool = false
    
    @Environment(NMEAReader.self) private var navigationReadings
    
    var cell: MultiDisplayCells
    var valueID: Int
    @Query var lastSettings: [UserSettingsMenu]
    
    var body: some View {
        GeometryReader{ geometry in
            
            let width = geometry.size.width

                //MARK: - The Whole Cell is a Big Button
                ZStack{
                    
                    Text(cell.name)
                        .frame(width: width, height: width, alignment: .topLeading)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.15))

                    //check if the last used settings are metric and the value has metric expression & decide what to display
                    if lastSettings.isEmpty  {
                        Text(cell.units)
                            .frame(width: width, height: width, alignment: .topTrailing)
                            .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.15))
                    } else {
                        Text((lastSettings.last!.metricToggle && cell.valueHasMetric) ? cell.metric : cell.units)
                            .frame(width: width, height: width, alignment: .topTrailing)
                            .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.15))
                    }



                    if let unwrappedID = navigationReadings.displayValue(a: valueID){
                        Text(String(format: cell.specifier, unwrappedID))
                            .padding(.bottom, width * 0.24)
                            .frame(width: width, height: width, alignment: .center)
                            .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.4))
                    }
                }//END OF ZSTACK
        }//END OF GEOMETRY READER
        
        //ALARM for Depth Warning - To Be Tested
        .onChange(of: navigationReadings.depth) { oldValue, newValue in
            if newValue != nil {
                if let value = newValue {
                    //this value here has to be selectable from the settings Menu, also for other values
                    if value < 3 {
                        triggerAlarm = true
                    }
                }
            } else {
                triggerAlarm = false
            }
        }
        .background((cell.id == 0 && triggerAlarm) ? alarmGradient.opacity(0.8)  : nonAlarmGradient.opacity(0.8))
        .foregroundStyle(Color("display_font"))
        .aspectRatio(3/2, contentMode: .fit)

        
    }//END OF BODY
}//END OF STRUCT

#Preview {
    BigDisplayCell(cell: displayCell[0], valueID: 0)
        .modelContainer(for: UserSettingsMenu.self)
        .environment(NMEAReader())
        
}

