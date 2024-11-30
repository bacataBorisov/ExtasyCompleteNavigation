//
//  UserSettingsMenuModel.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 26.11.24.
//
//MARK: - User Settings Menu Persistance

import SwiftData

@Model
class UserSettingsMenu {
    var metricToggle: Bool
    var waypointTrue: Bool
    
    init(metricToggle: Bool = false, waypointTrue: Bool = false) {
        self.metricToggle = metricToggle
        self.waypointTrue = waypointTrue
    }
}
