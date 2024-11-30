//
//  Waypoints.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 22.11.24.
//
//  Model for persistent data of the waypoints

import SwiftData

@Model

class Waypoints {

    @Attribute(.unique) var title = ""
    var lat: Double?
    var lon: Double?
    var isTargetSelected: Bool = false

    init(title: String = "", lat: Double? = nil, lon: Double? = nil, isTargetSelected: Bool = false) {
        self.title = title
        self.lat = lat
        self.lon = lon
        self.isTargetSelected = isTargetSelected
    }

}
