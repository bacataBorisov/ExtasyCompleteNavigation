import XCTest
@testable import ExtasyCompleteNavigation

/// Ensures each NMEA formatter is owned by exactly one processor declaration (routing sanity).
final class NMEASentenceProcessorRegistryTests: XCTestCase {

    func testNoDuplicateFormatsAcrossProcessors() {
        let lists: [[String]] = [
            HydroProcessor.supportedNMEASentenceFormats,
            CompassProcessor.supportedNMEASentenceFormats,
            WindProcessor.supportedNMEASentenceFormats,
            GPSProcessor.supportedNMEASentenceFormats
        ]
        var seen = Set<String>()
        for list in lists {
            for fmt in list {
                let upper = fmt.uppercased()
                XCTAssertFalse(seen.contains(upper), "Duplicate NMEA format registered: \(upper)")
                seen.insert(upper)
            }
        }
    }

    func testParserHandledFormatsAreDeclaredBySomeProcessor() {
        let declared = Set<String>([
            HydroProcessor.supportedNMEASentenceFormats,
            CompassProcessor.supportedNMEASentenceFormats,
            WindProcessor.supportedNMEASentenceFormats,
            GPSProcessor.supportedNMEASentenceFormats
        ].joined().map { $0.uppercased() })

        let handledByParser = Set([
            "DPT", "HDG", "MTW", "MWV", "VHW", "VLW",
            "GLL", "GGA", "GSA", "GSV", "RMC"
        ])

        for fmt in handledByParser {
            XCTAssertTrue(declared.contains(fmt), "Parser handles \(fmt) but no processor lists it in NMEASentenceProcessor")
        }
    }
}
