import Foundation

// MARK: - Racing / waypoint vs polar semantics
//
// **Two different “Upwind / Downwind” switches exist in the app:**
//
// 1. **Polar / boat mode** — `VMGData.sailingState` from true wind angle vs the polar tack table
//    (“sailed like an upwind leg or a downwind leg?”).
// 2. **Mark approach mode** — `WaypointData.waypointApproachState` from *bearing to mark* vs TWD,
//    the same rule `WaypointProcessor` uses for **diamond laylines** on the chart.
//
// The **tack trim bar** and **yellow optimal-TWA chevrons** compare *heading* (or TWA) to
// **TWD ± optimal TWA** for the chosen mode. That answers **polar trim on the current tack**,
// not **“are we on the layline?”** Layline alignment is a **position / course** problem: you
// can be perfectly trimmed to the polar niche yet hundreds of metres off the layline corridor.
//
// When a waypoint is active, tactical UI should follow **mark approach** mode so the same
// up/down choice drives chart laylines and the tack/angle hints where possible.

enum RacingNavigationSemantics {

    /// Sailing state used for **tack bar**, **anemometer optimal chevrons**, and other “match the chart”
    /// hints while navigating to a mark. Falls back to polar `sailingState` when no waypoint is selected.
    static func sailingStateForWaypointTackUI(
        isWaypointTargetSelected: Bool,
        waypointApproachState: String?,
        polarSailingState: String?
    ) -> String {
        if isWaypointTargetSelected,
           let w = waypointApproachState,
           w == "Upwind" || w == "Downwind" {
            return w
        }
        return polarSailingState ?? "Unknown"
    }

    /// Same up/down rule as `WaypointProcessor` for `waypointApproachState` / layline tack angle pick.
    static func markApproachIsUpwind(
        trueMarkBearingDegrees: Double,
        trueWindDirectionDegrees: Double,
        sailingStateLimitDegrees: Double
    ) -> Bool {
        let angleToMark = abs(normalizeAngleTo180(trueMarkBearingDegrees - trueWindDirectionDegrees))
        return angleToMark <= sailingStateLimitDegrees
    }

    /// Starboard-tack **target course** (TWD − optimal TWA) for the given mode, 0…360°.
    static func starboardTackTargetHeading(
        trueWindDirection: Double,
        optimalUpTWA: Double,
        optimalDnTWA: Double,
        sailingState: String
    ) -> Double {
        let optimalTWA = sailingState == "Upwind" ? optimalUpTWA : optimalDnTWA
        return normalizeAngle(trueWindDirection - optimalTWA)
    }

    /// Port-tack **target course** (TWD + optimal TWA) for the given mode, 0…360°.
    static func portTackTargetHeading(
        trueWindDirection: Double,
        optimalUpTWA: Double,
        optimalDnTWA: Double,
        sailingState: String
    ) -> Double {
        let optimalTWA = sailingState == "Upwind" ? optimalUpTWA : optimalDnTWA
        return normalizeAngle(trueWindDirection + optimalTWA)
    }
}
