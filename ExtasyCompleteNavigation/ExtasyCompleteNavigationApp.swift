//
//  ExtasyCompleteNavigationApp.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 13.06.23.
//

import SwiftUI
import SwiftData

@main

struct ExtasyCompleteNavigationApp: App {
    
    //init model container here for waypoint, so the preview on the detaildWPView will work.
    //it is different than the example givens but this way work, I still don't know why
    let modelContainer: ModelContainer
    
    init() {
      do {
          
          
          let config = ModelConfiguration(for:  Waypoints.self,
                                                Matrix.self,
                                                UltimateMatrix.self,
                                                UserSettingsMenu.self,
                                                BearingToMarkUnitsMenu.self,
                                                NauticalDistance.self,
                                                NextTackNauticalDistance.self,
                                                SwitchCoordinatesView.self,
                                                isStoredInMemoryOnly: true)
          
          modelContainer = try ModelContainer(for:  Waypoints.self,
                                                    Matrix.self,
                                                    UltimateMatrix.self,
                                                    UserSettingsMenu.self,
                                                    BearingToMarkUnitsMenu.self,
                                                    NauticalDistance.self,
                                                    NextTackNauticalDistance.self,
                                                    SwitchCoordinatesView.self,
                                                    configurations: config)
      } catch {
        fatalError("Could not initialize ModelContainer for these guys")
      }
    }


    //MARK: - Environment Property for the NMEAReader Class
    @State private var navigationReadings = NMEAReader()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(navigationReadings)
        }
        //creating container for the SwiftData
        .modelContainer(for: [
            Waypoints.self,
            Matrix.self,
            UltimateMatrix.self,
            UserSettingsMenu.self,
            BearingToMarkUnitsMenu.self,
            NauticalDistance.self,
            NextTackNauticalDistance.self,
            SwitchCoordinatesView.self])
        
        
        
        

    }
}
