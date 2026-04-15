import CoreLocation

public struct Layline: Hashable {
    public let start: CLLocationCoordinate2D
    public let end: CLLocationCoordinate2D

    public init(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) {
        self.start = start
        self.end = end
    }

    public static func == (lhs: Layline, rhs: Layline) -> Bool {
        lhs.start.latitude == rhs.start.latitude &&
        lhs.start.longitude == rhs.start.longitude &&
        lhs.end.latitude == rhs.end.latitude &&
        lhs.end.longitude == rhs.end.longitude
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(start.latitude)
        hasher.combine(start.longitude)
        hasher.combine(end.latitude)
        hasher.combine(end.longitude)
    }
}
