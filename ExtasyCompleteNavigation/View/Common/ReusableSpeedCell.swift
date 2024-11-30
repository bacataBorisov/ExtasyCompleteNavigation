//
//  ReusableSpeedCell.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 27.11.24.
//


import SwiftUI

struct ReusableSpeedCell: View {
    let name: String
    let value: Double?
    let unit: String
    let width: CGFloat

    var formattedValue: String {
        guard let value = value else { return "N/A" }
        return String(format: "%.2f", value) // Adjust the format as needed
    }

    var body: some View {
        ZStack {
            Group {
                Text(name)
                    .frame(width: width, height: width, alignment: .topLeading)
                    .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
                
                Text(unit)
                    .frame(width: width, height: width, alignment: .topTrailing)
                    .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
            }
            .padding(.all, 5)
            
            Text(formattedValue)
                .frame(width: width, height: width, alignment: .center)
                .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.4))
        }
        .minimumScaleFactor(0.2)
        .padding(.top, 5)
        .foregroundStyle(Color("display_font"))
    }
}

#Preview {
    GeometryProvider { width, _ in
        VStack(spacing: 10) {
            ReusableSpeedCell(
                name: "Polar Speed",
                value: 8.25, // Mock data
                unit: "kn",
                width: width / 3
            )
            
            ReusableSpeedCell(
                name: "Polar VMG",
                value: 12.34, // Mock data
                unit: "kn",
                width: width / 3
            )
            
            ReusableSpeedCell(
                name: "Waypoint VMC",
                value: 6.78, // Mock data
                unit: "kn",
                width: width / 3
            )
        }
        .aspectRatio(contentMode: .fit)
    }
}
