//
//  MultiDisplayMatrixModel.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 26.11.24.
//

import SwiftData

@Model
class Matrix {
    
    var identifier: [Int]

    init(identifier: [Int]) {
        self.identifier = identifier

    }
}
