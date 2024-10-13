//
//  UltimateView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 2.10.23.
//

import SwiftUI
import SwiftData

struct UltimateView: View {
    
    @Environment(NMEAReader.self) private var navigationReadings
    
    @State private var speedCorners: [Int] = [3, 11]
    @State private var angleCorners: [Int] = [4, 7]
    
    @Query var data: [UltimateMatrix]
    @Environment(\.modelContext) var context
    
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20){
                    NavigationLink(destination: SettingsMenu())
                    {
                        //I want to place Extasy Logo here
                        
                        Image(systemName: "gear")
                            .dynamicTypeSize(.xxxLarge)
                            .foregroundStyle(Color(UIColor.systemGray))
                    }
                    
                    
                    NavigationLink(destination: MapView()) {
                        //I want to place Extasy Logo here
                        Image(systemName: "map")
                            .dynamicTypeSize(.xxxLarge)
                            .foregroundStyle(Color(UIColor.systemGray))
                    }
                    
                    NavigationLink(destination: {
                        WaypointListView()
                    }, label: {
                        //I want to place Extasy Logo here
                        Image(systemName: "scope")
                            .dynamicTypeSize(.xxxLarge)
                            .foregroundStyle(Color(UIColor.systemGray))
                    })
                    
                }
                GeometryReader{ geometry in
                    
                    let width: CGFloat = min(geometry.size.width, geometry.size.height)
                    let fontSizeWind = width/13
                    let fontSizeCompass = width/8
                    
                    
                    
                    //MARK: - Corners Display
                    
                    HStack(){
                        Menu {
                            ForEach(displayCell){ cell in
                                if cell.tag == "speed" {
                                    Button(action: {
                                        speedCorners[0] = checkSlotMenu(a: cell.id, oldValue: speedCorners[0], forType: "speed")
                                    }, label: {
                                        Text(cell.name)
                                    })
                                }
                            }
                        } label: {
                            //MARK: - The Whole Cell is a Big Button
                            //Top Left Corner - speed value
                            SmallCornerView(cell: displayCell[speedCorners[0]],
                                            valueID: speedCorners[0],
                                            nameAlignment: .bottomLeading,
                                            valueAlignment: .topTrailing,
                                            stringSpecifier: "%.1f")
                        }
                        Spacer(minLength: width/1.45)
                        Menu {
                            ForEach(displayCell){ cell in
                                if cell.tag == "wind" {
                                    Button(action: {
                                        angleCorners[0] = checkSlotMenu(a: cell.id, oldValue: angleCorners[0], forType: "wind")
                                        
                                    }, label: {
                                        Text(cell.name)
                                    })
                                }
                            }
                        } label: {
                            //Top Right Corner - angle values
                            SmallCornerView(cell: displayCell[angleCorners[0]],
                                            valueID: angleCorners[0],
                                            nameAlignment: .bottomTrailing,
                                            valueAlignment: .topLeading,
                                            stringSpecifier: "%.f")
                            
                        }
                    }
                    .frame(width: width, height: width, alignment: .top)
                    
                    HStack{
                        Menu(){
                            ForEach(displayCell){ cell in
                                if cell.tag == "wind" {
                                    Button(action: {
                                        angleCorners[1] = checkSlotMenu(a: cell.id, oldValue: angleCorners[1], forType: "wind")
                                        
                                    }, label: {
                                        Text(cell.name)
                                    })
                                }
                            }
                        } label: {
                            //Bottom Left Corner - angles
                            SmallCornerView(cell: displayCell[angleCorners[1]],
                                            valueID: angleCorners[1],
                                            nameAlignment: .topLeading,
                                            valueAlignment: .bottomTrailing,
                                            stringSpecifier: "%.f")
                            
                        }
                        Spacer(minLength: width/1.45)
                        Menu {
                            ForEach(displayCell){ cell in
                                if cell.tag == "speed" {
                                    Button(action: {
                                        speedCorners[1] = checkSlotMenu(a: cell.id, oldValue: speedCorners[1], forType: "speed")
                                    }, label: {
                                        Text(cell.name)
                                    })
                                }
                            }
                        } label: {
                            //Bottom Right Corner - speed
                            SmallCornerView(cell: displayCell[speedCorners[1]],
                                            valueID: speedCorners[1],
                                            nameAlignment: .topTrailing,
                                            valueAlignment: .bottomLeading,
                                            stringSpecifier: "%.1f")
                        }
                    }
                    .frame(width: width, height: width, alignment: .bottom)
                    
                    
                    
                    //MARK: - Anemometer Section
                    //gauge dial base
                    Circle()
                        .stroke(LinearGradient(gradient: Gradient(colors: [Color("dial_gauge_start"), Color("dial_gauge_end")]), startPoint: .top, endPoint: .bottom), lineWidth: width/14)
                        .padding((width/20)/2)
                    //STBD color
                    Circle()
                        .trim(from: 0, to: 0.167)
                    //make a gradient color here
                        .stroke(LinearGradient(gradient: Gradient(colors: [Color("stbd_color_start"), Color("stbd_color_end")]), startPoint: .topTrailing, endPoint: .bottom), lineWidth: width/14)
                        .padding((width/20)/2) //it gives half of the stroke width, so it is like a strokeBorder
                        .rotationEffect(.init(degrees: 270))
                    
                    //PORT color
                    Circle()
                        .trim(from: 0, to: 0.167)
                    //gradient is inverted because the view is rotated 210 degrees
                        .stroke(LinearGradient(gradient: Gradient(colors: [Color("port_color_start"), Color("port_color_end")]), startPoint: .bottom, endPoint: .center), lineWidth: width/14)
                        .padding((width/20)/2)
                        .rotationEffect(.init(degrees: 210))
                    
                    
                    //dial gauge indicators
                    //long indicators
                    MyShape(sections: 12, lineLengthPercentage: 0.1)
                        .stroke(Color(UIColor.systemBackground), style: StrokeStyle(lineWidth: width/90))
                    
                    //short indicators
                    MyShape(sections: 36, lineLengthPercentage: 0.03)
                        .stroke(Color(UIColor.systemBackground), style: StrokeStyle(lineWidth: width/90))
                        .padding(.all, width/60)
                    
                    //True wind indicator arrow
                    ZStack{
                        Triangle()
                        
                            .rotation(.degrees(180))
                            .scaleEffect(x: 0.12, y:0.12)
                            .offset(y: -width/2.15)
                            .foregroundStyle(Color(UIColor.systemBlue))
                        
                        Text("T")
                        //.scaleEffect(x: 0.12, y:0.12)
                            .font(Font.custom("AppleSDGothicNeo-Bold", size: fontSizeWind))
                            .offset(y: -width/2.1)
                            .foregroundStyle(Color(UIColor.white))
                    }
                    
                    //In case there is no data for the wind, the arrow just stays at 0 degrees and doesn't move
                    .rotationEffect(.degrees(self.navigationReadings.trueWindAngle ?? 0))
                    .animation(.easeInOut(duration: 1), value: self.navigationReadings.trueWindAngle)
                    //Apparent wind indicator arrow
                    ZStack{
                        Triangle()
                            .rotation(.degrees(180))
                            .scaleEffect(x: 0.12, y:0.12)
                            .offset(y: -width/2.15)
                            .foregroundStyle(Color(UIColor.systemPink))
                        Text("A")
                        //.scaleEffect(x: 0.12, y:0.12)
                            .font(Font.custom("AppleSDGothicNeo-Bold", size: fontSizeWind))
                            .offset(y: -width/2.1)
                            .foregroundStyle(Color(UIColor.white))
                    }
                    
                    //In case there is no data for the wind, the arrow just stays at 0 degrees and doesn't move
                    .rotationEffect(.degrees(navigationReadings.appWindAngle ?? 0))
                    .animation(.easeInOut(duration: 1), value: navigationReadings.appWindAngle)
                    
                    
                    
                    //MARK: - Compass Section
                        ZStack(){
                            
                            Circle()
                                .stroke(LinearGradient(gradient: Gradient(colors: [Color("dial_gauge_start"), Color("dial_gauge_end")]), startPoint: .top, endPoint: .bottom), lineWidth: width/12)
                                .padding((width/20))
                                .scaleEffect(x: 0.82, y:0.82)
                                
                            //heading values
                            ForEach(GaugeMarkerCompass.labelSet()) { marker in
                                CompassLabelView(marker: marker,  geometry: geometry)
                                    .position(CGPoint(x: width / 2, y: width / 2))
                            }
                            .transition(.identity) //prevent labels from fading
                        }
                        .rotationEffect(Angle(degrees: -(navigationReadings.magneticHeading ?? 0)))
                        .animation(.smooth, value: navigationReadings.hdgForDisplayAndCalculation)
                        

                    
                    Text("▼")
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: fontSizeCompass))
                        .position(x:width/2, y: width/2 )
                        .offset(y: -width/2)
                        .foregroundColor(Color(UIColor.systemYellow))
                        .scaleEffect(x: 0.82, y:0.82)
                    
                    //MARK: - Bearing to Mark Marker
                    ZStack{
                        Triangle()
                            .rotation(.degrees(180))
                            .scaleEffect(x: 0.07, y:0.07)
                            .offset(y: -width/2.39)
                            .foregroundStyle(Color(UIColor.systemGreen))
                        Image(systemName: "scope")
                        //.scaleEffect(x: 0.12, y:0.12)
                            .font(Font.custom("AppleSDGothicNeo-Bold", size: width/30))
                            .offset(y: -width/2.34)
                            .foregroundStyle(Color(UIColor.black))
                    }
                    .opacity(navigationReadings.isVMGSelected ? 1 : 0) //show it when VMG is active
                    
                    //function here to fix the rotation - it takes a Double() and returns Double()
                    .rotationEffect(.degrees((navigationReadings.relativeMarkBearing)))
                    .animation(.easeInOut(duration: 1), value: navigationReadings.relativeMarkBearing)
                    
                    PseudoBoat()
                        .stroke(lineWidth: 4)
                        .foregroundColor(Color(UIColor.systemGray))
                        .scaleEffect(x: 0.25, y: 0.55, anchor: .center)
                    
                }
                .ignoresSafeArea()
                //that centers the shape
                .aspectRatio(1, contentMode: .fit)
                .scaleEffect(x: 0.98, y: 0.98)
            }//END OF ZSTACK
        }
        
        //MARK: - Save / Load Data Config in the Display
        .onAppear(){
            if data.isEmpty {
                let model = UltimateMatrix(ultimateSpeed: [3, 11], ultimateAngle: [4, 7])
                context.insert(model)
            } else {
                speedCorners = data.last!.ultimateSpeed
                print(speedCorners)
                angleCorners = data.last!.ultimateAngle
                print(angleCorners)
            }
        }
        .onChange(of: speedCorners) { oldValue, newValue in
            print(newValue)
            let model = UltimateMatrix(ultimateSpeed: newValue, ultimateAngle: angleCorners)
            context.insert(model)
            print(data.count)
        }
        .onChange(of: angleCorners) { oldValue, newValue in
            let model = UltimateMatrix(ultimateSpeed: speedCorners, ultimateAngle: newValue)
            context.insert(model)
            print(data.count)
        }
    }//END OF BODY
    
    //MARK: - Check for Duplicate Values in the Other Cells
    func checkSlotMenu(a: Int, oldValue: Int, forType: String) -> Int {
        
        switch forType {
        case "speed":
            //check if the slot is already taken
            let check = speedCorners.contains(a)
            //print(check)
            //check which one is the correct position
            if check == true {
                for index in 0..<speedCorners.count {
                    //once found exchange the displays
                    if a == speedCorners[index] {
                        speedCorners[index] = oldValue
                        return a
                    }
                }
                //if the slot is not taken, just return the value
            } else {
                return a
            }
        default:
            //check if the slot is already taken
            let check = angleCorners.contains(a)
            //print(check)
            //check which one is the correct position
            if check == true {
                for index in 0..<angleCorners.count {
                    //once found exchange the displays
                    if a == angleCorners[index] {
                        angleCorners[index] = oldValue
                        return a
                    }
                }
                //if the slot is not taken, just return the value
            } else {
                return a
            }
        }
        return -1
    }
    
}
#Preview {
    UltimateView()
        .environment(NMEAReader())
        .modelContainer(for: [
            UltimateMatrix.self,
            UserSettingsMenu.self,
            Waypoints.self])
}
