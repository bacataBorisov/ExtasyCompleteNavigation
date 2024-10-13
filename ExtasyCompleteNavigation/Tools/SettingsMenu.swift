//
//  SettingsMenu.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 6.10.23.
//

import SwiftUI
import SwiftData

struct SettingsMenu: View {
    
    @State private var changeUnits = false
    
    @Environment(NMEAReader.self) private var navigationReadings
    
    @Environment(\.modelContext) private var context
    @Query var lastSettings: [UserSettingsMenu]
    
    var body: some View {
        VStack(spacing: 0){

            List(){

                Toggle("Metric Wind", isOn: $changeUnits)
                    .onAppear(perform: {
                        if !lastSettings.isEmpty {
                            changeUnits = lastSettings.last!.metricToggle
                        }
                    })
                    .onChange(of: changeUnits) { oldValue, newValue in
                        let lastSettings = UserSettingsMenu(metricToggle: newValue)
                        context.insert(lastSettings)
                        navigationReadings.isMetricSelected = newValue
                    }
                NavigationLink("Raw Navigation Data", destination: RawNavigationData())
                //TODO: - this will lead to a view that will give more information about the units used.
                Text("Glossary")
                //TODO: - this will lead to a menu that you can select different alarm levels for the different values
                Text("Set Alarms")
                
                /*
                 Button are used during debugging for easier access to the socket communication functions. In the real world the app connects automatically once in the same network and disconnects when the app exits
                 */
                
                //Button("Start") { navigationReadings.start() }
                //Button("Stop") { navigationReadings.stop() }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsMenu()
        .environment(NMEAReader())
        .modelContainer(for: UserSettingsMenu.self)
    
}
