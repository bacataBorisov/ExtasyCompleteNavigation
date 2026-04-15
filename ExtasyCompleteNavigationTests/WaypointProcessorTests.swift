import XCTest
import CoreLocation
@testable import ExtasyCompleteNavigation

final class WaypointProcessorTests: XCTestCase {
    private var processor: WaypointProcessor!
    
    override func setUp() {
        super.setUp()
        processor = WaypointProcessor()
    }
    
    func testCalculateTrueMarkBearingDueSouth() {
        let start = CLLocationCoordinate2D(latitude: 1.0, longitude: 0.0)
        let mark = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        
        XCTAssertEqual(processor.calculateTrueMarkBearing(from: start, to: mark), 180.0, accuracy: 0.01)
    }
    
    func testCalculateTrueMarkBearingAcrossDateLineEastbound() {
        let start = CLLocationCoordinate2D(latitude: 0.0, longitude: 179.0)
        let mark = CLLocationCoordinate2D(latitude: 0.0, longitude: -179.0)
        
        XCTAssertEqual(processor.calculateTrueMarkBearing(from: start, to: mark), 90.0, accuracy: 0.5)
    }
    
    func testFindIntersectionReturnsNilForParallelLines() {
        let line1Start = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let line1End = CLLocationCoordinate2D(latitude: 0.0, longitude: 1.0)
        let line2Start = CLLocationCoordinate2D(latitude: 1.0, longitude: 0.0)
        let line2End = CLLocationCoordinate2D(latitude: 1.0, longitude: 1.0)
        
        let intersection = processor.findIntersection(
            line1Start: line1Start,
            line1End: line1End,
            line2Start: line2Start,
            line2End: line2End,
            maxDistance: 500_000
        )
        
        XCTAssertNil(intersection)
    }
    
    func testFindIntersectionReturnsExpectedCrossing() {
        let line1Start = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let line1End = CLLocationCoordinate2D(latitude: 1.0, longitude: 1.0)
        let line2Start = CLLocationCoordinate2D(latitude: 0.0, longitude: 1.0)
        let line2End = CLLocationCoordinate2D(latitude: 1.0, longitude: 0.0)
        
        let intersection = processor.findIntersection(
            line1Start: line1Start,
            line1End: line1End,
            line2Start: line2Start,
            line2End: line2End,
            maxDistance: 500_000
        )
        
        XCTAssertNotNil(intersection)
        XCTAssertEqual(intersection?.latitude ?? 0.0, 0.5, accuracy: 0.02)
        XCTAssertEqual(intersection?.longitude ?? 0.0, 0.5, accuracy: 0.02)
    }
    
    func testCalculateLaylineCoordinatesWrapsBearingOver360() {
        let start = CLLocationCoordinate2D(latitude: 43.0, longitude: 28.0)
        let over360 = processor.calculateLaylineCoordinates(start: start, bearing: 405.0, distance: 1_000)
        let normalized = processor.calculateLaylineCoordinates(start: start, bearing: 45.0, distance: 1_000)
        
        XCTAssertEqual(over360.latitude, normalized.latitude, accuracy: 1e-8)
        XCTAssertEqual(over360.longitude, normalized.longitude, accuracy: 1e-8)
    }
    
    func testGenerateDiamondLaylinesReturnsFourLaylines() {
        let boat = CLLocationCoordinate2D(latitude: 43.0, longitude: 28.0)
        let mark = CLLocationCoordinate2D(latitude: 43.01, longitude: 28.01)
        
        let result = processor.generateDiamondLaylines(
            boatLocation: boat,
            waypoint: mark,
            windDirection: 45.0,
            optimalUpTWA: 40.0,
            optimalDnTWA: 150.0,
            sailingState: "Upwind",
            boatToWaypointDistance: calculateDistance(from: boat, to: mark)
        )
        
        XCTAssertEqual(result.0.count, 4)
    }
    
    func testGenerateDiamondLaylinesReturnsStableIntersectionCountForSymmetricCase() {
        let boat = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let mark = CLLocationCoordinate2D(latitude: 0.01, longitude: 0.0)
        
        let result = processor.generateDiamondLaylines(
            boatLocation: boat,
            waypoint: mark,
            windDirection: 0.0,
            optimalUpTWA: 45.0,
            optimalDnTWA: 135.0,
            sailingState: "Upwind",
            boatToWaypointDistance: calculateDistance(from: boat, to: mark)
        )
        
        XCTAssertEqual(result.1.count, 2, "Symmetric upwind geometry should produce two intersections.")
    }
    
    func testCalculateTackStateChoosesIntersectionClosestToCurrentHeading() {
        let boat = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let ahead = (
            intersection: CLLocationCoordinate2D(latitude: 1.0, longitude: 0.0),
            distanceBoat: 10.0,
            distanceWaypoint: 20.0
        )
        let starboard = (
            intersection: CLLocationCoordinate2D(latitude: 0.0, longitude: 1.0),
            distanceBoat: 30.0,
            distanceWaypoint: 40.0
        )
        
        let result = processor.calculateTackState(
            currentHeading: 0.0,
            intersection1: ahead,
            intersection2: starboard,
            boatLocation: boat,
            trueWindDirection: 45.0,
            sailingState: "Upwind",
            optimalUpAngle: 40.0,
            optimalDownAngle: 150.0,
            twaThreshold: 90.0
        )
        
        XCTAssertEqual(result.currentTackDistance, 10.0, accuracy: 1e-9)
        XCTAssertEqual(result.nextLegDistance, 20.0, accuracy: 1e-9)
        XCTAssertEqual(result.nextLegIntersection.latitude, ahead.intersection.latitude, accuracy: 1e-9)
        XCTAssertEqual(result.nextLegIntersection.longitude, ahead.intersection.longitude, accuracy: 1e-9)
    }
    
    func testCalculateTackStateRemainsStableAcrossHeadingWrap() {
        let boat = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let nearNorthWest = (
            intersection: CLLocationCoordinate2D(latitude: 1.0, longitude: -0.1),
            distanceBoat: 12.0,
            distanceWaypoint: 18.0
        )
        let east = (
            intersection: CLLocationCoordinate2D(latitude: 0.0, longitude: 1.0),
            distanceBoat: 25.0,
            distanceWaypoint: 30.0
        )
        
        let result359 = processor.calculateTackState(
            currentHeading: 359.0,
            intersection1: nearNorthWest,
            intersection2: east,
            boatLocation: boat,
            trueWindDirection: 0.0,
            sailingState: "Upwind",
            optimalUpAngle: 40.0,
            optimalDownAngle: 150.0,
            twaThreshold: 90.0
        )
        
        let result1 = processor.calculateTackState(
            currentHeading: 1.0,
            intersection1: nearNorthWest,
            intersection2: east,
            boatLocation: boat,
            trueWindDirection: 0.0,
            sailingState: "Upwind",
            optimalUpAngle: 40.0,
            optimalDownAngle: 150.0,
            twaThreshold: 90.0
        )
        
        XCTAssertEqual(result359.currentTackDistance, result1.currentTackDistance, accuracy: 1e-9)
        XCTAssertEqual(result359.nextLegDistance, result1.nextLegDistance, accuracy: 1e-9)
    }
    
    func testCalculateTackStateTieFallsBackDeterministicallyToSecondIntersection() {
        let boat = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let left = (
            intersection: CLLocationCoordinate2D(latitude: 1.0, longitude: -1.0),
            distanceBoat: 11.0,
            distanceWaypoint: 21.0
        )
        let right = (
            intersection: CLLocationCoordinate2D(latitude: 1.0, longitude: 1.0),
            distanceBoat: 22.0,
            distanceWaypoint: 32.0
        )
        
        let result = processor.calculateTackState(
            currentHeading: 0.0,
            intersection1: left,
            intersection2: right,
            boatLocation: boat,
            trueWindDirection: 0.0,
            sailingState: "Upwind",
            optimalUpAngle: 40.0,
            optimalDownAngle: 150.0,
            twaThreshold: 90.0
        )
        
        XCTAssertEqual(result.currentTackDistance, 22.0, accuracy: 1e-9)
        XCTAssertEqual(result.nextLegDistance, 32.0, accuracy: 1e-9)
        XCTAssertEqual(result.nextLegIntersection.latitude, right.intersection.latitude, accuracy: 1e-9)
        XCTAssertEqual(result.nextLegIntersection.longitude, right.intersection.longitude, accuracy: 1e-9)
    }
    
    func testCalculateTackStateHandlesNegativeHeadingEquivalentToPositive() {
        let boat = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let north = (
            intersection: CLLocationCoordinate2D(latitude: 1.0, longitude: 0.1),
            distanceBoat: 14.0,
            distanceWaypoint: 19.0
        )
        let south = (
            intersection: CLLocationCoordinate2D(latitude: -1.0, longitude: 0.0),
            distanceBoat: 50.0,
            distanceWaypoint: 60.0
        )
        
        let resultNegative = processor.calculateTackState(
            currentHeading: -1.0,
            intersection1: north,
            intersection2: south,
            boatLocation: boat,
            trueWindDirection: 0.0,
            sailingState: "Upwind",
            optimalUpAngle: 40.0,
            optimalDownAngle: 150.0,
            twaThreshold: 90.0
        )
        
        let resultPositive = processor.calculateTackState(
            currentHeading: 359.0,
            intersection1: north,
            intersection2: south,
            boatLocation: boat,
            trueWindDirection: 0.0,
            sailingState: "Upwind",
            optimalUpAngle: 40.0,
            optimalDownAngle: 150.0,
            twaThreshold: 90.0
        )
        
        XCTAssertEqual(resultNegative.currentTackDistance, resultPositive.currentTackDistance, accuracy: 1e-9)
        XCTAssertEqual(resultNegative.nextLegDistance, resultPositive.nextLegDistance, accuracy: 1e-9)
    }
}
