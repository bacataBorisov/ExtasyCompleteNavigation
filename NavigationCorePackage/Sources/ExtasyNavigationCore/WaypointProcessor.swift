import Foundation
import CoreLocation
import MapKit

public final class WaypointProcessor {
    public var waypointData = WaypointData()
    public var starboardIntersection: (intersection: CLLocationCoordinate2D, distanceBoat: Double, distanceWaypoint: Double)?
    public var portsideIntersection: (intersection: CLLocationCoordinate2D, distanceBoat: Double, distanceWaypoint: Double)?

    public init() {}

    public func resetWaypointCalculations() {
        waypointData.reset()
        debugLog("Waypoint data has been reset.")
    }

    public func calculateTackState(
        currentHeading: Double,
        intersection1: (intersection: CLLocationCoordinate2D, distanceBoat: Double, distanceWaypoint: Double),
        intersection2: (intersection: CLLocationCoordinate2D, distanceBoat: Double, distanceWaypoint: Double),
        boatLocation: CLLocationCoordinate2D,
        trueWindDirection: Double,
        sailingState: String,
        optimalUpAngle: Double,
        optimalDownAngle: Double,
        twaThreshold: Double
    ) -> (currentTack: String,
          currentTackDistance: Double,
          nextLegDistance: Double,
          nextLegIntersection: CLLocationCoordinate2D,
          oppositeTack: String,
          oppositeTackDistance: Double,
          nextSailingState: String,
          unclampedAngleToFarIntersection: Double) {
        func vectorFrom(_ pointA: CLLocationCoordinate2D, to pointB: CLLocationCoordinate2D) -> (x: Double, y: Double) {
            let deltaX = pointB.longitude - pointA.longitude
            let deltaY = pointB.latitude - pointA.latitude
            return (x: deltaX, y: deltaY)
        }

        func angleBetween(_ vector1: (x: Double, y: Double), _ vector2: (x: Double, y: Double)) -> Double {
            let cross = vector1.x * vector2.y - vector1.y * vector2.x
            let dot = vector1.x * vector2.x + vector1.y * vector2.y
            return atan2(cross, dot)
        }

        let headingRad = toRadians(currentHeading)
        let boatHeadingVector = (x: sin(headingRad), y: cos(headingRad))

        let vectorToIntersection1 = vectorFrom(boatLocation, to: intersection1.intersection)
        let vectorToIntersection2 = vectorFrom(boatLocation, to: intersection2.intersection)

        let unclampedAngle1 = normalizeAngleTo180(toDegrees(angleBetween(boatHeadingVector, vectorToIntersection1)))
        let unclampedAngle2 = normalizeAngleTo180(toDegrees(angleBetween(boatHeadingVector, vectorToIntersection2)))

        let clampedAngle1 = normalizeAngleTo90(unclampedAngle1)
        let clampedAngle2 = normalizeAngleTo90(unclampedAngle2)

        let (
            currentTack,
            currentTackDistance,
            nextLegDistance,
            nextLegIntersection,
            oppositeTack,
            oppositeTackDistance,
            unclampedAngleToFarIntersection
        ) = {
            if abs(clampedAngle1) < abs(clampedAngle2) {
                return (
                    "Current Tack",
                    intersection1.distanceBoat,
                    intersection1.distanceWaypoint,
                    intersection1.intersection,
                    "Opposite Tack",
                    intersection2.distanceBoat,
                    unclampedAngle1
                )
            } else {
                return (
                    "Current Tack",
                    intersection2.distanceBoat,
                    intersection2.distanceWaypoint,
                    intersection2.intersection,
                    "Opposite Tack",
                    intersection1.distanceBoat,
                    unclampedAngle2
                )
            }
        }()

        return (
            currentTack,
            currentTackDistance,
            nextLegDistance,
            nextLegIntersection,
            oppositeTack,
            oppositeTackDistance,
            sailingState,
            unclampedAngleToFarIntersection
        )
    }

    public func calculateTrueMarkBearing(from currentLocation: CLLocationCoordinate2D, to waypoint: CLLocationCoordinate2D) -> Double {
        let lat1 = toRadians(currentLocation.latitude)
        let lon1 = toRadians(currentLocation.longitude)
        let lat2 = toRadians(waypoint.latitude)
        let lon2 = toRadians(waypoint.longitude)

        let deltaLon = lon2 - lon1
        let x = cos(lat2) * sin(deltaLon)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)

        let initialBearing = atan2(x, y)
        let trueMarkBearing = toDegrees(initialBearing).truncatingRemainder(dividingBy: 360)
        return trueMarkBearing >= 0 ? trueMarkBearing : trueMarkBearing + 360
    }

    public func findIntersection(
        line1Start: CLLocationCoordinate2D,
        line1End: CLLocationCoordinate2D,
        line2Start: CLLocationCoordinate2D,
        line2End: CLLocationCoordinate2D,
        maxDistance: Double
    ) -> CLLocationCoordinate2D? {
        let p1 = MKMapPoint(line1Start)
        let p2 = MKMapPoint(line1End)
        let p3 = MKMapPoint(line2Start)
        let p4 = MKMapPoint(line2End)

        let a1 = p2.y - p1.y
        let b1 = p1.x - p2.x
        let c1 = a1 * p1.x + b1 * p1.y

        let a2 = p4.y - p3.y
        let b2 = p3.x - p4.x
        let c2 = a2 * p3.x + b2 * p3.y

        let determinant = a1 * b2 - a2 * b1
        if abs(determinant) < .ulpOfOne {
            Log.navigation.debug("Lines are parallel or coincident.")
            return nil
        }

        let intersectionX = (b2 * c1 - b1 * c2) / determinant
        let intersectionY = (a1 * c2 - a2 * c1) / determinant
        let intersection = MKMapPoint(x: intersectionX, y: intersectionY).coordinate

        let totalLine1Length = p1.distance(to: p2)
        let totalLine2Length = p3.distance(to: p4)
        let distanceLine1ToIntersection = min(p1.distance(to: MKMapPoint(intersection)), p2.distance(to: MKMapPoint(intersection)))
        let distanceLine2ToIntersection = min(p3.distance(to: MKMapPoint(intersection)), p4.distance(to: MKMapPoint(intersection)))

        if distanceLine1ToIntersection > totalLine1Length || distanceLine2ToIntersection > totalLine2Length {
            Log.navigation.debug("Intersection is outside the line segments.")
            return nil
        }

        let distanceFromStart1 = p1.distance(to: MKMapPoint(intersection))
        let distanceFromStart2 = p3.distance(to: MKMapPoint(intersection))
        if distanceFromStart1 > maxDistance || distanceFromStart2 > maxDistance {
            Log.navigation.debug("Intersection is too far: \(distanceFromStart1), \(distanceFromStart2), max: \(maxDistance)")
            return nil
        }

        return intersection
    }

    public func generateDiamondLaylines(
        boatLocation: CLLocationCoordinate2D,
        waypoint: CLLocationCoordinate2D,
        windDirection: Double,
        optimalUpTWA: Double,
        optimalDnTWA: Double,
        sailingState: String,
        boatToWaypointDistance: Double
    ) -> ([Layline], [(intersection: CLLocationCoordinate2D, distanceBoat: Double, distanceWaypoint: Double)]) {
        let normalizedWindDirection = normalizeAngle(windDirection)

        let tackAngle: Double
        switch sailingState {
        case "Upwind":
            tackAngle = optimalUpTWA
        case "Downwind":
            tackAngle = optimalDnTWA
        default:
            debugLog("Sailing state is in transition or undefined. Defaulting to Upwind laylines.")
            tackAngle = optimalUpTWA
        }

        let laylineDistance = max(boatToWaypointDistance * 4.0, 200_000.0)

        let starboardBoatLayline = calculateLaylineCoordinates(
            start: boatLocation,
            bearing: normalizedWindDirection + tackAngle,
            distance: laylineDistance
        )
        let portsideBoatLayline = calculateLaylineCoordinates(
            start: boatLocation,
            bearing: normalizedWindDirection - tackAngle,
            distance: laylineDistance
        )
        let starboardWaypointLayline = calculateLaylineCoordinates(
            start: waypoint,
            bearing: normalizedWindDirection + tackAngle + 180,
            distance: laylineDistance
        )
        let portsideWaypointLayline = calculateLaylineCoordinates(
            start: waypoint,
            bearing: normalizedWindDirection - tackAngle + 180,
            distance: laylineDistance
        )

        let starboardIntersection = findIntersection(
            line1Start: boatLocation,
            line1End: starboardBoatLayline,
            line2Start: waypoint,
            line2End: portsideWaypointLayline,
            maxDistance: laylineDistance
        )

        let portsideIntersection = findIntersection(
            line1Start: boatLocation,
            line1End: portsideBoatLayline,
            line2Start: waypoint,
            line2End: starboardWaypointLayline,
            maxDistance: laylineDistance
        )

        var intersections: [(intersection: CLLocationCoordinate2D, distanceBoat: Double, distanceWaypoint: Double)] = []
        if let starboardIntersection {
            let distanceBoat = calculateDistance(from: boatLocation, to: starboardIntersection)
            let distanceWaypoint = calculateDistance(from: waypoint, to: starboardIntersection)
            intersections.append((intersection: starboardIntersection, distanceBoat: distanceBoat, distanceWaypoint: distanceWaypoint))
        }
        if let portsideIntersection {
            let distanceBoat = calculateDistance(from: boatLocation, to: portsideIntersection)
            let distanceWaypoint = calculateDistance(from: waypoint, to: portsideIntersection)
            intersections.append((intersection: portsideIntersection, distanceBoat: distanceBoat, distanceWaypoint: distanceWaypoint))
        }

        return (
            [
                Layline(start: boatLocation, end: starboardBoatLayline),
                Layline(start: boatLocation, end: portsideBoatLayline),
                Layline(start: waypoint, end: starboardWaypointLayline),
                Layline(start: waypoint, end: portsideWaypointLayline)
            ],
            intersections
        )
    }

    public func calculateLaylineCoordinates(
        start: CLLocationCoordinate2D,
        bearing: Double,
        distance: Double
    ) -> CLLocationCoordinate2D {
        let earthRadius = 6_371_000.0
        let angularDistance = distance / earthRadius
        let bearingRad = toRadians(bearing)

        let startLatRad = toRadians(start.latitude)
        let startLonRad = toRadians(start.longitude)

        let endLat = asin(
            sin(startLatRad) * cos(angularDistance) +
            cos(startLatRad) * sin(angularDistance) * cos(bearingRad)
        )

        let endLon = startLonRad + atan2(
            sin(bearingRad) * sin(angularDistance) * cos(startLatRad),
            cos(angularDistance) - sin(startLatRad) * sin(endLat)
        )

        return CLLocationCoordinate2D(latitude: toDegrees(endLat), longitude: toDegrees(endLon))
    }
}
