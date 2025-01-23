import Foundation
import CoreLocation
import Observation

class VMGProcessor {
    
    // Reference to shared VMGData
    var vmgData = VMGData()
    
    // Initialize with VMGData from NMEAParser
    private var calculateVMG: VMGCalculator? // Instance of VMGCalculator for computations
    private var tackTableLoaded: Bool = false

    
    // MARK: - Initialization
    ///If no other diagram exists and it is loaded it defaults to Extasy polar diagram
    ///TODO: - To be further extended for externally added diagrams
    
    init(diagramFileName: String = "diagram", tackTableFileName: String = "optimal_tack") {
        if let diagram = DiagramLoader.loadDiagram(from: diagramFileName) {
            self.calculateVMG = VMGCalculator(diagram: diagram)
            debugLog("VMGCalculator initialized with diagram: \(diagramFileName)")
        } else {
            debugLog("Failed to initialize VMGCalculator. Diagram not loaded.")
        }

        // Load the tack table
        if let calculateVMG = calculateVMG {
            calculateVMG.readOptimalTackTable(fileName: tackTableFileName)
            tackTableLoaded = !calculateVMG.optimalTackTable.isEmpty
            debugLog("Tack table loaded: \(tackTableLoaded)")
        } else {
            debugLog("Failed to load tack table. VMGCalculator not initialized.")
        }
    }
    
    // MARK: - Load Diagram
    func loadDiagram(from fileName: String) {
        if let diagram = DiagramLoader.loadDiagram(from: fileName) {
            calculateVMG = VMGCalculator(diagram: diagram)
        } else {
            debugLog("Failed to load diagram from file: \(fileName)")
        }
    }
    
    
    //public method to reset the data
    func resetVMGCalculations() {
        vmgData.reset()
        debugLog("VMG data has been reset")
        
    }
    
    func processPerformanceRatio(maxValue: Double, currentValue: Double) -> Double {
        
        guard maxValue > 0 else { return 0.0 }
        return min((currentValue / maxValue) * 100, 100) // Limit to 100%
    }
    
    func processTackData(windSpeed: Double, trueWindAngle: Double) -> (optUpTWA: Double, optDnTWA: Double, maxUpVMG: Double, maxDnVMG: Double, sailingState: String, sailingStateLimit: Double)? {
        guard tackTableLoaded, let calculateVMG = calculateVMG else {
            debugLog("Tack table not loaded or VMGCalculator not available.")
            return nil
        }

        // Call the interpolate function
        let result = calculateVMG.interpolateTackTableUsingSpline(for: windSpeed, trueWindAngle: trueWindAngle)
        
        // Safely unwrap the components of the returned tuple
        guard let interpolatedRow = result.interpolatedRow,
              let sailingState = result.sailingState,
              let sailingStateLimit = result.sailingStateLimit else {
            debugLog("Failed to process interpolated row or determine sailing state for wind speed: \(windSpeed)")
            return nil
        }

        // Return the processed tack data along with the sailing state
        return (
            optUpTWA: interpolatedRow[1],
            optDnTWA: interpolatedRow[2],
            maxUpVMG: interpolatedRow[5],
            maxDnVMG: interpolatedRow[6],
            sailingState: sailingState,
            sailingStateLimit: sailingStateLimit
        )
    }
    
    /// Processes VMG-related calculations based on input data
    func processVMGData(
        gpsData: GPSData?,
        hydroData: HydroData?,
        windData: WindData?
    ) -> VMGData? {
        
        // Check if data is valid using the helper function and unwrap values
        guard let boatLocation = gpsData?.boatLocation,
              let trueWindForce = windData?.trueWindForce,
              let trueWindAngle = windData?.trueWindAngle,
              let trueWindDirection = windData?.trueWindDirection,
              let speedOverGround = gpsData?.speedOverGround,
              let speedThroughWater = hydroData?.boatSpeedLag,
              let calculateVMG = calculateVMG else {
            return nil
        }
                
        //MARK: -  Perform VMG Calculations Once Data is Valid
        
        let polarSpeed = calculateVMG.evaluateDiagram(windForce: trueWindForce, windAngle: trueWindAngle)
        //take absolute value for display purposes in the progress bars and drop the negative nature of the cosine
        let polarVMG = abs((polarSpeed) * cos(toRadians(trueWindAngle)))

        // Calculate VMG using SOG (VMG over ground)
        let angleToWind = abs(normalizeAngle(trueWindAngle)) // Angle between wind and course
        
        // Speed Performance Calculations
        let speedPerformanceThroughWater = processPerformanceRatio(maxValue: polarSpeed, currentValue: speedThroughWater)
        let speedPerformanceOverGround = processPerformanceRatio(maxValue: polarSpeed, currentValue: speedOverGround)
        
        // VMG Performance Calculations
        let vmgOverGround = abs(speedOverGround * cos(toRadians(angleToWind)))
        let vmgOverGroundPerformance = processPerformanceRatio(maxValue: polarVMG, currentValue: vmgOverGround)
        
        let vmgThroughWater = abs(speedThroughWater * cos(toRadians(angleToWind)))
        let vmgThroughWaterPerformance = processPerformanceRatio(maxValue: polarVMG, currentValue: vmgThroughWater)
        
        // Fetch tack data
        let tackData = processTackData(windSpeed: trueWindForce, trueWindAngle: trueWindAngle)
        let optimalUpTWA = tackData?.optUpTWA ?? 0.0
        let optimalDnTWA = tackData?.optDnTWA ?? 0.0
        let maxUpVMG = tackData?.maxUpVMG ?? 0.0
        let maxDnVMG = tackData?.maxDnVMG ?? 0.0
    
        // Sailing State Determination
        let sailingState = tackData?.sailingState ?? "Unknown"
        //debugLog("Current sailing state is: [\(sailingState)]")
        
        // Sailing State Limit (threshold)
        let sailingStateLimit = tackData?.sailingStateLimit
        
        
        // Laylines calculation
        let laylines = generateLaylines(
            boatLocation: boatLocation,
            windDirection: trueWindDirection,
            optimalUpTWA: optimalUpTWA,
            optimalDnTWA: optimalDnTWA,
            sailingState: sailingState
        )
                
        // Update VMGData
        
        vmgData = VMGData(
            polarSpeed: polarSpeed,
            polarVMG: polarVMG,
            vmgOverGround: vmgOverGround,
            vmgOverGroundPerformance: vmgOverGroundPerformance,
            vmgThroughWater: vmgThroughWater,
            vmgThroughWaterPerformance: vmgThroughWaterPerformance,
            speedPerformanceThroughWater: speedPerformanceThroughWater,
            speedPerformanceOverGround: speedPerformanceOverGround,
            optimalUpTWA: optimalUpTWA,
            optimalDnTWA: optimalDnTWA,
            maxUpVMG: maxUpVMG,
            maxDnVMG: maxDnVMG,
            sailingState: sailingState,
            sailingStateLimit: sailingStateLimit,
            starboardLayline: laylines.starboardLayline,
            portsideLayline: laylines.portsideLayline
        )

        return vmgData
        
    }
    
    func calculateLaylineCoordinates(
        boatLocation: CLLocationCoordinate2D,
        windDirection: Double,
        tackAngle: Double,
        distance: Double = 20000 // Distance in meters for layline projection
    ) -> CLLocationCoordinate2D {
        let earthRadius: Double = 6371000 // Earth's radius in meters
        let laylineDirection = normalizeAngle(windDirection + tackAngle) // Adjust wind direction by tack angle
        let laylineDirectionRad = toRadians(laylineDirection)

        let lat1 = toRadians(boatLocation.latitude)
        let lon1 = toRadians(boatLocation.longitude)

        let lat2 = asin(sin(lat1) * cos(distance / earthRadius) +
                        cos(lat1) * sin(distance / earthRadius) * cos(laylineDirectionRad))
        let lon2 = lon1 + atan2(sin(laylineDirectionRad) * sin(distance / earthRadius) * cos(lat1),
                                cos(distance / earthRadius) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(latitude: toDegrees(lat2), longitude: toDegrees(lon2))
    }

    func generateLaylines(
        boatLocation: CLLocationCoordinate2D,
        windDirection: Double,
        optimalUpTWA: Double,
        optimalDnTWA: Double,
        sailingState: String
    ) -> (starboardLayline: CLLocationCoordinate2D, portsideLayline: CLLocationCoordinate2D) {
        // Normalize the wind direction to 0-360
        let normalizedWindDirection = normalizeAngle(windDirection)
        
        switch sailingState {
        case "Upwind":
            return (
                starboardLayline: calculateLaylineCoordinates(
                    boatLocation: boatLocation,
                    windDirection: normalizedWindDirection,
                    tackAngle: optimalUpTWA
                ),
                portsideLayline: calculateLaylineCoordinates(
                    boatLocation: boatLocation,
                    windDirection: normalizedWindDirection,
                    tackAngle: -optimalUpTWA
                )
            )
        case "Downwind":
            return (
                starboardLayline: calculateLaylineCoordinates(
                    boatLocation: boatLocation,
                    windDirection: normalizedWindDirection,
                    tackAngle: optimalDnTWA
                ),
                portsideLayline: calculateLaylineCoordinates(
                    boatLocation: boatLocation,
                    windDirection: normalizedWindDirection,
                    tackAngle: -optimalDnTWA
                )
            )
        default: // Handle transition or undefined states
            debugLog("Sailing state is in transition or undefined.")
            return (starboardLayline: boatLocation, portsideLayline: boatLocation)
        }
    }
}
