import Foundation
import CoreLocation
import MapKit

class WaypointProcessor {
    // Reference to shared WaypointData
    var waypointData = WaypointData()
    var starboardIntersection: (intersection: CLLocationCoordinate2D, distanceBoat: Double, distanceWaypoint: Double)? // point of intersection
    var portsideIntersection: (intersection: CLLocationCoordinate2D, distanceBoat: Double, distanceWaypoint: Double)? // point of intersection
    var tackDistance: Double?
    var tripDurationToNextTack: Double?
    var distanceOnOppositeTack: Double?
    var tripDurationOnOppositeTack: Double?
    
    // Serial queue for thread safety
    private let serialQueue = DispatchQueue(label: "com.extasy.waypointProcessor")
    
    // Flags for logging control
    private var hasLoggedWaypointSkipped = false
    private var hasLoggedWaypointInitialized = false
    
    // MARK: - Reset Waypoint Data
    func resetWaypointCalculations() {
        waypointData.reset()
        debugLog("Waypoint data has been reset.")
    }
    
    // MARK: - Process Waypoint Data
    func processWaypointData(
        vmgData: VMGData?,
        gpsData: GPSData?,
        windData: WindData?
    ) -> WaypointData? {
        serialQueue.sync { [self] in
            guard let polarSpeed = vmgData?.polarSpeed,
                  let markerCoordinate = gpsData?.waypointLocation,
                  let boatLocation = gpsData?.boatLocation,
                  let courseOverGround = gpsData?.courseOverGround,
                  let speedOverGround = gpsData?.speedOverGround,
                  let trueWindDirection = windData?.trueWindDirection,
                  let optimalUpTWA = vmgData?.optimalUpTWA,
                  let optimalDnTWA = vmgData?.optimalDnTWA,
                  let sailingState = vmgData?.sailingState,
                  let sailingStateLimit = vmgData?.sailingStateLimit else {
            
                return
            }
            
            
            // MARK: - Current Tack Calculations
            let distanceToMark = calculateDistance(from: boatLocation, to: markerCoordinate)
            
            let trueMarkBearing = calculateTrueMarkBearing(from: boatLocation, to: markerCoordinate)
            let relativeMarkBearing = calculateRelativeMarkBearing(
                trueMarkBearing: trueMarkBearing,
                courseOverGround: courseOverGround
            )
            
            // MARK: - Opposite Tack Calculations
            
            // TODO: - Do not forget to get the angle based on upwind/downwind situation
            let (_, oppositeRelativeMarkBearing) = calculateOppositeTack(
                courseOverGround: speedOverGround,
                trueWindDirection: trueWindDirection,
                optimalUpwindTackAngle: optimalUpTWA,
                optimalDownwindTackAngle: optimalDnTWA,
                trueMarkBearing: trueMarkBearing,
                sailingState: sailingState)
            
            // Calculate VMC for current and opposite tacks
            let currentTackVMC = calculateVMC(speed: speedOverGround, relativeBearing: relativeMarkBearing)
            let oppositeTackVMC = calculateVMC(speed: speedOverGround, relativeBearing: oppositeRelativeMarkBearing)
            
            // Absolute values for performance calculations
            let currentTackPolarVMC = abs(calculateVMC(speed: polarSpeed, relativeBearing: relativeMarkBearing))
            let oppositeTackPolarVMC = abs(calculateVMC(speed: polarSpeed, relativeBearing: oppositeRelativeMarkBearing))
            
            // Max value for performance calculations
            let maxTackPolarVMC = max(currentTackPolarVMC, oppositeTackPolarVMC)
            
            // Performance ratios using absolute values
            let currentTackVMCPerformance = processPerformanceRatio(maxValue: maxTackPolarVMC, currentValue: abs(currentTackVMC))
            let oppositeTackVMCPerformance = processPerformanceRatio(maxValue: maxTackPolarVMC, currentValue: abs(oppositeTackVMC))
            
            // Use signed values for directional feedback
            let currentTackVMCDisplay = abs(currentTackVMC)
            let oppositeTackVMCDisplay = abs(oppositeTackVMC)
            // MARK: - Time Calculations
            
            // Trip Duration and ETA to Waypoint
            let effectiveVMC = max(currentTackVMC, 0) // Only consider positive VMG for progress
            let tripDurationToWaypoint = distanceToMark * toNauticalMiles / effectiveVMC // in hours
            let etaToWaypoint = Date().addingTimeInterval(tripDurationToWaypoint * 3600) // in seconds
            
            let effectiveSOG = max(speedOverGround, 0) // Ensure positive SOG
            
            // MARK: - Laylines
            
            // Generate laylines and intersections
            let (laylines, intersections) = generateDiamondLaylines(
                boatLocation: boatLocation,
                waypoint: markerCoordinate,
                windDirection: trueWindDirection,
                optimalUpTWA: optimalUpTWA,
                optimalDnTWA: optimalDnTWA,
                sailingState: sailingState,
                boatToWaypointDistance: distanceToMark
            )
            
            // Assign laylines
            let starboardLayline = laylines[0]
            let portsideLayline = laylines[1]
            let extendedStarboardLayline = laylines[2]
            let extendedPortsideLayline = laylines[3]
            
            // Validate intersections before calculating tack states
            guard intersections.count >= 2 else {
                debugLog("Error: Not enough intersections to calculate tack states. Intersections count: \(intersections.count)")
                
                // Provide fallback values
                self.starboardIntersection = nil
                self.portsideIntersection = nil
                debugLog("Assigned default values for intersections and tack states.")
                return
            }
            
            // Calculate tack states
            let tackStates = calculateTackState(
                currentHeading: courseOverGround,
                intersection1: intersections[0],
                intersection2: intersections[1],
                boatLocation: markerCoordinate,
                trueWindDirection: trueWindDirection,
                sailingState: sailingState,
                optimalUpAngle: optimalUpTWA,
                optimalDownAngle: optimalDnTWA,
                twaThreshold: sailingStateLimit
            )
            
            // Safely calculate distances and durations
            let currentTackState = tackStates.currentTack
            let currentTackDistance = tackStates.currentTackDistance * toNauticalMiles
            let currentTackDuration = (effectiveSOG > 0) ? (currentTackDistance / effectiveSOG) : 0.0
            
            let oppositeTackState = tackStates.nextSailingState
            let oppositeTackDistance = tackStates.oppositeTackDistance * toNauticalMiles
            let oppositeTackDuration = (effectiveSOG > 0) ? (oppositeTackDistance / effectiveSOG) : 0.0
            
            // Debug or log results
            //debugLog("Current Tack: \(tackStates.currentTack), Distance: \(currentTackDistance) NM, Duration: \(currentTackDuration) hours")
            //debugLog("Opposite Tack: \(tackStates.oppositeTack), Distance: \(oppositeTackDistance) NM, Duration: \(oppositeTackDuration) hours")
            
            // Assign intersections (conditionally)
            if intersections.count >= 1 {
                self.starboardIntersection = intersections[0]
            }
            if intersections.count >= 2 {
                self.portsideIntersection = intersections[1]
            }
            
            // MARK: - Update Waypoint Data
            self.waypointData = WaypointData(
                distanceToMark: distanceToMark,
                trueMarkBearing: trueMarkBearing, tripDurationToWaypoint: tripDurationToWaypoint,
                etaToWaypoint: etaToWaypoint,
                tackDistance: currentTackDistance,
                tackDuration: currentTackDuration,
                distanceOnOppositeTack: oppositeTackDistance,
                tripDurationOnOppositeTack: oppositeTackDuration,
                currentTackState: currentTackState,
                currentTackRelativeBearing: relativeMarkBearing,
                oppositeTackState: oppositeTackState,
                oppositeTackRelativeBearing: oppositeRelativeMarkBearing,
                currentTackVMC: currentTackVMC,
                currentTackVMCDisplay: currentTackVMCDisplay,
                currentTackVMCPerformance: currentTackVMCPerformance, oppositeTackVMC: oppositeTackVMC,
                oppositeTackVMCDisplay: oppositeTackVMCDisplay,
                oppositeTackVMCPerformance: oppositeTackVMCPerformance,
                polarVMC: currentTackPolarVMC,
                maxTackPolarVMC: maxTackPolarVMC,
                isVMCNegative: currentTackVMC < 0,
                starboardLayline: starboardLayline,
                portsideLayline: portsideLayline,
                extendedStarboardLayline: extendedStarboardLayline,
                extendedPortsideLayline: extendedPortsideLayline,
                starboardIntersection: starboardIntersection,
                portsideIntersection: portsideIntersection
            )
        }
        return waypointData
    }
    
    
    func calculateTackState(
        currentHeading: Double,
        intersection1: (intersection: CLLocationCoordinate2D, distanceBoat: Double, distanceWaypoint: Double),
        intersection2: (intersection: CLLocationCoordinate2D, distanceBoat: Double, distanceWaypoint: Double),
        boatLocation: CLLocationCoordinate2D,
        trueWindDirection: Double,
        sailingState: String, // "Upwind" or "Downwind"
        optimalUpAngle: Double,
        optimalDownAngle: Double,
        twaThreshold: Double
    ) -> (currentTack: String, currentTackDistance: Double, oppositeTack: String, oppositeTackDistance: Double, nextSailingState: String, unclampedAngleToFarIntersection: Double) {
        // Helper: Convert heading to a unit vector
        func headingToVector(heading: Double) -> (x: Double, y: Double) {
            let radians = toRadians(heading)
            return (x: cos(radians), y: sin(radians))
        }
        
        // Helper: Calculate vector from point A to point B
        func vectorFrom(_ pointA: CLLocationCoordinate2D, to pointB: CLLocationCoordinate2D) -> (x: Double, y: Double) {
            let deltaX = pointB.longitude - pointA.longitude
            let deltaY = pointB.latitude - pointA.latitude
            return (x: deltaX, y: deltaY)
        }
        
        // Helper: Calculate the angle between two vectors
        func angleBetween(_ vector1: (x: Double, y: Double), _ vector2: (x: Double, y: Double)) -> Double {
            let cross = vector1.x * vector2.y - vector1.y * vector2.x
            let dot = vector1.x * vector2.x + vector1.y * vector2.y
            return atan2(cross, dot) // Angle in radians
        }
        
        // Boat's heading as a vector
        let boatHeadingVector = vectorFrom(boatLocation, to: CLLocationCoordinate2D(latitude: boatLocation.latitude + 1, longitude: boatLocation.longitude)) // A point directly north of the boat for heading vector
        
        // Calculate vectors to intersections
        let vectorToIntersection1 = vectorFrom(boatLocation, to: intersection1.intersection)
        let vectorToIntersection2 = vectorFrom(boatLocation, to: intersection2.intersection)
        
        // Calculate angles to intersections (clamped for comparison)
        let unclampedAngle1 = normalizeAngleTo180(toDegrees(angleBetween(boatHeadingVector, vectorToIntersection1)))
        let unclampedAngle2 = normalizeAngleTo180(toDegrees(angleBetween(boatHeadingVector, vectorToIntersection2)))
        
        let clampedAngle1 = normalizeAngleTo90(unclampedAngle1)
        let clampedAngle2 = normalizeAngleTo90(unclampedAngle2)
        
        // Debug logs for clamped angles
        //debugLog("Clamped Angle to Intersection 1: \(clampedAngle1)°, Distance: \(intersection1.distanceBoat) NM")
        //debugLog("Clamped Angle to Intersection 2: \(clampedAngle2)°, Distance: \(intersection2.distanceBoat) NM")
        
        // Determine closer intersection (using clamped angles)
        let (currentTack, currentTackDistance, oppositeTack, oppositeTackDistance, unclampedAngleToFarIntersection) = {
            if abs(clampedAngle1) < abs(clampedAngle2) {
                let unclampedAngle = unclampedAngle1
                return ("Current Tack", intersection1.distanceBoat, "Opposite Tack", intersection2.distanceBoat, unclampedAngle)
            } else {
                let unclampedAngle = unclampedAngle2
                return ("Current Tack", intersection2.distanceBoat, "Opposite Tack", intersection1.distanceBoat, unclampedAngle)
            }
        }()
        
        // Determine next sailing state based on the unclamped angle
        let nextSailingState = abs(unclampedAngleToFarIntersection) > twaThreshold ? "Downwind" : "Upwind"
        
        // Debug logs
        //debugLog("Unclamped Angle to Far Intersection: \(unclampedAngleToFarIntersection)°")
        //debugLog("Closest Intersection: \(currentTack)")
        //debugLog("Sailing State: \(sailingState)")
        //debugLog("Next Sailing State: \(nextSailingState)")
        
        return (currentTack, currentTackDistance, oppositeTack, oppositeTackDistance, nextSailingState, unclampedAngleToFarIntersection)
    }
    
    func calculateTrueMarkBearing(from currentLocation: CLLocationCoordinate2D, to waypoint: CLLocationCoordinate2D) -> Double {
        let lat1 = toRadians(currentLocation.latitude)
        let lon1 = toRadians(currentLocation.longitude)
        let lat2 = toRadians(waypoint.latitude)
        let lon2 = toRadians(waypoint.longitude)
        
        let deltaLon = lon2 - lon1
        
        let x = cos(lat2) * sin(deltaLon)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        let initialBearing = atan2(x, y) // Result is in radians
        let trueMarkBearing = toDegrees(initialBearing).truncatingRemainder(dividingBy: 360) // Convert to degrees and normalize
        
        return trueMarkBearing >= 0 ? trueMarkBearing : trueMarkBearing + 360 // Ensure result is in [0, 360)
    }
    private func calculateRelativeMarkBearing(trueMarkBearing: Double, courseOverGround: Double) -> Double {
        let relativeBearing = normalizeAngle(trueMarkBearing - courseOverGround)
        return abs(relativeBearing)
    }
    
    private func calculateVMC(speed: Double, relativeBearing: Double) -> Double {
        return speed * cos(toRadians(relativeBearing))
    }
    
    private func calculateOppositeTack(
        courseOverGround: Double,
        trueWindDirection: Double,
        optimalUpwindTackAngle: Double,
        optimalDownwindTackAngle: Double,
        trueMarkBearing: Double,
        sailingState: String // "Upwind" or "Downwind"
    ) -> (Double, Double) {
        // Normalize the true wind direction
        let normalizedTrueWindDirection = normalizeAngleTo180(trueWindDirection)
        let currentTackOffset = normalizeAngleTo180(courseOverGround - normalizedTrueWindDirection)
        
        // Determine the optimal tack angle based on the sailing state
        let optimalTackAngle = sailingState == "Upwind" ? optimalUpwindTackAngle : optimalDownwindTackAngle
        
        // Calculate the opposite tack angle
        let oppositeTackAngle = currentTackOffset > 0 ? -optimalTackAngle : optimalTackAngle
        
        // Calculate the course over ground (COG) for the opposite tack
        let oppositeCOG = normalizeAngleTo180(trueWindDirection + oppositeTackAngle)
        
        // Calculate the relative mark bearing for the opposite tack
        let oppositeRelativeMarkBearing = normalizeAngleTo180(trueMarkBearing - oppositeCOG)
        
        return (oppositeCOG, oppositeRelativeMarkBearing)
    }
    private func processPerformanceRatio(maxValue: Double, currentValue: Double) -> Double {
        guard maxValue > 0 else { return 0.0 }
        return min((currentValue / maxValue) * 100, 100)
    }
    
    func findIntersection(
        line1Start: CLLocationCoordinate2D,
        line1End: CLLocationCoordinate2D,
        line2Start: CLLocationCoordinate2D,
        line2End: CLLocationCoordinate2D,
        maxDistance: Double
    ) -> CLLocationCoordinate2D? {
        // Convert CLLocationCoordinate2D to MKMapPoint
        let p1 = MKMapPoint(line1Start)
        let p2 = MKMapPoint(line1End)
        let p3 = MKMapPoint(line2Start)
        let p4 = MKMapPoint(line2End)
        
        // Line 1: A1 * x + B1 * y = C1
        let A1 = p2.y - p1.y
        let B1 = p1.x - p2.x
        let C1 = A1 * p1.x + B1 * p1.y
        
        // Line 2: A2 * x + B2 * y = C2
        let A2 = p4.y - p3.y
        let B2 = p3.x - p4.x
        let C2 = A2 * p3.x + B2 * p3.y
        
        // Calculate the determinant
        let determinant = A1 * B2 - A2 * B1
        
        if abs(determinant) < .ulpOfOne {
            // Lines are parallel or coincident
            print("Lines are parallel or coincident.")
            return nil
        }
        
        // Calculate the intersection point in Cartesian coordinates
        let intersectionX = (B2 * C1 - B1 * C2) / determinant
        let intersectionY = (A1 * C2 - A2 * C1) / determinant
        
        // Convert back to CLLocationCoordinate2D
        let intersection = MKMapPoint(x: intersectionX, y: intersectionY).coordinate
        
        //debugLog("Intersection (lat, lon): [\(intersection.latitude), \(intersection.longitude)]")
        
        // Ensure the intersection is within the line segments
        let totalLine1Length = p1.distance(to: p2)
        let totalLine2Length = p3.distance(to: p4)
        let distanceLine1ToIntersection = min(p1.distance(to: MKMapPoint(intersection)), p2.distance(to: MKMapPoint(intersection)))
        let distanceLine2ToIntersection = min(p3.distance(to: MKMapPoint(intersection)), p4.distance(to: MKMapPoint(intersection)))
        
        // Validate intersection is within segment bounds
        if distanceLine1ToIntersection > totalLine1Length || distanceLine2ToIntersection > totalLine2Length {
            print("Intersection is outside the line segments.")
            return nil
        }
        
        // Validate maxDistance constraint
        let distanceFromStart1 = p1.distance(to: MKMapPoint(intersection))
        let distanceFromStart2 = p3.distance(to: MKMapPoint(intersection))
        if distanceFromStart1 > maxDistance || distanceFromStart2 > maxDistance {
            print("Intersection is too far: \(distanceFromStart1), \(distanceFromStart2), max: \(maxDistance)")
            return nil
        }
        
        // Return the intersection coordinate
        return intersection
    }
    
    func generateDiamondLaylines(
        boatLocation: CLLocationCoordinate2D,
        waypoint: CLLocationCoordinate2D,
        windDirection: Double,
        optimalUpTWA: Double,
        optimalDnTWA: Double,
        sailingState: String,
        boatToWaypointDistance: Double // Use calculated distance for dynamic layline length
    ) -> ([Layline], [(intersection: CLLocationCoordinate2D, distanceBoat: Double, distanceWaypoint: Double)]) {
        let normalizedWindDirection = normalizeAngle(windDirection)
        
        // Select tack angles based on the sailing state
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
        
        // Dynamic layline distance based on boat-to-waypoint distance
        let laylineDistance = boatToWaypointDistance * 1.5
        
        // Generate laylines for the boat
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
        
        // Generate laylines for the waypoint
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
        
        // Find intersections within the given layline distances
        // Intersections are named from the boat point of view
        let starboardIntersection = findIntersection(
            line1Start: boatLocation,
            line1End: starboardBoatLayline,
            line2Start: waypoint,
            line2End: portsideWaypointLayline,
            maxDistance: laylineDistance // Limit intersection to dynamic layline length
        )
        
        
        let portsideIntersection = findIntersection(
            line1Start: boatLocation,
            line1End: portsideBoatLayline,
            line2Start: waypoint,
            line2End: starboardWaypointLayline,
            maxDistance: laylineDistance
        )
        
        //debugLog("Intersection #1 coordinates: [\(String(describing: starboardIntersection?.latitude)),\(String(describing: starboardIntersection?.longitude))]")
        //debugLog("Intersection #2 coordinates: [\(String(describing: portsideIntersection?.latitude)),\(String(describing: portsideIntersection?.longitude))]")
        
        // Calculate distances from boat/waypoint to intersection points
        var intersections: [(intersection: CLLocationCoordinate2D, distanceBoat: Double, distanceWaypoint: Double)] = []
        if let starboardIntersection = starboardIntersection {
            let distanceBoat = calculateDistance(from: boatLocation, to: starboardIntersection)
            let distanceWaypoint = calculateDistance(from: waypoint, to: starboardIntersection)
            intersections.append((intersection: starboardIntersection, distanceBoat: distanceBoat, distanceWaypoint: distanceWaypoint))
        }
        if let portsideIntersection = portsideIntersection {
            let distanceBoat = calculateDistance(from: boatLocation, to: portsideIntersection)
            let distanceWaypoint = calculateDistance(from: waypoint, to: portsideIntersection)
            intersections.append((intersection: portsideIntersection, distanceBoat: distanceBoat, distanceWaypoint: distanceWaypoint))
        }
        
        // Return laylines and intersections
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
    
    func calculateLaylineCoordinates(
        start: CLLocationCoordinate2D,
        bearing: Double,
        distance: Double
    ) -> CLLocationCoordinate2D {
        let earthRadius = 6371000.0 // Earth radius in meters
        let angularDistance = distance / earthRadius
        let bearingRad = toRadians(bearing)
        
        let startLatRad = toRadians(start.latitude)
        let startLonRad = toRadians(start.longitude)
        
        let endLat = asin(sin(startLatRad) * cos(angularDistance) +
                          cos(startLatRad) * sin(angularDistance) * cos(bearingRad))
        
        let endLon = startLonRad + atan2(sin(bearingRad) * sin(angularDistance) * cos(startLatRad),
                                         cos(angularDistance) - sin(startLatRad) * sin(endLat))
        
        return CLLocationCoordinate2D(latitude: toDegrees(endLat), longitude: toDegrees(endLon))
    }
    
    private func calculateIntersectionLayline(
        startLocation: CLLocationCoordinate2D,
        targetLocation: CLLocationCoordinate2D,
        bearing: Double
    ) -> CLLocationCoordinate2D {
        let lat1 = toRadians(startLocation.latitude)
        let lon1 = toRadians(startLocation.longitude)
        let targetLat = toRadians(targetLocation.latitude)
        let targetLon = toRadians(targetLocation.longitude)
        let deltaLat = targetLat - lat1
        let deltaLon = targetLon - lon1
        let angularDistance = 2 * atan2(
            sqrt(sin(deltaLat / 2) * sin(deltaLat / 2) +
                 cos(lat1) * cos(targetLat) * sin(deltaLon / 2) * sin(deltaLon / 2)),
            sqrt(1 - sin(deltaLat / 2) * sin(deltaLat / 2) -
                 cos(lat1) * cos(targetLat) * sin(deltaLon / 2) * sin(deltaLon / 2))
        )
        let lat2 = asin(
            sin(lat1) * cos(angularDistance) +
            cos(lat1) * sin(angularDistance) * cos(toRadians(bearing))
        )
        let lon2 = lon1 + atan2(
            sin(toRadians(bearing)) * sin(angularDistance) * cos(lat1),
            cos(angularDistance) - sin(lat1) * sin(lat2)
        )
        return CLLocationCoordinate2D(latitude: toDegrees(lat2), longitude: toDegrees(lon2))
    }
}
