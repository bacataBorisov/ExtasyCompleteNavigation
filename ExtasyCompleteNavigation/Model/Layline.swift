import CoreLocation

struct Layline: Hashable {
    let start: CLLocationCoordinate2D
    let end: CLLocationCoordinate2D

    static func == (lhs: Layline, rhs: Layline) -> Bool {
        lhs.start.latitude == rhs.start.latitude &&
        lhs.start.longitude == rhs.start.longitude &&
        lhs.end.latitude == rhs.end.latitude &&
        lhs.end.longitude == rhs.end.longitude
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(start.latitude)
        hasher.combine(start.longitude)
        hasher.combine(end.latitude)
        hasher.combine(end.longitude)
    }
}
