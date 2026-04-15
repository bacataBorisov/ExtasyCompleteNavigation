import XCTest
@testable import ExtasyCompleteNavigation

final class HydroProcessorTests: XCTestCase {

    func testProcessDepthValidSentence() {
        let p = HydroProcessor()
        // $IIXXX,DPT,depth,offset*checksum style split: talker+sentence, then fields
        let split = ["II", "DPT", "12.4", "0.0"]
        let out = p.processDepth(split)
        XCTAssertNotNil(out)
        XCTAssertEqual(out!.rawDepth ?? -1, 12.4, accuracy: 0.001)
    }

    func testProcessDepthInvalidReturnsNil() {
        let p = HydroProcessor()
        XCTAssertNil(p.processDepth(["II", "DPT", "x", "0.0"]))
    }

    func testProcessSpeedLogParsesWaterSpeedField() {
        let p = HydroProcessor()
        // Matches `UtilsNMEA.splitNMEAString`: [talker2, format, ...fields] — index 6 = water speed (knots).
        let split = ["II", "VHW", "0", "T", "0", "M", "6.12", "N", "11.33", "K"]
        let out = p.processSpeedLog(split)
        XCTAssertNotNil(out)
        XCTAssertEqual(out!.rawBoatSpeedLag ?? -1, 6.12, accuracy: 0.01)
    }
}
