import SwiftUI

import SwiftUI

struct AnemometerView: View {
    
    let trueWindAngle: Double
    let apparentWindAngle: Double
    let width: CGFloat
    
    var body: some View {
        
        ZStack {
            // Dial Gauge Base
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color("dial_gauge_start"), Color("dial_gauge_end")]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: width / 14
                )
                .padding(width / 20 / 2)
            
            // STBD Sector
            SectorView(
                gradientColors: [Color("stbd_color_start"), Color("stbd_color_end")],
                startAngle: 270,
                lineWidth: width / 14,
                padding: width / 20 / 2
            )
            
            // PORT Sector
            SectorView(
                gradientColors: [Color("port_color_end"), Color("port_color_start")],
                startAngle: 210,
                lineWidth: width / 14,
                padding: width / 20 / 2
            )
            
            // Dial Gauge Indicators
            DialGaugeIndicators(width: width)
            
            // True Wind Indicator
            WindArrow(
                label: "T",
                color: Color(UIColor.systemBlue),
                angle: trueWindAngle,
                fontSize: width/13,
                offset: width / 2.15
            )
            
            // Apparent Wind Indicator
            WindArrow(
                label: "A",
                color: Color(UIColor.systemPink),
                angle: apparentWindAngle,
                fontSize: width/13,
                offset: width / 2.15
            )
        }
    }
    
}

// MARK: - Subviews

struct SectorView: View {
    let gradientColors: [Color]
    let startAngle: Double
    let lineWidth: CGFloat
    let padding: CGFloat
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.167)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .topTrailing,
                    endPoint: .bottom
                ),
                lineWidth: lineWidth
            )
            .padding(padding)
            .rotationEffect(.degrees(startAngle))
    }
}

struct DialGaugeIndicators: View {
    let width: CGFloat
    
    var body: some View {
        ZStack {
            // Long Indicators
            MyShape(sections: 12, lineLengthPercentage: 0.1)
                .stroke(Color(UIColor.systemBackground), style: StrokeStyle(lineWidth: width / 90))
            
            // Short Indicators
            MyShape(sections: 36, lineLengthPercentage: 0.03)
                .stroke(Color(UIColor.systemBackground), style: StrokeStyle(lineWidth: width / 90))
                .padding(width / 60)
        }
    }
}

struct WindArrow: View {
    let label: String
    let color: Color
    let angle: Double
    let fontSize: CGFloat
    let offset: CGFloat
    
    var body: some View {
        ZStack {
            Triangle()
                .rotation(.degrees(180))
                .scaleEffect(x: 0.12, y: 0.12)
                .offset(y: -offset)
                .foregroundStyle(color)
            
            Text(label)
                .font(Font.custom("AppleSDGothicNeo-Bold", size: fontSize))
                .offset(y: -offset * 1.04)
                .foregroundStyle(Color(UIColor.white))
        }
        .rotationEffect(.degrees(angle))
        .animation(.easeInOut(duration: 1), value: angle)
    }
}

// MARK: - Preview
#Preview {
    GeometryProvider { width, _ in
        AnemometerView(
            trueWindAngle: 48,
            apparentWindAngle: 120, width: width
        )
    }
    .aspectRatio(contentMode: .fit)

}



////
////  AnemometerView.swift
////  ExtasyCompleteNavigation
////
////  Created by Vasil Borisov on 22.11.24.
////
//import SwiftUI
//
//struct AnemometerView: View {
//
//    let trueWindAngle: Double
//    let apparentWindAngle: Double
//
//    var body: some View {
//
//        GeometryReader{ geometry in
//
//            let width: CGFloat = min(geometry.size.width, geometry.size.height)
//            let fontSizeWind = width/13
//
//            ZStack{
//                //MARK: - Anemometer Section
//                //gauge dial base
//                Circle()
//                    .stroke(LinearGradient(gradient: Gradient(colors: [Color("dial_gauge_start"), Color("dial_gauge_end")]), startPoint: .top, endPoint: .bottom), lineWidth: width/14)
//                    .padding((width/20)/2)
//                //STBD color
//                Circle()
//                    .trim(from: 0, to: 0.167)
//                //make a gradient color here
//                    .stroke(LinearGradient(gradient: Gradient(colors: [Color("stbd_color_start"), Color("stbd_color_end")]), startPoint: .topTrailing, endPoint: .bottom), lineWidth: width/14)
//                    .padding((width/20)/2) //it gives half of the stroke width, so it is like a strokeBorder
//                    .rotationEffect(.init(degrees: 270))
//
//                //PORT color
//                Circle()
//                    .trim(from: 0, to: 0.167)
//                //gradient is inverted because the view is rotated 210 degrees
//                    .stroke(LinearGradient(gradient: Gradient(colors: [Color("port_color_start"), Color("port_color_end")]), startPoint: .bottom, endPoint: .center), lineWidth: width/14)
//                    .padding((width/20)/2)
//                    .rotationEffect(.init(degrees: 210))
//
//
//                //dial gauge indicators
//                //long indicators
//                MyShape(sections: 12, lineLengthPercentage: 0.1)
//                    .stroke(Color(UIColor.systemBackground), style: StrokeStyle(lineWidth: width/90))
//
//                //short indicators
//                MyShape(sections: 36, lineLengthPercentage: 0.03)
//                    .stroke(Color(UIColor.systemBackground), style: StrokeStyle(lineWidth: width/90))
//                    .padding(.all, width/60)
//
//                //True wind indicator arrow
//                ZStack{
//                    Triangle()
//
//                        .rotation(.degrees(180))
//                        .scaleEffect(x: 0.12, y:0.12)
//                        .offset(y: -width/2.15)
//                        .foregroundStyle(Color(UIColor.systemBlue))
//
//                    Text("T")
//                    //.scaleEffect(x: 0.12, y:0.12)
//                        .font(Font.custom("AppleSDGothicNeo-Bold", size: fontSizeWind))
//                        .offset(y: -width/2.1)
//                        .foregroundStyle(Color(UIColor.white))
//                }
//
////                In case there is no data for the wind, the arrow just stays at 0 degrees and doesn't move
//                .rotationEffect(.degrees(trueWindAngle))
//                .animation(.easeInOut(duration: 1), value: trueWindAngle)
//                //Apparent wind indicator arrow
//                ZStack{
//                    Triangle()
//                        .rotation(.degrees(180))
//                        .scaleEffect(x: 0.12, y:0.12)
//                        .offset(y: -width/2.15)
//                        .foregroundStyle(Color(UIColor.systemPink))
//                    Text("A")
//                    //.scaleEffect(x: 0.12, y:0.12)
//                        .font(Font.custom("AppleSDGothicNeo-Bold", size: fontSizeWind))
//                        .offset(y: -width/2.1)
//                        .foregroundStyle(Color(UIColor.white))
//                }
//
//                //In case there is no data for the wind, the arrow just stays at 0 degrees and doesn't move
//                .rotationEffect(.degrees(apparentWindAngle))
//                .animation(.easeInOut(duration: 1), value: apparentWindAngle)
//            }
//        }
//        .aspectRatio(contentMode: .fit)
//    }
//}
//
//#Preview {
//
//    return AnemometerView(
//        trueWindAngle: 45, // Example value for true wind angle
//        apparentWindAngle: 120 // Example value for apparent wind angle
//    )
//}
//
