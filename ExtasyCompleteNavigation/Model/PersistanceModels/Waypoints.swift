import SwiftUI
import SwiftData

@Model
class Waypoints: Identifiable {
    var title = ""
    var lat: Double?
    var lon: Double?
    var isTargetSelected: Bool = false

    var id = UUID() // Unique identifier

    init(title: String = "", lat: Double? = nil, lon: Double? = nil, isTargetSelected: Bool = false) {
        self.title = title
        self.lat = lat
        self.lon = lon
        self.isTargetSelected = isTargetSelected
    }
}
