//
//  UltimateView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 2.10.23.
//

import SwiftUI
import SwiftData

struct UltimateView: View {
    
    //the source for the data to be displayed
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(SettingsManager.self) private var settingsManager
    
    
    @State private var speedCorners: [Int] = [3, 11]
    @State private var angleCorners: [Int] = [4, 7]
    
    @Query var data: [UltimateMatrix]
    @Environment(\.modelContext) var context

    var body: some View {
        
        GeometryProvider{ width, geometry, height in
            
            ZStack {
                //MARK: - Section with Settings, Map, Waypoints
                UltimateNavigationView()
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
                AnemometerView(trueWindAngle: navigationReadings.windData?.trueWindAngle ?? 0, apparentWindAngle: navigationReadings.windData?.apparentWindAngle ?? 0, width: width)
                
                //MARK: - Compass Section
                //TODO: - Fix compass to show properly the wrapped angles
                CompassView(width: width, geometry: geometry)
                
                //                    //MARK: - Bearing to Mark Marker
                if navigationReadings.gpsData?.isTargetSelected == true {
                    BearingMarkerView(width: width)
                }
            }//END OF ZSTACK
        }//END OF GEOMETRY
        //.ignoresSafeArea()
        .aspectRatio(1, contentMode: .fit)
        //.scaleEffect(x: 0.95, y: 0.95)
        .padding()
        
        
        //MARK: - Save / Load Data Config in the Display
        
        .onAppear {
            if let lastModel = data.last {
                speedCorners = lastModel.ultimateSpeed
                angleCorners = lastModel.ultimateAngle
            } else {
                let initialModel = UltimateMatrix(ultimateSpeed: [3, 11], ultimateAngle: [4, 7])
                context.insert(initialModel)
            }
            
        }
        .onChange(of: speedCorners) { _, _ in
            updateUltimateMatrix()
        }
        .onChange(of: angleCorners) { _, _ in
            updateUltimateMatrix()
        }
        
    }//END OF BODY
    
    //MARK: - Helper function for updating UltimateMatrix .onAppear & .onChange
    private func updateUltimateMatrix() {
        let model = UltimateMatrix(ultimateSpeed: speedCorners, ultimateAngle: angleCorners)
        context.insert(model)
    }
    //MARK: - Check for Duplicate Values in the Other Cells
    //optimized version
    func checkSlotMenu(a: Int, oldValue: Int, forType: String) -> Int {
        // Determine which array to check based on the type
        var corners = forType == "speed" ? speedCorners : angleCorners
        
        // Check if the value already exists in the array
        if let index = corners.firstIndex(of: a) {
            // Swap the values
            corners[index] = oldValue
        } else {
            // Add the new value if it doesn't exist
            return a
        }
        
        // Update the corresponding array
        if forType == "speed" {
            speedCorners = corners
        } else {
            angleCorners = corners
        }
        
        return a
    }
    
    //old working version
    //    func checkSlotMenu(a: Int, oldValue: Int, forType: String) -> Int {
    //
    //        switch forType {
    //        case "speed":
    //            //check if the slot is already taken
    //            let check = speedCorners.contains(a)
    //            //print(check)
    //            //check which one is the correct position
    //            if check == true {
    //                for index in 0..<speedCorners.count {
    //                    //once found exchange the displays
    //                    if a == speedCorners[index] {
    //                        speedCorners[index] = oldValue
    //                        return a
    //                    }
    //                }
    //                //if the slot is not taken, just return the value
    //            } else {
    //                return a
    //            }
    //        default:
    //            //check if the slot is already taken
    //            let check = angleCorners.contains(a)
    //            //print(check)
    //            //check which one is the correct position
    //            if check == true {
    //                for index in 0..<angleCorners.count {
    //                    //once found exchange the displays
    //                    if a == angleCorners[index] {
    //                        angleCorners[index] = oldValue
    //                        return a
    //                    }
    //                }
    //                //if the slot is not taken, just return the value
    //            } else {
    //                return a
    //            }
    //        }
    //        return -1
    //    }
    
}
#Preview {
    UltimateView()
        .environment(NMEAParser())
        .environment(SettingsManager())
        .modelContainer(for: [
            UltimateMatrix.self,
            Waypoints.self])
}
