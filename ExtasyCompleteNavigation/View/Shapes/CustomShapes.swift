//
//  Untitled.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 25.11.24.
//

import SwiftUI

//MARK: - Pseudo Boat Shape
/*
 Draws the shape of the pseudo-boat used in UltimateDisplay
 */

public struct PseudoBoat: Shape {
   public func path(in rect: CGRect) -> Path {
        var path = Path()
        let height = rect.minY + rect.maxY

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: (rect.minX), y: rect.maxY),
            control1: CGPoint(x: (rect.midX-rect.midX), y:rect.maxY/3),
            control2: CGPoint(x: (rect.midX-rect.midX), y: rect.maxY/2)
        )
        path.addLine(to: CGPoint(x: (rect.minX), y: rect.maxY))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: (rect.maxX), y: rect.maxY),
            control1: CGPoint(x: (rect.midX+rect.midX), y:rect.maxY/3),
            control2: CGPoint(x: (rect.midX+rect.midX), y:rect.maxY/2)
        )
        //inside path
        path.move(to: CGPoint(x: rect.midX, y: rect.minY+height/20))
        path.addCurve(
            to: CGPoint(x: (rect.minX), y: rect.maxY),
            control1: CGPoint(x: (rect.midX-rect.midX/1.1), y:rect.maxY/3),
            control2: CGPoint(x: (rect.midX-rect.midX), y: rect.maxY/2)
        )
        path.addLine(to: CGPoint(x: (rect.minX), y: rect.maxY))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY+height/20))
        path.addCurve(
            to: CGPoint(x: (rect.maxX), y: rect.maxY),
            control1: CGPoint(x: (rect.midX+rect.midX/1.1), y:rect.maxY/3),
            control2: CGPoint(x: (rect.midX+rect.midX), y: rect.maxY/2)
        )
        return path
    }
}

//shape for multidisplay lines
public struct HorizontalLine: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: 2*rect.maxY/3))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: 2*rect.maxY/3),
            control1: CGPoint(x: rect.maxX/3, y:rect.maxY/1.52),
            control2: CGPoint(x: 2*rect.maxX/3, y: rect.maxY/1.52)
        )
        path.move(to: CGPoint(x: rect.minX, y: 2*rect.maxY/3))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: 2*rect.maxY/3),
            control1: CGPoint(x: rect.maxX/3, y:rect.maxY/1.49),
            control2: CGPoint(x: 2*rect.maxX/3, y: rect.maxY/1.49)
        )
        
        return path
    }
}

public struct HorizontalMiddleLine: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.maxX/3, y:rect.maxY/1.52),
            control2: CGPoint(x: 2*rect.maxX/3, y: rect.maxY/1.52)
        )
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.maxX/3, y:rect.maxY/1.49),
            control2: CGPoint(x: 2*rect.maxX/3, y: rect.maxY/1.49)
        )
        
        return path
    }
}

public struct VerticalLine: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        
        path.move(to: CGPoint(x: rect.maxX/3, y: 2*rect.maxY/3))
        path.addCurve(
            to: CGPoint(x: rect.maxX/3, y: rect.maxY),
            control1: CGPoint(x: rect.maxX/3.05, y: 7*rect.maxY/9),
            control2: CGPoint(x: rect.maxX/3.05, y: 8*rect.maxY/9)
        )
        path.move(to: CGPoint(x: rect.maxX/3, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.maxX/3, y: 2*rect.maxY/3),
            control1: CGPoint(x: rect.maxX/2.92, y: 8*rect.maxY/9),
            control2: CGPoint(x: rect.maxX/2.92, y: 7*rect.maxY/9)
        )
        
        path.move(to: CGPoint(x: 2*rect.maxX/3, y: 2*rect.maxY/3))
        path.addCurve(
            to: CGPoint(x: 2*rect.maxX/3, y: rect.maxY),
            control1: CGPoint(x: 2*rect.maxX/3.02, y: 7*rect.maxY/9),
            control2: CGPoint(x: 2*rect.maxX/3.03, y: 8*rect.maxY/9)
        )
        path.move(to: CGPoint(x: 2*rect.maxX/3, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: 2*rect.maxX/3, y: 2*rect.maxY/3),
            control1: CGPoint(x: 2*rect.maxX/2.96, y: 8*rect.maxY/9),
            control2: CGPoint(x: 2*rect.maxX/2.96, y: 7*rect.maxY/9)
        )
        return path
    }
}


//shape for the indicator arrow
public struct Triangle: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        
        return path
    }
}

//shape for creating the white dashes for the indicators. Besically it is a circle that you
//can divide to as many parts as you need. It can be re-used probably for the compass too.
//could be transferred to a different file at a later stage - CustomShapes???
public struct MyShape : Shape {
    var sections : Int
    var lineLengthPercentage: CGFloat
    
    public func path(in rect: CGRect) -> Path {
        let radius = rect.width / 2
        let degreeSeparation : Double = 360.0 / Double(sections)
        var path = Path()
        for index in 0..<Int(360.0/degreeSeparation) {
            let degrees = Double(index) * degreeSeparation
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let innerX = center.x + (radius - rect.size.width * lineLengthPercentage / 2) * CGFloat(cos(degrees / 360 * Double.pi * 2))
            let innerY = center.y + (radius - rect.size.width * lineLengthPercentage / 2) * CGFloat(sin(degrees / 360 * Double.pi * 2))
            let outerX = center.x + radius * CGFloat(cos(degrees / 360 * Double.pi * 2))
            let outerY = center.y + radius * CGFloat(sin(degrees / 360 * Double.pi * 2))
            path.move(to: CGPoint(x: innerX, y: innerY))
            path.addLine(to: CGPoint(x: outerX, y: outerY))
        }
        return path
    }
}

// labels and the numbers for the gauge - answer from stackOverflow
public struct LabelView: View {
    let marker: GaugeMarker
    let geometry: GeometryProxy
    
    @State var fontSize: CGFloat = 12
    @State var paddingValue: CGFloat = 100
    
    public var body: some View {
        
        VStack {
            Text(marker.label)
                .foregroundColor(Color(UIColor.systemBackground))
                .font(Font.custom("AppleSDGothicNeo-Bold", size: fontSize))
                .rotationEffect(Angle(degrees: -self.marker.degrees))
                .padding(.bottom, paddingValue)
        }.rotationEffect(Angle(degrees: marker.degrees))
            .onAppear {
                paddingValue = geometry.size.width * 0.72
                fontSize = geometry.size.width * 0.07
            }
    }
}

struct GaugeMarker: Identifiable, Hashable {
    let id = UUID()
    
    let degrees: Double
    let label: String
    
    init(degrees: Double, label: String) {
        self.degrees = degrees
        self.label = label
    }
    
    // adjust according to your needs
    static func labelSet() -> [GaugeMarker] {
        return [
            GaugeMarker(degrees: 0, label: "▼"),
            GaugeMarker(degrees: 30, label: "30"),
            GaugeMarker(degrees: 60, label: "60"),
            GaugeMarker(degrees: 90, label: "90"),
            GaugeMarker(degrees: 120, label: "120"),
            GaugeMarker(degrees: 240, label: "120"),
            GaugeMarker(degrees: 270, label: "90"),
            GaugeMarker(degrees: 300, label: "60"),
            GaugeMarker(degrees: 330, label: "30")
        ]
    }
}

public struct BoatShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Draw a triangular boat shape
        path.move(to: CGPoint(x: width / 2, y: 0)) // Top point
        path.addLine(to: CGPoint(x: 0, y: height)) // Bottom-left
        path.addLine(to: CGPoint(x: width, y: height)) // Bottom-right
        path.closeSubpath() // Close the triangle

        return path
    }
}
