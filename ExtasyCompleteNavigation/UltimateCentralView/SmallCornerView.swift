//
//  SmallCornerView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 28.01.24.
//

import SwiftUI

struct SmallCornerView: View {
    
    @Environment(NMEAReader.self) private var navigationReadings
    var cell: MultiDisplayCells
    var valueID: Int
    
    let nameAlignment, valueAlignment: Alignment
    let stringSpecifier: String
    
    
    var body: some View {
        GeometryReader{ geometry in
            
            let width = geometry.size.width
            
            //MARK: - The Whole Cell is a Big Button
            ZStack{
                Text(cell.name)
                    .frame(width: width, height: width, alignment: nameAlignment)
                    .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.35))
                if let unwrappedValue = navigationReadings.displayValue(a: valueID){
                    Text(String(format: stringSpecifier, unwrappedValue))
                        .frame(width: width, height: width, alignment: valueAlignment)
                        .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.45))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .foregroundStyle(Color("display_font"))
    }
}

#Preview {
    SmallCornerView(cell: displayCell[1],
                    valueID: 1,
                    nameAlignment: .topLeading,
                    valueAlignment: .bottomTrailing,
                    stringSpecifier: "%.1f")
    .environment(NMEAReader())
}
