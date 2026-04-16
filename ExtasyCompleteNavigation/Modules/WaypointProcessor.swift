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

    /// Low-pass **true wind direction** used **only** for diamond layline geometry (chart stability).
    /// Live `WindData.trueWindDirection` stays unmodified for instruments, VMC, and `waypointApproachState`.
    private var laylineWindDirectionSmoothed: Double?
    private var laylineOptimalUpSmoothed: Double?
    private var laylineOptimalDnSmoothed: Double?

    /// TWD blend for chart laylines only (slower ≈ Garmin-style **layline filter** — real shifts still converge).
    private static let laylineWindDirectionBlend = 0.045
    /// Polar optimal up/down **TWA** blend for layline rays only (damps TWS table jitter).
    private static let laylineTackAngleBlend = 0.10

    // Flags for logging control
    private var hasLoggedWaypointSkipped = false
    private var hasLoggedWaypointInitialized = false
    
    /// Total trip time in **hours** for waypoint TRIP/ETA.
    ///
    /// When both tactical legs exist, uses **leg1 + leg2 at SOG** (same model as `tackDuration` /
    /// `tripDurationOnOppositeTack`). Otherwise uses rhumb-line **DTM / SOG**. Avoids
    /// `DTM / VMC`, which blows up when VMC is small but the boat is still moving at SOG.
    static func tripDurationToWaypointHours(
        distanceToMarkMeters: Double,
        effectiveSOGKnots: Double,
        leg1Hours: Double?,
        leg2Hours: Double?
    ) -> Double? {
        guard effectiveSOGKnots > 0 else { return nil }
        if let a = leg1Hours, let b = leg2Hours, a.isFinite, b.isFinite, a >= 0, b >= 0 {
            return a + b
        }
        guard distanceToMarkMeters > 0 else { return nil }
        return distanceToMarkMeters * toNauticalMiles / effectiveSOGKnots
    }

    // MARK: - Reset Waypoint Data
    func resetWaypointCalculations() {
        laylineWindDirectionSmoothed = nil
        laylineOptimalUpSmoothed = nil
        laylineOptimalDnSmoothed = nil
        waypointData.reset()
        debugLog("Waypoint data has been reset.")
    }

    private func laylineSmoothedWindDirection(measured: Double) -> Double {
        if let prev = laylineWindDirectionSmoothed {
            let delta = normalizeAngleTo180(measured - prev)
            laylineWindDirectionSmoothed = normalizeAngle(prev + Self.laylineWindDirectionBlend * delta)
        } else {
            laylineWindDirectionSmoothed = normalizeAngle(measured)
        }
        return laylineWindDirectionSmoothed!
    }

    private func laylineSmoothedTackAngles(up measuredUp: Double, down measuredDn: Double) -> (up: Double, down: Double) {
        if let prevU = laylineOptimalUpSmoothed, let prevD = laylineOptimalDnSmoothed {
            laylineOptimalUpSmoothed = prevU + (measuredUp - prevU) * Self.laylineTackAngleBlend
            laylineOptimalDnSmoothed = prevD + (measuredDn - prevD) * Self.laylineTackAngleBlend
        } else {
            laylineOptimalUpSmoothed = measuredUp
            laylineOptimalDnSmoothed = measuredDn
        }
        return (laylineOptimalUpSmoothed!, laylineOptimalDnSmoothed!)
    }
    
    // MARK: - Process Waypoint Data
    func processWaypointData(
        vmgData: VMGData?,
        gpsData: GPSData?,
        windData: WindData?
    ) -> WaypointData? {
        serialQueue.sync { [self] () -> Void in
            guard let polarSpeed = vmgData?.polarSpeed,
                  let markerCoordinate = gpsData?.waypointLocation,
                  let boatLocation = gpsData?.boatLocation,
                  let courseOverGround = gpsData?.courseOverGround,
                  let speedOverGround = gpsData?.speedOverGround,
                  let trueWindDirection = windData?.trueWindDirection,
                  let optimalUpTWA = vmgData?.optimalUpTWA,
                  let optimalDnTWA = vmgData?.optimalDnTWA,
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

            // Sailing state for the WAYPOINT approach: bearing to mark vs **live** TWD — for
            // labels, VMC, tack hints (`waypointApproachState`); not coupled to heading alone.
            let angleToMark = abs(normalizeAngleTo180(trueMarkBearing - trueWindDirection))
            let waypointSailingState = angleToMark <= sailingStateLimit ? "Upwind" : "Downwind"

            // Layline geometry: **smoothed** TWD + **mark-only** up/down vs that wind.
            // Live TWD can jitter when NMEA HDG/TWA updates shift derived direction during course
            // changes; using polar `sailingState` for laylines swapped optimal up/down angles
            // whenever TWA crossed the polar threshold. Diamond laylines instead follow a
            // low-pass wind (Garmin-style “layline filter”) and the same mark-vs-wind rule
            // used for approach state — chart lines move mainly with real shifts and boat–mark
            // geometry, not every heading wobble.
            let windForLaylines = laylineSmoothedWindDirection(measured: trueWindDirection)
            let angleToMarkLay = abs(normalizeAngleTo180(trueMarkBearing - windForLaylines))
            let laylineSailingState = angleToMarkLay <= sailingStateLimit ? "Upwind" : "Downwind"
            let tackAnglesForLaylines = laylineSmoothedTackAngles(up: optimalUpTWA, down: optimalDnTWA)

            // MARK: - Opposite Tack Calculations
            
            let (_, oppositeRelativeMarkBearing) = calculateOppositeTack(
                courseOverGround: courseOverGround,
                trueWindDirection: trueWindDirection,
                optimalUpwindTackAngle: optimalUpTWA,
                optimalDownwindTackAngle: optimalDnTWA,
                trueMarkBearing: trueMarkBearing,
                sailingState: waypointSailingState)
            
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
            let effectiveSOG = max(speedOverGround, 0) // Ensure positive SOG
            
            // MARK: - Laylines
            
            // Generate laylines and intersections
            let (laylines, intersections) = generateDiamondLaylines(
                boatLocation: boatLocation,
                waypoint: markerCoordinate,
                windDirection: windForLaylines,
                optimalUpTWA: tackAnglesForLaylines.up,
                optimalDnTWA: tackAnglesForLaylines.down,
                sailingState: laylineSailingState,
                boatToWaypointDistance: distanceToMark
            )
            
            // Assign laylines
            let starboardLayline = laylines[0]
            let portsideLayline = laylines[1]
            let extendedStarboardLayline = laylines[2]
            let extendedPortsideLayline = laylines[3]
            
            // Validate intersections before calculating tack states.
            // Even when intersections can't be found the laylines themselves are valid and
            // must always be saved so the map never goes blank.
            guard intersections.count >= 2 else {
                debugLog("Not enough intersections (\(intersections.count)) — saving laylines without tack distances.")
                self.starboardIntersection = nil
                self.portsideIntersection = nil
                let tripNoLegs = Self.tripDurationToWaypointHours(
                    distanceToMarkMeters: distanceToMark,
                    effectiveSOGKnots: effectiveSOG,
                    leg1Hours: nil,
                    leg2Hours: nil
                )
                let etaNoLegs = tripNoLegs.map { Date().addingTimeInterval($0 * 3600) }
                self.waypointData = WaypointData(
                    distanceToMark: distanceToMark,
                    trueMarkBearing: trueMarkBearing,
                    tripDurationToWaypoint: tripNoLegs,
                    etaToWaypoint: etaNoLegs,
                    currentTackRelativeBearing: relativeMarkBearing,
                    waypointApproachState: waypointSailingState,
                    currentTackVMC: currentTackVMC,
                    currentTackVMCDisplay: currentTackVMCDisplay,
                    currentTackVMCPerformance: currentTackVMCPerformance,
                    oppositeTackVMC: oppositeTackVMC,
                    oppositeTackVMCDisplay: oppositeTackVMCDisplay,
                    oppositeTackVMCPerformance: oppositeTackVMCPerformance,
                    polarVMC: currentTackPolarVMC,
                    maxTackPolarVMC: maxTackPolarVMC,
                    isVMCNegative: currentTackVMC < 0,
                    starboardLayline: starboardLayline,
                    portsideLayline: portsideLayline,
                    extendedStarboardLayline: extendedStarboardLayline,
                    extendedPortsideLayline: extendedPortsideLayline,
                    starboardIntersection: nil,
                    portsideIntersection: nil
                )
                return
            }
            
            // Calculate tack states
            let tackStates = calculateTackState(
                currentHeading: courseOverGround,
                intersection1: intersections[0],
                intersection2: intersections[1],
                boatLocation: boatLocation,
                trueWindDirection: trueWindDirection,
                sailingState: waypointSailingState,
                optimalUpAngle: optimalUpTWA,
                optimalDownAngle: optimalDnTWA,
                twaThreshold: sailingStateLimit
            )
            
            // Leg 1: boat → tack intersection
            let currentTackState = tackStates.currentTack
            let currentTackDistance = tackStates.currentTackDistance * toNauticalMiles
            let currentTackDuration = (effectiveSOG > 0) ? (currentTackDistance / effectiveSOG) : 0.0

            // Leg 2: tack intersection → mark
            // Use distanceWaypoint of the closer intersection (not distanceBoat of the far one).
            let oppositeTackDistance = tackStates.nextLegDistance * toNauticalMiles
            let oppositeTackDuration = (effectiveSOG > 0) ? (oppositeTackDistance / effectiveSOG) : 0.0

            // TRIP / ETA must match the **tactical leg model** (SOG along boat→tack→mark), not
            // `DTM / currentTackVMC` — tiny VMC inflates time to hundreds of hours while the
            // leg rows still show a ~10 h sum (see `tackDuration` + `tripDurationOnOppositeTack`).
            let tripDurationToWaypoint = Self.tripDurationToWaypointHours(
                distanceToMarkMeters: distanceToMark,
                effectiveSOGKnots: effectiveSOG,
                leg1Hours: currentTackDuration,
                leg2Hours: oppositeTackDuration
            )
            let etaToWaypoint = tripDurationToWaypoint.map { Date().addingTimeInterval($0 * 3600) }

            // Sailing state for leg 2 is determined from the INTERSECTION's perspective,
            // not from the boat's current position. The bearing from the intersection to
            // the mark vs TWD may differ significantly from the boat's current AoM.
            let intersectionToMarkBearing = calculateTrueMarkBearing(
                from: tackStates.nextLegIntersection,
                to: markerCoordinate
            )
            let intersectionAoM = abs(normalizeAngleTo180(intersectionToMarkBearing - trueWindDirection))
            let nextLegSailingState = intersectionAoM <= sailingStateLimit ? "Upwind" : "Downwind"
            let oppositeTackState = nextLegSailingState

            // Determine which tack/gybe the boat is on for the second leg.
            // TWA of the second leg = (TWD − heading_toward_mark) mod 360°.
            // > 180° means wind arrives from the port side → PORT tack/gybe.
            let secondLegTWA = normalizeAngle(trueWindDirection - intersectionToMarkBearing)
            let nextLegTack = secondLegTWA > 180.0 ? "Port" : "Starboard"
            
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
                waypointApproachState: waypointSailingState,
                nextLegSailingState: nextLegSailingState,
                nextLegTack: nextLegTack,
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
    ) -> (currentTack: String,
          currentTackDistance: Double,
          nextLegDistance: Double,
          nextLegIntersection: CLLocationCoordinate2D,
          oppositeTack: String,
          oppositeTackDistance: Double,
          nextSailingState: String,
          unclampedAngleToFarIntersection: Double) {
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
        
        // Boat's heading as a unit vector in (deltaLon, deltaLat) space (north-up, east-right)
        let headingRad = toRadians(currentHeading)
        let boatHeadingVector = (x: sin(headingRad), y: cos(headingRad))
        
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
        
        // Determine the closer intersection (= the tack point the boat will reach first).
        // Also capture its distanceWaypoint (leg-2 length: intersection → mark) and its
        // coordinate so the caller can compute the second-leg sailing state from there.
        let (currentTack,
             currentTackDistance,
             nextLegDistance,
             nextLegIntersection,
             oppositeTack,
             oppositeTackDistance,
             unclampedAngleToFarIntersection) = {
            if abs(clampedAngle1) < abs(clampedAngle2) {
                return ("Current Tack",
                        intersection1.distanceBoat,
                        intersection1.distanceWaypoint,  // leg 2: closer intersection → mark
                        intersection1.intersection,
                        "Opposite Tack",
                        intersection2.distanceBoat,
                        unclampedAngle1)
            } else {
                return ("Current Tack",
                        intersection2.distanceBoat,
                        intersection2.distanceWaypoint,  // leg 2: closer intersection → mark
                        intersection2.intersection,
                        "Opposite Tack",
                        intersection1.distanceBoat,
                        unclampedAngle2)
            }
        }()

        return (currentTack,
                currentTackDistance,
                nextLegDistance,
                nextLegIntersection,
                oppositeTack,
                oppositeTackDistance,
                sailingState,
                unclampedAngleToFarIntersection)
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
            Log.navigation.debug("Lines are parallel or coincident.")
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
            Log.navigation.debug("Intersection is outside the line segments.")
            return nil
        }
        
        // Validate maxDistance constraint
        let distanceFromStart1 = p1.distance(to: MKMapPoint(intersection))
        let distanceFromStart2 = p3.distance(to: MKMapPoint(intersection))
        if distanceFromStart1 > maxDistance || distanceFromStart2 > maxDistance {
            Log.navigation.debug("Intersection is too far: \(distanceFromStart1), \(distanceFromStart2), max: \(maxDistance)")
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
        
        // Laylines must extend far enough that their intersections always fall within the segments,
        // even when the boat is well past or alongside the laylines. 4× the current distance with
        // a 200 km floor (~108 NM) covers all practical sailing scenarios.
        let laylineDistance = max(boatToWaypointDistance * 4.0, 200_000.0)
        
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
