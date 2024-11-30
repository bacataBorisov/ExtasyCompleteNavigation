//
//  GaugeMarkerCompass.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 25.11.24.
//
import Foundation

struct GaugeMarkerCompass: Identifiable, Hashable {
    let id = UUID()
    
    let degrees: Double
    let label: String
    
    init(degrees: Double, label: String) {
        self.degrees = degrees
        self.label = label
    }
    
    // adjust according to your needs
    static func labelSet() -> [GaugeMarker] {
        return [
            GaugeMarker(degrees: 0, label: "N"),
            GaugeMarker(degrees: 30, label: "30"),
            GaugeMarker(degrees: 60, label: "60"),
            GaugeMarker(degrees: 90, label: "E"),
            GaugeMarker(degrees: 120, label: "120"),
            GaugeMarker(degrees: 150, label: "150"),
            GaugeMarker(degrees: 180, label: "S"),
            GaugeMarker(degrees: 210, label: "210"),
            GaugeMarker(degrees: 240, label: "240"),
            GaugeMarker(degrees: 270, label: "W"),
            GaugeMarker(degrees: 300, label: "300"),
            GaugeMarker(degrees: 330, label: "330")
            
        ]
    }
}
