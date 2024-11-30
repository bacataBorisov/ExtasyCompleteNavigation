//
//  VMGModels.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 26.11.24.
//

import SwiftData


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
