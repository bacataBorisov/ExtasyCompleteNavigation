//
//  ConfigModel.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 4.12.23.
//

/* You can add as many models as you want and you will use the same container for the whole app!!!*/


import Foundation
import SwiftData
import MapKit

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

@Model

class Matrix {
    
    var identifier: [Int]

    
    init(identifier: [Int]) {
        self.identifier = identifier

    }
}

@Model
class UltimateMatrix {
   
    var ultimateSpeed: [Int]
    var ultimateAngle: [Int]
    
    init(ultimateSpeed: [Int], ultimateAngle: [Int]) {

        self.ultimateSpeed = ultimateSpeed
        self.ultimateAngle = ultimateAngle
    }
}
//MARK: - Model Class and Enum for the Bearing to Waypoint Angle - True or Relativa
enum WaypointAngle: Codable {
    
    case relativeAngle
    case trueAngle
}

@Model
class BearingToMarkUnitsMenu {
    
    var angle: WaypointAngle
    
    init(angle: WaypointAngle = .relativeAngle) {
        self.angle = angle
    }
}



//MARK: - Model Class and Enum for the distance menu in the VMG View and its persistance
enum Distance: CaseIterable, Codable {
    
    case nauticalMiles
    case nauticalCables
    case meters
    case boatLength
}

@Model
class NauticalDistance {
    var distance: Distance
    
    //init with backing data
    init(distance: Distance = .meters) {
        self.distance = distance
    }
}

//MARK: - Model Class and Enum for the distance menu in the VMG View and its persistance
enum NextTackDistance: CaseIterable, Codable {
    
    case nauticalMiles
    case nauticalCables
    case meters
    case boatLength
}

@Model
class NextTackNauticalDistance {
    var distance: NextTackDistance
    
    //init with backing data
    init(distance: NextTackDistance = .meters) {
        self.distance = distance
    }
}

//MARK: - Model Class and Enum for the Coordinates View - Boat's or Waypoint
enum CoordinatesSwitch: Codable {
    
    case boatCoordinates
    case waypointCoordinates
}

@Model
class SwitchCoordinatesView {
    
    var position: CoordinatesSwitch
    
    init(position: CoordinatesSwitch = .boatCoordinates) {
        self.position = position
    }
}


//MARK: - User Settings Menu Persistance
@Model
class UserSettingsMenu {
    var metricToggle: Bool
    var waypointTrue: Bool
    
    init(metricToggle: Bool = false, waypointTrue: Bool = false) {
        self.metricToggle = metricToggle
        self.waypointTrue = waypointTrue
    }
}

