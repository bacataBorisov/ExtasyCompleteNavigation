//
//  VMGCalculator.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 23.09.23.
//

import Foundation

class VMGCalculator {
    
    //VMG = Velocity Made Good - is the optimup angle against the wind
    //VMG formula
    // VMG = SOG*cos(tita), where tita = angle between COG and TWA
    
    let SMALL: Double = 1.0e-5;
    let DEG_TO_RAD: Double = 0.017453292519943295769236907684886;
    
    private var WIND_CNT = Int()
    private var GRADUS_CNT = Int()
    private var wind = [Double]()
    private var gradus = [Double]()
    private var diagram = [[Double]]()
    private var fullDiagram = [[String]]()
    
    func toRadians(degrees: Double) -> Double {
        return (Double.pi / 180.0) * degrees
    }
    func toDegrees(radians: Double) -> Double {
        return radians * (180.0 / Double.pi)
    }
    
    
//MARK: - This might be wrong and probably deleted
//    func calculateVMG(boatSpeed: Double, windAngle: Double) -> Double {
//
//        var trueWindAngle = toRadians(degrees: windAngle)
//        if trueWindAngle < 0 {
//            trueWindAngle *= (-1)
//        }
//        
//        let vmg = boatSpeed*cos(trueWindAngle)
//        //print("PRINTING FROM VMG CALC FUNCTION")
//        //print("boat speed is: [\(boatSpeed)], TWA is: [\(windAngle)]")
//        
//        
//        //I think that VMG should always be positive, it is easier to read.
//        //This needs to be confirmed
//        if vmg <= 0 {
//            return vmg * (-1)
//        }
//        return vmg
//    }
    
    func eval_cubic_spline(u: Double, xa: Double, xb: Double, xc: Double, xd: Double) -> Double {
        var c = Double()
        
        // Check the value of u
        if (u < -SMALL || u > 1.0 + SMALL)
        {
            print("Attempt ot evaluate outside of [0,1] range")
        }
        c = u * u * u * (-1 * xa + 3 * xb - 3 * xc + xd) + u * u * (3 * xa - 6 * xb + 3 * xc) + u * (-3 * xa + 3 * xc) + (xa + 4 * xb + xc)
        c = c / 6.0
        
        //print("c is: \(c)")
        
        return c
    }
    //MARK: - Takes the VMG from the Polar Diagram
    func readDiagram() {
        //open a file reading from file
        let path = Bundle.main.path(forResource:"diagram", ofType: "txt")
        guard let file = freopen(path, "r", stdin) else {
            fatalError("Couldn't open polar diagram file")
        }
        
        // first pass, count lines and columns - not empty only
        // and locate arrays
        
        var rowCount = 0
        while let line = readLine(){
            if line.isEmpty {
                continue
            }
            rowCount += 1
            
            if rowCount == 1 {
                //split the string to count the columns
                let tokens = line.components(separatedBy: " ")
                var columnCount = 0
                for column in tokens {
                    if column.isEmpty{
                        continue
                    }
                    columnCount += 1
                }
                //            print("columns: \(columnCount)")
                WIND_CNT = columnCount - 1
                //            print("WIND_CNT: \(WIND_CNT)")
                //creating a new Array with 1 element less because of the first column
                //this is preparation for the partial diagram that will be filled later
                wind = Array(repeating: 0, count: WIND_CNT)
                //            print("windArray is: \(wind)")
            }
        }
        //    print("rows: \(rowCount)")
        GRADUS_CNT = rowCount - 1
        //    print("GRADUS_CNT is: \(GRADUS_CNT)")
        //same goes here - preparing for the new partial diagram - with one row less
        gradus = Array(repeating: 0, count: GRADUS_CNT)
        //    print("gradusArray is: \(gradus)")
        diagram = Array(repeating: Array(repeating: 0, count: WIND_CNT), count: GRADUS_CNT)
        //pay attention when dealing with 2D arrays - kind of tricky
        //    print("partialDiagram will be: \(GRADUS_CNT) rows X \(WIND_CNT) columns")
        fclose(file)
        //second pass on the array to read the values in fill them into the partial diagram
        
        
        guard let file = freopen(path, "r", stdin) else {
            fatalError("Couldn't open polar diagram file")
        }
        
        rowCount = 0
        while let line = readLine(){
            var columnCount = 0
            if (!line.isEmpty){
                let tokens = line.components(separatedBy: " ")
                for column in tokens {
                    if (!column.isEmpty) {
                        //print(rowCount, columnCount)
                        if (rowCount == 0 && columnCount > 0) {
                            if (columnCount <= WIND_CNT) {
                                
                                wind[columnCount - 1] = Double(column) ?? 666 // 666 means error
                                //print("new windArray is: \(wind)")
                            }
                        } else if (rowCount > 0 && columnCount == 0) {
                            if (rowCount <= GRADUS_CNT) {
                                
                                gradus[rowCount - 1] = Double(column) ?? 666 // 666 -> means error
                                //print("new gradusArray is: \(gradus)")
                            }
                        } else if (rowCount > 0 && columnCount > 0 ) {
                            if (rowCount <= (GRADUS_CNT) && columnCount <= (WIND_CNT)){
                                diagram[rowCount - 1][columnCount - 1] = Double(column) ?? 666 // 66 means eror
                                
                            }
                        }
                        columnCount += 1
                    }
                }
                rowCount += 1
            }
        }
        //    print("wind force diagram is: \(wind)")
        //    print("angle diagram is: \(gradus)")
        //    print("partial diagram is: \(diagram)\n")
        fclose(file)
        //print(diagram)
    }
    
    func evaluate_diagram(windForce: Double, windAngle: Double) -> Double {
        
        if diagram.isEmpty {
            readDiagram()
            //print(diagram)
        }
        
        
        var finalWindAngle = Double()
        var finalWindForce = Double()
        
        finalWindAngle = windAngle
        if finalWindAngle < 0 {
            finalWindAngle = finalWindAngle * (-1)
        }
        if windForce <= wind[0]{
            return 0.0
        }
        
        if finalWindAngle <= gradus[0] {
            return 0
        }
        
        // the last found index could be max upper bound - 2
        // because spline will be calculated with j+2 - from Joro source file VMG.java
        
        var j = 0
        while j < (WIND_CNT - 2){
            if (windForce >= wind[j] && windForce < wind[j + 1] || j + 1 == WIND_CNT - 2)
            {
                break;
            }
            j += 1
        }
        
        //this is the range when you are inside the diagram, otherwise you are outside our diagram
        finalWindForce = 1.0 / ((wind[j + 1] - wind[j]) / (windForce - wind[j]))
        
        if (finalWindForce < -SMALL)
        {
            finalWindForce = finalWindForce + SMALL
        }
        
        if (finalWindForce < -SMALL || finalWindForce > 1.0 + SMALL)
        {
            return 0.0
        }
        
        while (finalWindAngle > 360.0)
        {
            finalWindAngle = finalWindAngle - 360.0
        }
        
        if (finalWindAngle > 180.0)
        {
            finalWindAngle = 360.0 - finalWindAngle
        }
        
        if (finalWindAngle <= gradus[1])
        {
            return 0.0
        }
        
        // the last found index could be max upper bound - 2
        // because spline will be calculated with i+2
        var i = 0
        while i < (GRADUS_CNT - 2){
            if (finalWindAngle >= gradus[i] && finalWindAngle < gradus[i + 1] || i + 1 == GRADUS_CNT - 2)
            {
                break;
            }
            i += 1
        }
        
        finalWindAngle = 1.0 / ((gradus[i + 1] - gradus[i]) / (finalWindAngle - gradus[i]))
        
        if (finalWindAngle < -SMALL)
        {
            finalWindAngle = finalWindAngle + SMALL
        }
        
        //print(finalWindAngle, finalWindForce)
        
        
        let i0 = i > 0 ? i - 1 : i
        let i1 = i
        let i2 = i+1
        let i3 = i+2
        
        let j0 = j > 0 ? j - 1 : j
        let j1 = j
        let j2 = j+1
        let j3 = j+2
        
        
        let dWind1 = eval_cubic_spline(u: finalWindForce, xa: diagram[i0][j0], xb: diagram[i0][j1], xc: diagram[i0][j2], xd: diagram[i0][j3])
        let dWind2 = eval_cubic_spline(u: finalWindForce, xa: diagram[i1][j0], xb: diagram[i1][j1], xc: diagram[i1][j2], xd: diagram[i1][j3])
        let dWind3 = eval_cubic_spline(u: finalWindForce, xa: diagram[i2][j0], xb: diagram[i2][j1], xc: diagram[i2][j2], xd: diagram[i2][j3])
        let dWind4 = eval_cubic_spline(u: finalWindForce, xa: diagram[i3][j0], xb: diagram[i3][j1], xc: diagram[i3][j2], xd: diagram[i3][j3])
        
        let ret = eval_cubic_spline(u: finalWindAngle, xa: dWind1, xb: dWind2, xc: dWind3, xd: dWind4)
        //print("for windForce: \(windForce) & windAngle: \(windAngle) VMG is: \(ret)")
        return ret
        
    }
    
}
