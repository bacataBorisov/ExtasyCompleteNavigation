//
//  EstimatedTimeArrivalView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 3.02.24.
//

import SwiftUI
import SwiftData

struct EstimatedTimeArrivalView: View {

    @Environment(NMEAReader.self) private var navigationReadings
    var cell: MultiDisplayCells
    var valueID: Int
    
    var body: some View {
        
        GeometryReader{ geometry in
            
            let width = geometry.size.width
            
            ZStack{
                Group{
                    Text("\(cell.name)")
                        .frame(width: width, height: width, alignment: .topLeading)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
                   
                    if let unwrappedValue = navigationReadings.displayValue(a: valueID){
                        
                        let formatter: DateComponentsFormatter = {
                            let formatter = DateComponentsFormatter()
                            formatter.unitsStyle = .positional
                            formatter.zeroFormattingBehavior = .pad
                            formatter.allowedUnits = [.hour, .minute, .second]
                            return formatter
                        }()
                        
                        //TODO: - Need to play a little bit with the font size - it has to be dynamic
                        if let result = formatter.string(from: unwrappedValue) {
                            Text(result)
                                .frame(width: width, height: width, alignment: .center)
                                .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.2))
                                
                        }
                        
                        

                    }
                }
                .padding(.top, 5)
                .minimumScaleFactor(0.15)
            }//END OF ZSTACK
        }//END OF GEOMETRY READER
        
        .aspectRatio(1, contentMode: .fit)
        .foregroundStyle(Color("display_font"))
        
    }//END OF BODY
}

#Preview {
    EstimatedTimeArrivalView(cell: displayCell[17], valueID: 17)
        .environment(NMEAReader())
}
