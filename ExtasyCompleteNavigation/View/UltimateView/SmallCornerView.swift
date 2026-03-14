//
//  SmallCornerView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 28.01.24.
//
// TODO: - Refactor SmallCornerView Logic
// Currently, the view uses a GeometryReader internally to dynamically adapt its size.
// In the future, consider separating the logic to allow passing the `width` explicitly from the parent view.
// This will standardize the geometry management across the app and align with a more modular design.
// Ensure to handle cases where the `width` might be invalid or not provided by including a fallback mechanism.
import SwiftUI

struct SmallCornerView: View {
    
    @Environment(NMEAParser.self) private var navigationReadings
    var cell: MultiDisplayCells
    var valueID: Int
    
    let nameAlignment, valueAlignment: Alignment
    let stringSpecifier: String
    
    private var isStale: Bool {
        navigationReadings.dataStatus.sensorStatus(forValueID: valueID) == .stale
    }
    
    var body: some View {
        GeometryReader{ geometry in
            
            let width = geometry.size.width
            
            ZStack{
                Text(cell.name)
                    .frame(width: width, height: width, alignment: nameAlignment)
                    .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.35))
                
                let valueText: String = {
                    if isStale { return "--" }
                    if let value = navigationReadings.displayValue(a: valueID) {
                        return String(format: stringSpecifier, value)
                    }
                    return "--"
                }()
                
                Text(valueText)
                    .frame(width: width, height: width, alignment: valueAlignment)
                    .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.45))
                    .opacity(isStale ? 0.35 : 1.0)
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
    .environment(NMEAParser())
}
