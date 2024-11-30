//
//  UltimateViewMatrixModel.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 26.11.24.
//

import SwiftData

@Model
class UltimateMatrix {
   
    var ultimateSpeed: [Int]
    var ultimateAngle: [Int]
    
    init(ultimateSpeed: [Int], ultimateAngle: [Int]) {

        self.ultimateSpeed = ultimateSpeed
        self.ultimateAngle = ultimateAngle
    }
}
