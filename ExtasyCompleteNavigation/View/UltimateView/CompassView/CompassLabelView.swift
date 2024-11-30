//
//  CompassLabelView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 25.11.24.
//

import SwiftUI
//MARK: - Compass Geometry & View

public struct CompassLabelView: View {
    let marker: GaugeMarker
    let geometry: GeometryProxy
    
    @State var fontSize: CGFloat = 12
    @State var paddingValue: CGFloat = 100
    
    public var body: some View {
        VStack {
            Text(marker.label)
                .foregroundColor(Color(UIColor.systemBackground))
                .font(Font.custom("AppleSDGothicNeo-Bold", size: geometry.size.width * 0.05))
                .rotationEffect(Angle(degrees: 0))
                .padding(.bottom, geometry.size.width * 0.73)
        }.rotationEffect(Angle(degrees: marker.degrees))
            .onAppear {
                paddingValue = geometry.size.width * 0.9
                fontSize = geometry.size.width * 0.07
            }
    }
}
