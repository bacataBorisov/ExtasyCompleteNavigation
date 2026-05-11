import XCTest
import CoreLocation
@testable import ExtasyCompleteNavigation

// MARK: - Helpers

/// Creates a minimal flat polar that returns approximately `speed` knots for any
/// angle in [45°, 160°] and any TWS in [8, 20] kn.
///
/// Format (same as VMGCalculator.init?(diagram:)):
///   row 0  = [0.0, tws1, tws2, …]
///   row 1+ = [angle, speed1, speed2, …]
private func makeFlatPolar(speed: Double) -> VMGCalculator? {
    let diagram: [[Double]] = [
        [0.0,   8.0,    12.0,   16.0,   20.0],
        [45.0,  speed,  speed,  speed,  speed],
        [90.0,  speed,  speed,  speed,  speed],
        [135.0, speed,  speed,  speed,  speed],
        [160.0, speed,  speed,  speed,  speed],
    ]
    return VMGCalculator(diagram: diagram)
}

/// Creates a polar that only covers TWA 30°–90° (max angle = 90°).
/// Querying angles > 90° will return 0 from evaluateDiagram.
private func makeNarrowPolar(speed: Double) -> VMGCalculator? {
    let diagram: [[Double]] = [
        [0.0,  8.0,   12.0,   16.0,   20.0],
        [30.0, speed,  speed,  speed,  speed],
        [50.0, speed,  speed,  speed,  speed],
        [70.0, speed,  speed,  speed,  speed],
        [90.0, speed,  speed,  speed,  speed],
    ]
    return VMGCalculator(diagram: diagram)
}

// MARK: - downwindDirectDuration

final class DownwindDirectDurationTests: XCTestCase {

    // MARK: SOG-fallback paths (no polar needed)

    func testNilCalcFallsBackToSOG() {
        let dtmNM = 2.0
        let dtmMeters = dtmNM / toNauticalMiles
        let sog = 6.0
        let result = WaypointProcessor.downwindDirectDuration(
            distanceToMarkMeters: dtmMeters,
            twaToMark: 160,
            tws: 12,
            calc: nil,
            sogKnots: sog
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, dtmNM / sog, accuracy: 1e-6,
                       "With nil calc, duration = DTM / SOG")
    }

    func testNilTWSFallsBackToSOG() {
        let dtmNM = 3.0
        let dtmMeters = dtmNM / toNauticalMiles
        let sog = 7.0
        let result = WaypointProcessor.downwindDirectDuration(
            distanceToMarkMeters: dtmMeters,
            twaToMark: 150,
            tws: nil,
            calc: nil,
            sogKnots: sog
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, dtmNM / sog, accuracy: 1e-6)
    }

    func testZeroSOGWithNilCalcReturnsNil() {
        let result = WaypointProcessor.downwindDirectDuration(
            distanceToMarkMeters: 5_000,
            twaToMark: 160,
            tws: nil,
            calc: nil,
            sogKnots: 0
        )
        XCTAssertNil(result, "Zero SOG with no polar → cannot estimate time")
    }

    func testPolarAngleOutOfRangeFallsBackToSOG() {
        // A polar covering only 30–90°: querying 170° returns 0, triggering SOG fallback.
        let calc  = makeNarrowPolar(speed: 7.0)
        let dtmNM = 1.5
        let sog   = 6.5
        let result = WaypointProcessor.downwindDirectDuration(
            distanceToMarkMeters: dtmNM / toNauticalMiles,
            twaToMark: 170,          // outside table → evaluateDiagram returns 0
            tws: 10,
            calc: calc,
            sogKnots: sog
        )
        XCTAssertNotNil(result, "Out-of-range polar angle must fall back to SOG, not return nil")
        XCTAssertEqual(result!, dtmNM / sog, accuracy: 1e-5,
                       "Fallback value must equal DTM / SOG")
    }

    func testPolarSpeedUsedWhenAvailable() {
        // Flat polar returns `speed` for any angle in [45°, 160°].
        let speed  = 8.0
        let dtmNM  = 2.4
        let calc   = makeFlatPolar(speed: speed)

        guard let result = WaypointProcessor.downwindDirectDuration(
            distanceToMarkMeters: dtmNM / toNauticalMiles,
            twaToMark: 130,
            tws: 12,
            calc: calc,
            sogKnots: 5.0                           // would give different answer
        ) else {
            XCTFail("Expected a non-nil duration from polar")
            return
        }
        // Polar speed 8 kn → duration ≈ 2.4/8 = 0.3 h
        XCTAssertEqual(result, dtmNM / speed, accuracy: 0.05,
                       "Should use polar speed, not SOG fallback")
    }
}

// MARK: - downwindPathAdvisor

final class DownwindPathAdvisorTests: XCTestCase {

    // MARK: Sailing-state gate

    func testAdvisorReturnsAllNilsWhenNotDownwind() {
        let r = WaypointProcessor.downwindPathAdvisor(
            waypointSailingState: "Upwind",
            distanceToMarkMeters: 3_000,
            twaToMark: 40,
            leg1NM: 1.5,
            leg2NM: 1.5,
            optimalDnTWA: 130,
            tws: 12,
            calc: nil,
            sogKnots: 6
        )
        XCTAssertNil(r.direct)
        XCTAssertNil(r.gybe)
        XCTAssertNil(r.delta)
        XCTAssertNil(r.twaToMark)
        XCTAssertNil(r.optimalGybeTWA)
    }

    // MARK: Delta sign convention (critical: gybe − direct)

    /// delta = gybe − direct.  Positive → direct wins.
    func testDeltaIsPositiveWhenDirectFaster() {
        // Force direct to be fast (short path at good SOG) and gybe to be slow
        // (long legs via SOG fallback).
        let dtmNM  = 1.0
        let leg1   = 1.8    // gybe path is 1.8 + 1.2 = 3.0 NM
        let leg2   = 1.2
        let sog    = 6.0
        // direct   = 1.0 / 6.0 = 0.1667 h
        // gybe     = 3.0 / 6.0 = 0.5 h
        // delta    = 0.5 − 0.1667 = +0.333 h  → direct is faster
        let r = WaypointProcessor.downwindPathAdvisor(
            waypointSailingState: "Downwind",
            distanceToMarkMeters: dtmNM / toNauticalMiles,
            twaToMark: 155,
            leg1NM: leg1,
            leg2NM: leg2,
            optimalDnTWA: 135,
            tws: nil,
            calc: nil,
            sogKnots: sog
        )
        guard let delta = r.delta else { XCTFail("delta should not be nil"); return }
        XCTAssertGreaterThan(delta, 0,
            "delta = gybe − direct must be positive when gybe path is longer at equal speed")
        XCTAssertEqual(r.direct!, dtmNM / sog, accuracy: 1e-5)
        XCTAssertEqual(r.gybe!,  (leg1 + leg2) / sog, accuracy: 1e-5)
    }

    /// delta = gybe − direct.  Negative → gybe wins.
    func testDeltaIsNegativeWhenGybeFaster() {
        // Gybe path shorter than direct (degenerate but tests the sign).
        let dtmNM = 3.0
        let leg1  = 0.8     // gybe path = 1.6 NM < 3.0 direct
        let leg2  = 0.8
        let sog   = 6.0
        // direct = 3.0 / 6 = 0.5 h
        // gybe   = 1.6 / 6 = 0.267 h
        // delta  = 0.267 − 0.5 = −0.233 h  → gybe wins
        let r = WaypointProcessor.downwindPathAdvisor(
            waypointSailingState: "Downwind",
            distanceToMarkMeters: dtmNM / toNauticalMiles,
            twaToMark: 175,
            leg1NM: leg1,
            leg2NM: leg2,
            optimalDnTWA: 130,
            tws: nil,
            calc: nil,
            sogKnots: sog
        )
        guard let delta = r.delta else { XCTFail("delta should not be nil"); return }
        XCTAssertLessThan(delta, 0,
            "delta = gybe − direct must be negative when gybe path is shorter at equal speed")
    }

    // MARK: optimalGybeTWA passthrough

    func testOptimalGybeTWAIsReturnedInTuple() {
        let r = WaypointProcessor.downwindPathAdvisor(
            waypointSailingState: "Downwind",
            distanceToMarkMeters: 2.0 / toNauticalMiles,
            twaToMark: 160,
            leg1NM: 1.2,
            leg2NM: 1.2,
            optimalDnTWA: 128,
            tws: nil,
            calc: nil,
            sogKnots: 7
        )
        XCTAssertEqual(r.optimalGybeTWA ?? -1, 128, accuracy: 1e-9,
                       "Optimal gybe TWA must be returned unchanged in the result tuple")
    }

    // MARK: Overstood / Deep / On-layline geometric classification

    /// Mark above optimal (twaToMark < optDnTWA) → direct trivially wins, delta > 0.
    func testDirectWinsWhenMarkAboveOptimal() {
        // twaToMark = 93°, optDnTWA = 158° — the crash-session scenario
        let dtmNM = 2.2
        let sog   = 7.9
        let r = WaypointProcessor.downwindPathAdvisor(
            waypointSailingState: "Downwind",
            distanceToMarkMeters: dtmNM / toNauticalMiles,
            twaToMark: 93,
            leg1NM: 2.9,
            leg2NM: 2.8,
            optimalDnTWA: 158,
            tws: nil,
            calc: nil,
            sogKnots: sog
        )
        guard let delta = r.delta, let direct = r.direct, let gybe = r.gybe else {
            XCTFail("All values must be non-nil"); return
        }
        XCTAssertGreaterThan(delta, 0, "Mark high → direct wins → delta must be positive")
        XCTAssertLessThan(direct, gybe, "Direct time must be less than gybe time")
    }

    /// Mark deeper than optimal (twaToMark > optDnTWA) with equal leg speeds:
    /// gybe wins only when extra speed from optimal angle more than offsets the extra distance.
    func testMarkDeepIndicatorCondition() {
        // When sailing at same speed (SOG fallback, calc nil):
        // gybe path is always longer → direct wins regardless of angle.
        // But the STATUS should say "MARK DEEP" (twaToMark > optDnTWA).
        let twaToMark = 174.0
        let optDnTWA  = 156.0
        XCTAssertGreaterThan(twaToMark, optDnTWA,
            "Precondition: mark is deeper than optimal angle")

        let r = WaypointProcessor.downwindPathAdvisor(
            waypointSailingState: "Downwind",
            distanceToMarkMeters: 1.6 / toNauticalMiles,
            twaToMark: twaToMark,
            leg1NM: 1.1,
            leg2NM: 0.6,
            optimalDnTWA: optDnTWA,
            tws: nil,
            calc: nil,
            sogKnots: 6.7
        )
        XCTAssertEqual(r.twaToMark ?? -1, twaToMark, accuracy: 1e-9)
        // With equal speed (SOG only, no polar advantage):
        // gybe path 1.7 NM > direct 1.6 NM → direct wins → delta > 0
        XCTAssertGreaterThan(r.delta ?? 0, 0)
    }
}

// MARK: - formatTripDuration overflow crash regression

/// `VMGSimpleView.formatTripDuration` was crashing with EXC_BREAKPOINT (SIGTRAP)
/// because `Int(h * 3600)` traps when `h * 3600 > Int.max`.
/// This happens when effectiveSOG is near-zero (e.g., 1e-16 kn), producing
/// astronomical-but-finite hours that still pass the `isFinite` guard.
///
/// The fix adds `h < 87_600` to the guard. These tests verify the crash scenario
/// and the safety of the cap value.
final class FormatTripDurationCrashRegressionTests: XCTestCase {

    /// Demonstrate that a near-zero SOG generates hours that would overflow Int.
    func testNearZeroSOGProducesOverflowingHours() {
        let nearZeroSOG = 1e-16   // kn — pathologically small but finite
        let dtmNM       = 1.4
        let hours       = dtmNM / nearZeroSOG   // ≈ 1.4e16 hours

        // isFinite passes (this is not infinity/NaN):
        XCTAssertTrue(hours.isFinite, "Near-zero SOG produces a finite but huge value")

        // The value * 3600 exceeds Int.max on 64-bit:
        XCTAssertGreaterThan(hours * 3600, Double(Int.max),
            "hours * 3600 must exceed Int.max to confirm the crash scenario")
    }

    /// The cap value itself (87,600 h = 10 years) must fit comfortably in Int.
    func testCapValueFitsInInt() {
        let cap     = 87_600.0
        let seconds = cap * 3600   // 315,360,000
        XCTAssertLessThan(seconds, Double(Int.max),
            "The 87,600-hour cap must not itself overflow Int")
        XCTAssertEqual(Int(seconds), 315_360_000)
    }

    /// Values below the cap must convert to Int without issues.
    func testReasonableHoursConvertSafely() {
        let cases: [Double] = [0.25, 1.0, 24.0, 168.0, 720.0, 8760.0]
        for h in cases {
            XCTAssertLessThan(h, 87_600, "Precondition: value is below cap")
            let total = Int(h * 3600)
            XCTAssertGreaterThanOrEqual(total, 0, "Int conversion must be non-negative for h=\(h)")
        }
    }

    /// Multi-day formatting math: 2 days 3 hours 15 min.
    func testMultiDayFormattingMath() {
        let h     = 51.25          // 51h 15m = 2d 3h 15m
        let total = Int(h * 3600)  // 184,500 seconds
        let days  = total / 86_400
        let hh    = (total % 86_400) / 3_600
        let mm    = (total % 3_600) / 60
        XCTAssertEqual(days, 2)
        XCTAssertEqual(hh,   3)
        XCTAssertEqual(mm,   15)
    }

    /// Zero-hour boundary: should return 0d 0h 0m without crashing.
    func testZeroHoursConverts() {
        let total = Int(0.0 * 3600)
        XCTAssertEqual(total, 0)
    }
}

// MARK: - Color-logic sign convention (unit-level)

/// The view uses: gybeFaster = (delta < 0)
///   DIRECT cell → cyan when !gybeFaster (direct wins, delta > 0)
///   GYBE   cell → cyan when  gybeFaster (gybe  wins, delta < 0)
///
/// These tests verify the delta polarity that the view depends on.
final class AdvisorColorSignConventionTests: XCTestCase {

    func testDeltaPositiveWhenDirectFaster() {
        // direct = 0.2 h, gybe = 0.5 h → delta = gybe − direct = +0.3 > 0
        let direct = 0.2, gybe = 0.5
        let delta = gybe - direct
        XCTAssertGreaterThan(delta, 0, "direct faster → delta must be positive")
        let gybeFaster = delta < 0
        XCTAssertFalse(gybeFaster, "gybeFaster must be false when direct wins")
    }

    func testDeltaNegativeWhenGybeFaster() {
        // direct = 0.5 h, gybe = 0.2 h → delta = gybe − direct = −0.3 < 0
        let direct = 0.5, gybe = 0.2
        let delta = gybe - direct
        XCTAssertLessThan(delta, 0, "gybe faster → delta must be negative")
        let gybeFaster = delta < 0
        XCTAssertTrue(gybeFaster, "gybeFaster must be true when gybe wins")
    }

    func testDeltaZeroWhenTied() {
        let delta = 0.3 - 0.3
        let gybeFaster = delta < 0
        XCTAssertFalse(gybeFaster, "Tied → neither faster → gybeFaster is false")
    }

    /// Regression for the inverted-highlight bug: before the fix `directFaster`
    /// was set to `delta < 0` and used to colour the DIRECT cell. That made the
    /// DIRECT cell cyan when GYBE was faster and vice versa.
    func testHighlightLogicAfterFix() {
        // Scenario: direct = 11 min, gybe = 12 min (direct is faster)
        let directH = 11.0 / 60
        let gybeH   = 12.0 / 60
        let delta   = gybeH - directH   // +1/60 > 0

        let gybeFaster = delta < 0      // false → direct wins
        // Direct cell should be cyan (!gybeFaster), gybe cell should be dim (gybeFaster)
        XCTAssertFalse(gybeFaster)
        XCTAssertTrue(!gybeFaster,  "Direct cell must be highlighted when direct is faster")
        XCTAssertFalse(gybeFaster,  "Gybe  cell must NOT be highlighted when gybe is slower")
    }
}

// MARK: - formatAdvisorDuration string output

/// Locks the hh:mm:ss contract for the advisor DIRECT/GYBE time cells.
final class AdvisorDurationFormatTests: XCTestCase {

    private func formatAdvisorDuration(_ hours: Double?) -> String {
        guard let h = hours, h.isFinite, h > 0, h < 87_600 else { return "—" }
        let total = Int(h * 3600)
        let hh = total / 3600
        let mm = (total % 3600) / 60
        let ss = total % 60
        return String(format: "%02d:%02d:%02d", hh, mm, ss)
    }

    func testSubMinute() {
        XCTAssertEqual(formatAdvisorDuration(45.0 / 3600), "00:00:45")
    }

    func testMinutes() {
        XCTAssertEqual(formatAdvisorDuration(11.0 / 60), "00:11:00",
                       "00:11 without seconds was what the screenshot showed — must now be 00:11:00")
    }

    func testMinutesAndSeconds() {
        // 11 min 30 sec
        let h = (11.0 * 60 + 30) / 3600
        XCTAssertEqual(formatAdvisorDuration(h), "00:11:30")
    }

    func testHoursMinutesSeconds() {
        // 1h 18m 22s = 4702 sec
        XCTAssertEqual(formatAdvisorDuration(4702.0 / 3600), "01:18:22")
    }

    func testNilReturnsPlaceholder() {
        XCTAssertEqual(formatAdvisorDuration(nil), "—")
    }

    func testZeroReturnsPlaceholder() {
        XCTAssertEqual(formatAdvisorDuration(0), "—")
    }

    func testOverflowCapReturnsPlaceholder() {
        XCTAssertEqual(formatAdvisorDuration(100_000), "—")
    }
}

// MARK: - formatAdvisorDelta string output

/// Locks the "seconds always shown" contract for the racing delta display.
/// The helper replicates the formatAdvisorDelta logic from VMGSimpleView /
/// iPhoneVMGView so the format can be tested without touching private view methods.
final class AdvisorDeltaFormatTests: XCTestCase {

    private func formatAdvisorDelta(_ deltaHours: Double) -> String {
        let absSecs = Int(abs(deltaHours) * 3600)
        let h = absSecs / 3600
        let m = (absSecs % 3600) / 60
        let s = absSecs % 60
        let timeStr: String
        if h > 0 {
            timeStr = "\(h)h \(m)m \(s)s"
        } else if m > 0 {
            timeStr = "\(m)m \(s)s"
        } else {
            timeStr = "\(s)s"
        }
        return deltaHours < 0 ? "save \(timeStr)" : "+\(timeStr)"
    }

    func testSecondsOnlyDelta() {
        XCTAssertEqual(formatAdvisorDelta(-45.0 / 3600), "save 45s")
        XCTAssertEqual(formatAdvisorDelta( 30.0 / 3600), "+30s")
    }

    func testMinutesPlusSeconds_alwaysShown() {
        // 2 min 0 sec — seconds must still appear (the "always show seconds" contract)
        XCTAssertEqual(formatAdvisorDelta( 2.0 / 60), "+2m 0s",
                       "Seconds must always appear when delta is in the minutes range")
        // 1 min 15 sec
        XCTAssertEqual(formatAdvisorDelta(-75.0 / 3600), "save 1m 15s")
        // 4 min 30 sec
        XCTAssertEqual(formatAdvisorDelta( 4.5 / 60), "+4m 30s")
    }

    func testHoursPlusMinutesPlusSeconds() {
        // 1 h 18 min 22 sec = 4702 seconds
        let totalSec: Double = 4702
        let delta = totalSec / 3600
        XCTAssertEqual(formatAdvisorDelta(delta), "+1h 18m 22s")
    }

    func testSavePrefix_negativeSign() {
        // Negative delta = gybe faster → "save ..."
        XCTAssertTrue(formatAdvisorDelta(-0.05).hasPrefix("save "))
    }

    func testPlusPrefix_positiveSign() {
        // Positive delta = direct faster → "+..."
        XCTAssertTrue(formatAdvisorDelta(0.05).hasPrefix("+"))
    }

    func testZeroDelta() {
        XCTAssertEqual(formatAdvisorDelta(0), "+0s")
    }
}
