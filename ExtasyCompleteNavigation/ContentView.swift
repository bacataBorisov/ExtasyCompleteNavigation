//
//  ContentView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 13.06.23.
//

import SwiftUI
import MapKit
import SwiftData

//MARK: - Main View
struct ContentView: View {
    
    //One instance - Single Source of Thruth
    @Environment(NMEAParser.self) private var navigationReadings
    
    //create one instance of the NMEAReader
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    @Query private var waypoints: [Waypoints]
    
    var body: some View {
        
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            IpadView()
                .onDisappear(perform: {
                    
                    for waypoint in waypoints {
                        waypoint.isTargetSelected = false
                    }                    
                })
        } else {
            IPhoneView()
                .onDisappear(perform: {
                    
                    //navigationReadings.stop()
                    for waypoint in waypoints {
                        waypoint.isTargetSelected = false
                    }
                    //                    navigationReadings.isVMGSelected = false
                })
                .onAppear {
                    //navigationReadings.start()
                }
        }
    }//END OF BODY
}//END OF CONTENT VIEW

//TODO: - WORK MORE ON THE IPAD VIEW
//MARK: - iPad View
struct IpadView: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    @Environment(NMEAParser.self) private var navigationReadings
    
    var body: some View {
        
        GeometryReader { ruler in
            if ruler.size.width < ruler.size.height || horizontalSizeClass == .compact {
                //MARK: - iPad Potrait View
                
                VStack(){
                    UltimateView()
                    Divider()
                        .frame(height: 1)
                    
                    HStack{
                        MultiDisplay()
                        if navigationReadings.isVMGSelected == true {
                            Divider()
                                .frame(height: 1)
                                .overlay(Color(UIColor.systemGray))
                            VMGView(viewModel: VMGViewModel(vmgProcessor: navigationReadings.vmgProcessor))
                        }
                    }
                }//END OF VSTACK
                
                
            } else {
                //MARK: - iPad LandscapeView
                
                HStack(){
                    UltimateView()
                    Divider()
                        .frame(width: 1)
                        .overlay(Color(UIColor.systemGray))
                    VStack(){
                        MultiDisplay()
                        Text("isVMGSelected: \(navigationReadings.isVMGSelected.description)")
                        // Ensure VMGView is displayed only if isVMGSelected is true
                        if navigationReadings.isVMGSelected == true {
                            Divider()
                                .frame(height: 1)
                                .overlay(Color(UIColor.systemGray))
                            withAnimation(.spring) {
                                VMGView(viewModel: VMGViewModel(vmgProcessor: navigationReadings.vmgProcessor))
                                
                            }
                        }
                    }
                }//END OF HSTACK
            }
        }
    }
}

//MARK: - iPhone Portrait View
struct IPhoneView: View {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(NMEAParser.self) private var navigationReadings
    
    var body: some View {
        VHStack{
            //The navigation stack is only for the upper part of the display - much more convenient and faster to work
            //MARK: - Upper Part of the Display
            UltimateView()
            
            //MARK: - Lower Part of the Display
            
            ScrollView(verticalSizeClass == .compact ? .vertical : .horizontal) {
                
                HStack{
                    MultiDisplay()
                    Divider()
                    
                    // Ensure VMGView is displayed only if isVMGSelected is true
                    if navigationReadings.isVMGSelected == true {
                        
                        withAnimation(.spring(response: 0.5, dampingFraction: 1)) {
                            VMGView(viewModel: VMGViewModel(vmgProcessor: navigationReadings.vmgProcessor))
                                .transition(.opacity)
                        }
                    }
                }
            }
            .defaultScrollAnchor(verticalSizeClass == .compact ? .top : .topLeading)
            .scrollClipDisabled()
            
        }
        
    }//END OF ZSTACK
}//END OF NAVIGATION STACK

#Preview {
    ContentView()
        .environment(NMEAParser())
        .modelContainer(for: [
            Matrix.self,
            UserSettingsMenu.self,
            UltimateMatrix.self,
            Waypoints.self,
            BearingToMarkUnitsMenu.self,
            NauticalDistance.self,
            NextTackNauticalDistance.self,
            SwitchCoordinatesView.self,
        ])
}
