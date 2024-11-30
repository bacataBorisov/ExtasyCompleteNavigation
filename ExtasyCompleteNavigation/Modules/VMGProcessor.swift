import Foundation
import CoreLocation
import Observation

class VMGProcessor: ObservableObject {
    
    @Published var vmgData = VMGData() // Instance to hold VMG-related data
    private var calculateVMG: VMGCalculator? // Instance of VMGCalculator for computations
    
    // MARK: - Initialization
    ///If no other diagram exists and it is loaded it defaults to Extasy polar diagram
    ///TODO: - To be further extended for externally added diagrams

    init(diagramFileName: String = "diagram") {
        if let diagram = DiagramLoader.loadDiagram(from: diagramFileName) {
            self.calculateVMG = VMGCalculator(diagram: diagram)
            print("VMGCalculator initialized with diagram: \(diagramFileName)")
            //print(calculateVMG?.gradus ?? "---")
            //print(calculateVMG?.wind ?? "---")

        } else {
            print("Failed to initialize VMGCalculator. Diagram not loaded.")
        }
    }
    
    // MARK: - Load Diagram
    func loadDiagram(from fileName: String) {
        if let diagram = DiagramLoader.loadDiagram(from: fileName) {
            calculateVMG = VMGCalculator(diagram: diagram)
        } else {
            print("Failed to load diagram from file: \(fileName)")
        }
    }
    
    // Public method to update markerCoordinate
    func updateMarkerCoordinate(to coordinate: CLLocationCoordinate2D) {
        vmgData.markerCoordinate = coordinate
    }
    //public method to reset the data
    func resetVMGCalculations() {
        vmgData.reset()
    }
    
    /// Processes VMG-related calculations based on input data
    func processVMGData(
        gpsData: GPSData?,
        markerCoordinate: CLLocationCoordinate2D?,
        windData: WindData?,
        isVMGSelected: Bool
    ) {
        
        // Ensure VMG calculation is selected and wind data is valid
        guard isVMGSelected else {
            print("VMG calculation is not selected.")
            return
        }
        
        guard let calculateVMG = calculateVMG else {
            print("VMGCalculator is not initialized. Load a diagram file first.")
            return
        }

        // Check required data incrementally, without resetting everything
        if windData?.trueWindForce == nil || windData?.trueWindAngle == nil {
            
            resetVMGCalculations()
            print("Missing or invalid wind data for VMG calculation.")
            return
        }

        if gpsData?.courseOverGround == nil {
            resetVMGCalculations()
            print("Missing or invalid course over ground (COG) data.")
            return
        }
        
        // Proceed with calculations only if all required data is present
        if let trueWindForce = windData?.trueWindForce,
           let trueWindAngle = windData?.trueWindAngle,
           let courseOverGround = gpsData?.courseOverGround {
            // Perform VMG calculations
            let polarSpeed = calculateVMG.evaluateDiagram(windForce: trueWindForce, windAngle: trueWindAngle)
            print("This is the return from the EvalDiagramFUNC: \(polarSpeed)")
            vmgData.polarSpeed = polarSpeed
            vmgData.polarVMG = polarSpeed * cos(toRadians(trueWindAngle))
            
            print("Polar SPEED: \(String(describing: vmgData.polarSpeed)), polar VMG: \(String(describing: vmgData.polarVMG))")
            // Calculate waypoint-related data if a marker is set
            if let markerCoordinate = markerCoordinate,
               let boatLocation = gpsData?.boatLocation {
                
                // Calculate distance to the marker
                let locationA = CLLocation(latitude: boatLocation.latitude, longitude: boatLocation.longitude)
                let locationB = CLLocation(latitude: markerCoordinate.latitude, longitude: markerCoordinate.longitude)
                vmgData.distanceToMark = locationA.distance(from: locationB)
                
                let eta = calculateETA(distance: vmgData.distanceToMark, speed: gpsData?.speedOverGround)
                print("ETA to the WP is: \(String(describing: eta))")
                
                DispatchQueue.main.async {
                    self.vmgData.estTimeOfArrival = eta
                    print("MODIFIED ETA IS: \(String(describing: self.vmgData.estTimeOfArrival))")
                }


                // Calculate true mark bearing
                let (_, trueMarkBearing) = calcOffset(boatLocation, markerCoordinate)
                vmgData.trueMarkBearing = normalizeAngle(trueMarkBearing)
                
                // Calculate relative mark bearing
                let relativeMarkBearing = normalizeAngle(trueMarkBearing - courseOverGround)
                vmgData.relativeMarkBearing = relativeMarkBearing
                
                // Limit the array to the last N values (e.g., 2 values for smoothing)
                if vmgData.relativeMarkBearingArray.count > 2 {
                    vmgData.relativeMarkBearingArray.removeFirst()
                }

                // Smooth relative mark bearing for display
                vmgData.relativeMarkBearingArray.append(relativeMarkBearing)
                if vmgData.relativeMarkBearingArray.count > 1 {
                    let sourceAngle = vmgData.relativeMarkBearingArray[0]
                    let targetAngle = vmgData.relativeMarkBearingArray[1]
                    let smoothedAngle = calculateShortestRotation(from: sourceAngle, to: targetAngle)
                    vmgData.relativeMarkBearing = smoothedAngle
                    vmgData.relativeMarkBearingArray[0] = smoothedAngle
                    vmgData.relativeMarkBearingArray.removeLast()
                    print("Mark Bearing Array count is: \(vmgData.relativeMarkBearingArray.count)")
                }
                
                // Calculate distances to next and long tack
                vmgData.distanceToNextTack = cos(toRadians(relativeMarkBearing)) * (vmgData.distanceToMark ?? 0)
                vmgData.distanceToTheLongTack = cos(toRadians(90 - relativeMarkBearing)) * (vmgData.distanceToMark ?? 0)
                
                vmgData.etaToNextTack = calculateETA(distance: vmgData.distanceToNextTack, speed: gpsData?.speedOverGround)
                print("ETA to next tack is: \(String(describing: vmgData.etaToNextTack))")

            }
        }

        // Update waypoint VMC if course and speed are available
        if let courseOverGround = gpsData?.courseOverGround,
           let speedOverGround = gpsData?.speedOverGround {
            
            let normalizedCOG = normalizeAngle(courseOverGround)
            vmgData.waypointVMC = vmg(speed: speedOverGround, target_angle: vmgData.trueMarkBearing, boat_angle: normalizedCOG)
            print("VMC is: \(String(describing: vmgData.waypointVMC))")
        }
    }
    // Calculate ETA given distance and speed
    private func calculateETA(distance: Double?, speed: Double?) -> Double? {
        guard let distance = distance, let speed = speed, speed > 0 else { return nil }
        return distance / speed // ETA in hours
    }
    // Calculate shortest rotation for smooth animations
    private func calculateShortestRotation(from oldHeading: Double, to newHeading: Double) -> Double {
        let delta = (newHeading - oldHeading).truncatingRemainder(dividingBy: 360)
        return delta > 180 ? delta - 360 : (delta < -180 ? delta + 360 : delta)
    }
    
    // Normalize angle to [0, 360)
    private func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle.truncatingRemainder(dividingBy: 360)
        if normalized < 0 { normalized += 360 }
        return normalized
    }
    
    // Convert degrees to radians
    private func toRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180
    }
    
    // Calculate distance and bearing to a waypoint
    func calcOffset(_ coord0: CLLocationCoordinate2D,
                    _ coord1: CLLocationCoordinate2D) -> (distance: Double, bearing: Double) {
        
        let earthRadius: Double = 6371000 // Earth's radius in meters (mean radius)
        let degToRad: Double = .pi / 180.0
        let radToDeg: Double = 180.0 / .pi
        
        // Convert coordinates to radians
        let lat0 = coord0.latitude * degToRad
        let lat1 = coord1.latitude * degToRad
        let lon0 = coord0.longitude * degToRad
        let lon1 = coord1.longitude * degToRad
        
        // Calculate differences
        let dLat = lat1 - lat0
        let dLon = lon1 - lon0
        
        // Haversine formula for distance
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat0) * cos(lat1) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        let distance = earthRadius * c // Distance in meters
        
        // Formula for initial bearing
        let y = sin(dLon) * cos(lat1)
        let x = cos(lat0) * sin(lat1) - sin(lat0) * cos(lat1) * cos(dLon)
        let initialBearing = atan2(y, x) * radToDeg
        
        // Normalize bearing to [0, 360)
        let normalizedBearing = (initialBearing + 360).truncatingRemainder(dividingBy: 360)
        
        return (distance, normalizedBearing)
    }
}
