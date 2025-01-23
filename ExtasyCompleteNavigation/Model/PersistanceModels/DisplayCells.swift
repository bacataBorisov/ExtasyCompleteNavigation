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
    
    // Optional toggle behavior
    var toggleTargetID: Int? // Optional ID to toggle to

}

// MARK: - Predefined Display Cell Data for Navigation Metrics
let staticMultiDisplayCells: [MultiDisplayCells] = [
    
    MultiDisplayCells(
        id: 0,
        name: "DPT",
        units: "m",
        valueHasMetric: false,
        metric: "",
        specifier: "%.1f",
        tag: "other"),
    
    MultiDisplayCells(
        id: 1,
        name: "HDG",
        units: "°",
        valueHasMetric: false,
        metric: "",
        specifier: "%.f",
        tag: "other"),
    
    MultiDisplayCells(
        id: 2,
        name: "SWT",
        units: "°C",
        valueHasMetric: false,
        metric: "",
        specifier: "%.1f",
        tag: "other"),
    
    MultiDisplayCells(
        id: 3,
        name: "BSPD",
        units: "kn",
        valueHasMetric: false,
        metric: "",
        specifier: "%.2f",
        tag: "speed"),
    
    MultiDisplayCells(
        id: 4,
        name: "AWA",
        units: "°",
        valueHasMetric: false,
        metric: "",
        specifier: "%.f",
        tag: "wind"),
    
    MultiDisplayCells(
        id: 5,
        name: "AWD",
        units: "°",
        valueHasMetric: false,
        metric: "",
        specifier: "%.f",
        tag: "wind"),
    
    MultiDisplayCells(
        id: 6,
        name: "AWS",
        units: "kn",
        valueHasMetric: true,
        metric: "m/s",
        specifier: "%.1f",
        tag: "wind"),
    
    MultiDisplayCells(
        id: 7,
        name: "TWA",
        units: "°",
        valueHasMetric: false,
        metric: "",
        specifier: "%.f",
        tag: "wind"),
    
    MultiDisplayCells(
        id: 8,
        name: "TWD",
        units: "°",
        valueHasMetric: false,
        metric: "",
        specifier: "%.f",
        tag: "wind"),
    
    MultiDisplayCells(
        id: 9,
        name: "TWS",
        units: "kn",
        valueHasMetric: true,
        metric: "m/s",
        specifier: "%.1f",
        tag: "wind"),
    
    MultiDisplayCells(
        id: 10,
        name: "COG",
        units: "°",
        valueHasMetric: false,
        metric: "",
        specifier: "%.f",
        tag: "other"),
    
    MultiDisplayCells(
        id: 11,
        name: "SOG",
        units: "kn",
        valueHasMetric: false,
        metric: "",
        specifier: "%.2f",
        tag: "speed")
    
    ]

// MARK: - Global Access to Static Data
var displayCell: [MultiDisplayCells] = staticMultiDisplayCells
