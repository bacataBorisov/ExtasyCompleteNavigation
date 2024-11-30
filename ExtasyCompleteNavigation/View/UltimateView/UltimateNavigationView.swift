//
//  UltimateNavigationView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 22.11.24.
//
// NOTE:
// The current child views (e.g., SettingsView, MapView, WaypointListView)
// do not require explicit geometry management or width passing from the parent view.
// They adapt naturally to the screen size or navigation context provided by SwiftUI.
//
// However, if these views become more complex and require precise scaling, padding,
// or layout adjustments based on the parent dimensions, it is recommended to:
// 1. Use GeometryProvider in the parent (UltimateView).
// 2. Pass the `width` (or other geometry-related parameters) explicitly
//    from UltimateView to the child views.
//
// This approach ensures consistency across child views and flexibility for future enhancements.


import Foundation
import SwiftUI

struct UltimateNavigationView: View {
    
    //the source for the data to be displayed
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(\.modelContext) var context
    
    var body: some View {
        ZStack {
            PseudoBoat()
                .stroke(lineWidth: 4)
                .foregroundColor(Color(UIColor.systemGray))
                .scaleEffect(x: 0.25, y: 0.55, anchor: .center)
            
            VStack(spacing: 20) {
                NavigationLink(destination: SettingsMenuView(navigationReadings: navigationReadings, modelContext: context)) {
                    Image(systemName: "gear")
                        .dynamicTypeSize(.xxxLarge)
                        .foregroundStyle(Color(UIColor.systemGray))
                }
                NavigationLink(destination: MapView()) {
                    Image(systemName: "map")
                        .dynamicTypeSize(.xxxLarge)
                        .foregroundStyle(Color(UIColor.systemGray))
                }
                NavigationLink(destination: WaypointListView()) {
                    Image(systemName: "scope")
                        .dynamicTypeSize(.xxxLarge)
                        .foregroundStyle(Color(UIColor.systemGray))
                }
            }
        }
    }
}

#Preview {
    //Use geometry reader only in the preview since I am using one in the UltimateView
    GeometryProvider { width, _ in
                
        UltimateNavigationView()
            .environment(NMEAParser())
            .modelContainer(for: [UserSettingsMenu.self])
            .background(Color.black)
    }
    .aspectRatio(contentMode: .fit)
    
}
