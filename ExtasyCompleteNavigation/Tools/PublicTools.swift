//
//  ViewShapesTool.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 3.10.23.
//

import Foundation
import SwiftUI


//MARK: - Shape Structures for the Different Views
//MARK: - Constants
//coeff. for converting to nautical miles
public let toNauticalMiles = 0.000539956803
public let toNauticalCables = 0.0053961007775
public let toBoatLengths = 0.083333333333
public let toMetersPerSecond = 0.514444444

public var rawString = String()
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

//MARK: - Specially for the Compass Needs

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

struct GaugeMarkerCompass: Identifiable, Hashable {
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
            GaugeMarker(degrees: 0, label: "N"),
            GaugeMarker(degrees: 30, label: "30"),
            GaugeMarker(degrees: 60, label: "60"),
            GaugeMarker(degrees: 90, label: "E"),
            GaugeMarker(degrees: 120, label: "120"),
            GaugeMarker(degrees: 150, label: "150"),
            GaugeMarker(degrees: 180, label: "S"),
            GaugeMarker(degrees: 210, label: "210"),
            GaugeMarker(degrees: 240, label: "240"),
            GaugeMarker(degrees: 270, label: "W"),
            GaugeMarker(degrees: 300, label: "300"),
            GaugeMarker(degrees: 330, label: "330")
            
        ]
    }
}

//MARK: - Pseudo Boat Shape

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

//Convert the value to be displayed properly - without the negative sign and
//divided by modulus if it is higher than 360
public func convertForDisplay(_ value: Double?) -> Double? {
    
    if var displayedValue = value {
        if displayedValue < 0 {
            displayedValue += 360
            return displayedValue
        //when higher than 360 and any other case
        } else {
            return displayedValue.truncatingRemainder(dividingBy: 360)
        }
    } else {
        return nil
    }
    
}

//MARK: Block for Precise Rounding of a Value
// Specify the decimal place to round to using an enum
public enum RoundingPrecision {
    
    case ones
    case tenths
    case hundredths
}

// Round to the specific decimal place
public func preciseRound(
    _ value: Double,
    precision: RoundingPrecision = .ones) -> Double
{
    switch precision {
    case .ones:
        return round(value)
    case .tenths:
        return round(value * 10) / 10.0
    case .hundredths:
        return round(value * 100) / 100.0
    }
}


public func toRadians(_ degrees: Double) -> Double {
    return degrees * (Double.pi / 180.0)
}
public func toDegrees(_ radians: Double) -> Double {
    return radians * (180.0 / Double.pi)
}

//VMG to a waypoint formula - VMG=speed x COSINE(course-bearing to mark), SOG, COG to be used
public func vmg(speed: Double, target_angle: Double, boat_angle: Double) -> Double {
    
    print("PRINTING FROM VMG")

    print("COG: [\(boat_angle)], SOG: [\(speed)], BTW: [\(target_angle)]")
    
    //check what is higher so we can always get positive valu
    var courseOffset = target_angle - boat_angle
    
    if courseOffset < 0 {
        courseOffset = courseOffset * (-1)
        
        if courseOffset >= 180 {
            courseOffset = 360 - courseOffset
        }
    }
    
    
    let courseOffsetInRadians = toRadians(courseOffset)
    print("Course Offset: [\(courseOffset)]")
    let rt = speed * cos(courseOffsetInRadians)
    print("VMG: [\(rt)]")
    return rt
}

//MARK: - Awesome Function for Resizing by Passing a View

public struct VHStack<Content: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?

    let content: Content

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        //LandscapeView
        if verticalSizeClass == .compact {
            HStack() {
                content
            }
            .safeAreaPadding(.top)
        //PortraitView
        } else {
            VStack {
                content
            }
            .safeAreaPadding(.all)
        }
    }
}

//USed for ScrollView Purposes
public struct HVStack<Content: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?

    let content: Content

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        //LandscapeView
        if verticalSizeClass == .compact {
            VStack() {
                content
            }
            //.safeAreaPadding(.all)
        //PortraitView
        } else {
            HStack {
                content
            }
            //.safeAreaPadding(.top)
        }
    }
}

//this must be public
