//
//  ReusableDistanceCell.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 27.11.24.
//

import SwiftUI
import SwiftData

struct ReusableDistanceCell: View {
    let name: String
    let unitLabel: String
    let formattedValue: String
    let onTapCycleUnits: () -> Void
    let width: CGFloat

    var body: some View {
        ZStack {
            Text(name)
                .frame(width: width, height: width, alignment: .topLeading)
                .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))

            Text(unitLabel)
                .frame(width: width, height: width, alignment: .topTrailing)
                .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))

            Text(formattedValue)
                .frame(width: width, height: width, alignment: .center)
                .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.4))
        }
        .minimumScaleFactor(0.2)
        .padding(.top, 5)
        .onTapGesture {
            onTapCycleUnits()
        }
        .foregroundStyle(Color("display_font"))
    }
}
