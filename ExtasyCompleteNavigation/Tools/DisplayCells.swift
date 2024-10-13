//
//  DisplayCells.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 6.10.23.
//

import Foundation

struct MultiDisplayCells: Hashable, Codable, Identifiable {
    
    var id: Int
    var name: String
    var units: String
    //check if the value can be converted to metric units
    var valueHasMetric: Bool
    var metric: String
    var specifier: String
    var tag: String

}


