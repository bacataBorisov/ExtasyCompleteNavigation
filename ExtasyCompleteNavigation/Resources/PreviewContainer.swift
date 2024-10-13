////
////  PreviewContainer.swift
////  ExtasyCompleteNavigation
////
////  Created by Vasil Borisov on 30.01.24.
////
//
//import Foundation
//import SwiftData
//
//@MainActor
//let previewContainer: ModelContainer = {
//    do {
//        let container = try ModelContainer(
//            for: Matrix.self
//        )
//        
////        // Make sure the persistent store is empty. If it's not, return the non-empty container.
////        var itemFetchDescriptor = FetchDescriptor<NavigationReadings>()
////        itemFetchDescriptor.fetchLimit = 1
////        
////        guard try container.mainContext.fetch(itemFetchDescriptor).count == 0 else { return container }
////        
////        let items = [
////        
////        NavigationReadings(title: 0, name: "DPT", dimension: "m", specifier: "%.2f", tag: "other"),
////        NavigationReadings(title: 1, name: "HDG", dimension: "°", specifier: "%.f", tag: "other"),
////        NavigationReadings(title: 2, name: "SWT", dimension: "°C", specifier: "%.1f", tag: "other"),
////        NavigationReadings(title: 3, name: "BSPD", dimension: "kn", specifier: "%.2f", tag: "speed"),
////        NavigationReadings(title: 4, name: "AWA", dimension: "°", specifier: "%.f", tag: "wind"),
////        NavigationReadings(title: 5, name: "AWD", dimension: "°", specifier: "%.f", tag: "wind"),
////        NavigationReadings(title: 6, name: "AWS", dimension: "kn", specifier: "%.1f", tag: "wind"),
////        NavigationReadings(title: 7, name: "TWA", dimension: "°", specifier: "%.f", tag: "wind"),
////        NavigationReadings(title: 8, name: "TWD", dimension: "°", specifier: "%.f", tag: "wind"),
////        NavigationReadings(title: 9, name: "TWS", dimension: "°", specifier: "%.1f", tag: "wind"),
////        NavigationReadings(title: 10, name: "COG", dimension: "kn", specifier: "%.2f", tag: "speed"),
////        NavigationReadings(title: 11, name: "SOG", dimension: "kn", specifier: "%.2f", tag: "speed"),
////        NavigationReadings(title: 12, name: "pSPD", dimension: "kn", specifier: "%.2f", tag: "speed"),
////        NavigationReadings(title: 13, name: "VMC", dimension: "", specifier: "%.2f", tag: "speed"),
////        NavigationReadings(title: 14, name: "VMG", dimension: "", specifier: "%.2f", tag: "speed")
////        
////        ]
////        let item = Matrix(identifier: [0, 1, 2, 3])
//        
//        container.mainContext.insert(item)
//
//        return container
//    } catch {
//        fatalError("Failed to create container")
//    }
//}()
