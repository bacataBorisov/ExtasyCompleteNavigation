//
//  CompassView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 20.11.24.
//

import SwiftUI

struct CompassView: View {
    
    let heading: Double
    let width: CGFloat
    let markers = GaugeMarkerCompass.labelSet()
    let geometry: GeometryProxy
    
    var body: some View {
        
        ZStack(){
            Circle()
                .stroke(LinearGradient(gradient: Gradient(colors: [Color("dial_gauge_start"), Color("dial_gauge_end")]), startPoint: .top, endPoint: .bottom), lineWidth: width/12)
                .padding((width/20))
                .scaleEffect(x: 0.82, y:0.82)
            
            ForEach(markers) { marker in
                CompassLabelView(marker: marker, geometry: geometry)
                    .position(CGPoint(x: width / 2, y: width / 2))
            }
        }//END OF ZSTACK
        .transition(.identity) //prevent labels from fading
        .rotationEffect(.degrees(-(heading)))
        .animation(.easeInOut(duration: 1), value: heading)
        
        //Yellow Indicator
        Text("▼")
            .font(Font.custom("AppleSDGothicNeo-Bold", size: width/8))
            .position(x:width/2, y: width/2 )
            .offset(y: -width/2)
            .foregroundColor(Color(UIColor.systemYellow))
            .scaleEffect(x: 0.82, y:0.82)
    }
}

#Preview {
    GeometryProvider { width, geometry in
        
        CompassView(heading: 45, width: width, geometry: geometry)
            .environment(NMEAParser())
    }
    .aspectRatio(contentMode: .fit)
    
    
}
