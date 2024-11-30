//
//  SettingsMenuViewModel.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 18.11.24.
//

import SwiftUI
import SwiftData

final class SettingsMenuViewModel: ObservableObject {
    @Published var changeUnits: Bool = false
    
    private var navigationReadings: NMEAParser
    private var modelContext: ModelContext
    
    init(navigationReadings: NMEAParser, modelContext: ModelContext) {
        
        self.navigationReadings = navigationReadings
        self.modelContext = modelContext
        loadSettings()
    }
    //fetch last settings used in the user menu
    func loadSettings() {
        do {
            let fetchDescriptor = FetchDescriptor<UserSettingsMenu>()
            let fetchedSettings = try modelContext.fetch(fetchDescriptor)

            if let lastSetting = fetchedSettings.last {
                changeUnits = lastSetting.metricToggle
                navigationReadings.isMetricSelected = changeUnits
            } else {
                // Added explicit type annotation for `defaultSettings`
                let defaultSettings: UserSettingsMenu = UserSettingsMenu(metricToggle: false)
                modelContext.insert(defaultSettings)
                changeUnits = defaultSettings.metricToggle
            }
        } catch {
            print("Error fetching settings: \(error)")
        }
    }
    
    func updateSettings() {
        // Added explicit type annotation for `newSettings`
        let newSettings: UserSettingsMenu = UserSettingsMenu(metricToggle: changeUnits)
        modelContext.insert(newSettings)
        navigationReadings.isMetricSelected = changeUnits
    }
}

