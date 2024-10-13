//
//  SpeedAndDepth.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 26.08.23.
//

import SwiftUI
import SwiftData

struct SmallDisplayCell: View {
    
    //MARK: - View Section Variables
    let alarmGradient = EllipticalGradient(colors:[Color(UIColor.systemRed), Color(UIColor.systemPink), Color(UIColor.systemBackground)])
    let nonAlarmGradient = EllipticalGradient(colors:[Color(UIColor.systemBackground), Color(UIColor.systemBackground)])
    
    @State var triggerAlarm: Bool = false
    
    @Environment(NMEAReader.self) private var navigationReadings
    var cell: MultiDisplayCells
    var valueID: Int
    //Indicates that VMG has to be green
    @State var goodResult = false
    
    @Query var lastSettings: [UserSettingsMenu]
    
    var body: some View {
        
        GeometryReader{ geometry in
            
            let width = geometry.size.width
            
            ZStack{
                Group{
                    Text(cell.name)
                        .frame(width: width, height: width, alignment: .topLeading)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
                    if lastSettings.isEmpty  {
                        Text(cell.units)
                            .frame(width: width, height: width, alignment: .topTrailing)
                            .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
                    } else {
                        Text((lastSettings.last!.metricToggle && cell.valueHasMetric) ? cell.metric : cell.units)
                            .frame(width: width, height: width, alignment: .topTrailing)
                            .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.18))
                    }

                    if let unwrappedValue = navigationReadings.displayValue(a: valueID){
                        Text(String(format: cell.specifier, unwrappedValue))
                            .frame(width: width, height: width, alignment: .center)
                            .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.4))
                    }
                }
                .padding(.top, 5)
            }//END OF ZSTACK
        }//END OF GEOMETRY READER
        //MARK: - Trigger Depth Alarm
        .onChange(of: navigationReadings.depth) { _ , newValue in
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
        .background((cell.id == 0 && triggerAlarm) ? alarmGradient  : nonAlarmGradient)
        .aspectRatio(1, contentMode: .fit)
        .foregroundStyle(Color("display_font"))
        
    }//END OF BODY
}//END OF STRUCTURE

#Preview {
    SmallDisplayCell(cell: displayCell[1], valueID: 1)
        .environment(NMEAReader())
        .modelContainer(for: [Matrix.self, UserSettingsMenu.self])
}


