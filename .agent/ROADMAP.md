# Improvement Roadmap

Prioritized list of improvements, organized by impact and effort.

---

## Priority 1 — Robustness & Stability

### Thread Safety Audit
- **Status**: Not started
- **Issue**: Processors are called from the UDP delegate queue (`.global()`), but their mutable state (`gpsData`, `hydroData`, etc.) is read on `@MainActor` by SwiftUI views. The periodic cache-and-copy helps, but cached data can be written concurrently.
- **Approach**: Convert processors to `actor` types, or synchronize all shared state with a lock/queue. Evaluate whether the whole parsing pipeline should run on a dedicated actor.
- **Files**: `GPSProcessor.swift`, `HydroProcessor.swift`, `WindProcessor.swift`, `CompassProcessor.swift`, `NMEAParser.swift`

### Connection Status UI
- **Status**: Done (Session 2, Mar 2026)
- **Issue**: No visual feedback when the boat network is disconnected, UDP data stops, or NMEA data goes stale. The watchdog (`checkForStaleData`) prints to console but doesn't notify the UI.
- **Approach**: Add a connection state enum (`connected` / `stale` / `disconnected`) to `NMEAParser` or `UDPHandler`, surface it in the navigation views as a status indicator.
- **Files**: `NMEAParser.swift`, `UDPHandler.swift`, `UltimateView.swift`

### Error Recovery
- **Status**: Not started
- **Issue**: UDP errors, NMEA parse failures, and invalid sentences are only logged via `print`. No retry logic, no user notification.
- **Approach**: Implement structured error types, add automatic UDP reconnection, show transient alerts for persistent failures.

---

## Priority 2 — Code Modernization

### Swift Concurrency Migration
- **Status**: Not started
- **What**: Replace closure-based UDP callback chain with `AsyncStream`. Replace `Timer` + `DispatchQueue.main.async` with `Task` + `@MainActor`.
- **Benefit**: Eliminates manual thread management, makes data flow explicit and testable.
- **Scope**: `UDPHandler`, `NMEAParser`, `NavigationManager`

### Protocol-Based Processors
- **Status**: Not started
- **What**: Define a `NMEAProcessor` protocol with `func process(_ sentence: [String]) -> SomeData`. Each processor conforms.
- **Benefit**: Uniform interface, easier testing, potential for dynamic processor registration (e.g., custom NMEA sentences).

### Structured Logging
- **Status**: Not started
- **What**: Replace `print` / `debugLog` with `os.Logger` using appropriate subsystems and categories.
- **Benefit**: Filterable in Console.app, zero-cost in release builds, proper log levels.

### Move Shared Models
- **Status**: Not started
- **What**: `Layline` struct is defined in `MapView.swift` but used by `WaypointProcessor` and `WaypointData`. Move to its own file in `Model/`.
- **Files**: `MapView.swift` → `Model/Layline.swift`

---

## Priority 3 — Testing

### Unit Tests for Core Logic
- **Status**: Not started (only `KalmanFilterTest` exists)
- **What**: Add tests for:
  - `NMEAParser` sentence routing and validation
  - Each processor (known NMEA input → expected output)
  - `VMGCalculator` polar interpolation
  - `MathUtilities` (angle normalization, distance, bearing)
  - `WaypointProcessor` layline intersection
- **Benefit**: Confidence in refactoring, regression prevention

### NMEA Test Data & Simulator
- **Status**: Basic Python simulator exists, deployed as systemd service on RPi
- **What**: The current Python script generates random NMEA data with configurable limits. A full **macOS NMEA simulator app** was identified as a separate project need — the script isn't realistic enough for thorough testing.
- **Origin**: From v2.0 notes — "NMEA simulator lacks a lot of functionality and I can't properly test my apps"

### Real-Environment Validation
- **Status**: Not started — blocked on boat access
- **What**: On-boat testing checklist:
  - Bearing to mark accuracy (many calculations depend on it)
  - Compass and wind gauge behavior in real conditions
  - Laylines in both wind mode and waypoint mode
  - Sailing state detection accuracy
  - Kalman filter fine-tuning (especially wind filter)
  - Downwind angle testing (suggested: Nessebar, Burgas, or Cape Emine)
- **Origin**: From v2.0 notes

---

## Priority 4 — Features

### Configurable Refresh Rate
- **Status**: Not started
- **What**: The 1.037s periodic update interval is hardcoded. Allow user to choose between e.g. 0.5s (racing) and 2s (cruising).

### Route / Track Persistence
- **Status**: Not started
- **What**: Record boat tracks using SwiftData (like waypoints). Enable post-race review with track overlay on the map. Use Kalman-filtered positions.
- **Origin**: From v1.0 notes

### Polar Diagram Import & Editing
- **Status**: Not started
- **What**: Allow importing custom polar diagrams (e.g., ORC or from other boat models). Allow adding custom correction points. Visualize curves (tested in GeoGebra — "looks quite all right"). Dynamically gather data to update polar diagram and tack tables for improved accuracy.
- **Origin**: From v1.0 + v2.0 notes

### Stale Data Visual Reset / Per-Value Watchdog
- **Status**: Done (Session 2, Mar 2026)
- **What**: Implement a watchdog/heartbeat for **every individual value** (not just wind). Display relevant messages, icons, or greyed-out state when specific data goes stale. Different from connection status — handles individual sensor failures.
- **Origin**: From v2.0 notes — "Implement watchdog or heartbeat for every single value"

### Depth Alarm Enhancement
- **Status**: Basic version exists (color change under 5m)
- **What**: Add configurable depth threshold, sound/vibration alert, toggle in settings.
- **Origin**: From v1.0 notes

### Kalman Filter UI Controls
- **Status**: Not started
- **What**: Expose Kalman filter coefficients in Advanced Settings for each sensor value. Add explanation of how to tune them. "Create the damping low pass effect with Kalman and make them adjustable from 0 to 11" (goes to 11).
- **Origin**: From v2.0 notes

### Race Timer
- **Status**: Not started
- **What**: Start/final countdown timer for race starts, similar to Garmin race timer.
- **Origin**: From v1.0 notes

### Race Marks (Start Line)
- **Status**: Not started
- **What**: Support for at least 3 marks for upwind/downwind racing — 2 for start line + 1 turning mark. One start mark can be a committee boat.
- **Origin**: From v1.0 notes

### Performance Ratio: Current vs Opposite Tack
- **Status**: Not started
- **What**: Time/distance ratio comparing current and opposite tack to help decide whether to tack.
- **Origin**: From v2.0 notes

### Wind Shifts, Currents & Drift Integration
- **Status**: Not started
- **What**: Incorporate wind shift detection, current estimation, and drift into layline calculations for more realistic tactical information.
- **Origin**: From v2.0 notes

### Lock Screen Widget
- **Status**: Not started
- **What**: Display remaining distance and time to waypoint on the iOS lock screen.
- **Origin**: From v2.0 notes

### Map Enhancements
- **Status**: Partially done
- **What**:
  - Full-screen map mode with data overlay
  - Coordinates below waypoint markers (tap to edit)
  - Map compass features (if necessary)
  - Better mechanism for no-GPS fallback: try 10 times → last known location → 0,0 with message → reinitialize when data returns
  - Center-on-boat button with configurable zoom levels
  - Enable map rotation (currently disabled)
- **Origin**: From v2.0 notes

### Personalization
- **Status**: Not started
- **What**:
  - Custom boat name (entered on first launch, shown on map)
  - Custom boat logo upload
  - Google/Apple login for personalization
- **Origin**: From v2.0 notes

### iCloud Data Sync
- **Status**: Not started (attempted, deferred)
- **What**: Sync collected CSV log data with iCloud Drive when WiFi is available. Also consider cached/backup data for displaying last known position.
- **Origin**: From v2.0 notes

### Drag-and-Drop Waypoint Adjustment
- **Status**: Not started
- **What**: Allow moving a waypoint by dragging it on the map.
- **Origin**: From v1.0 notes

### Waypoint Detail Map Preview
- **Status**: Not started
- **What**: When viewing waypoint details, show a small map snippet with the marker position.
- **Origin**: From v1.0 notes

### Distance Unit Selection
- **Status**: Not started
- **What**: Distance cells selectable between NM, cables, boat lengths (requires boat length in settings), meters.
- **Origin**: From v1.0 notes

### Bearing Display Mode
- **Status**: Partially done (true/relative toggle exists)
- **What**: Make bearing-to-mark selectable between true and relative in all relevant displays.

### Offline Map Support
- **Status**: Not started
- **What**: Investigate offline map tile caching for use without internet connectivity at sea.

### Boat Position in Display Cells
- **Status**: Not started
- **What**: Show current boat coordinates in multi-display cells as a selectable option.

### Glossary / Abbreviation Reference
- **Status**: Not started
- **What**: In-app glossary defining all abbreviations (AWA, TWS, VMG, VMC, COG, SOG, etc.) for less experienced crew.

### Connection Instructions
- **Status**: Not started
- **What**: Write setup instructions for connecting to major marine brands — NMEA 0183/2000 with Garmin, B&G, Raymarine.
- **Origin**: From v2.0 notes

### Settings View Redesign
- **Status**: Not started
- **What**: Standard iOS-native settings view. Consider adding processing time display (moving average) in advanced settings.
- **Origin**: From v2.0 notes

### Watch App: Long-Press Full Screen
- **Status**: Not started
- **What**: On long press of a watch metric, go to full-screen display of that single value. Also investigate Action Button integration.
- **Origin**: From v2.0 notes

### Accessibility
- **Status**: Not started
- **What**: Add VoiceOver labels to all instrument displays and controls.

---

## Priority 5 — Cleanup

- Remove empty `Extensions.swift`
- Update `README.md` to remove references to non-existent `VMGViewModel` and `SettingsMenuViewModel`
- Clean up commented-out old VMGCalculator implementation at bottom of file
- Remove `global` variable `displayCell` in `DisplayCells.swift` — consider a proper registry pattern
- Rename `WaypointFIllForm.swift` → `WaypointFillForm.swift` (typo in filename)
- Refactor MapView for better scalability and first-run experience
- Redesign MultiDisplay to be more adaptive across screen sizes
- Ensure all available values from data structures are displayable in cells
- Update Software Architecture diagram in Lucidchart with latest module structure

---

## Design Principles

Guiding principles established across v1.0 and v2.0 development:

1. **This app is a listener only** — we never transmit to boat instruments
2. **Universal NMEA 0183 support** — should work with any NMEA 0183 device, not just B&G
3. **Views should not think** — all logic in processors/parser, views only display
4. **Graceful degradation** — show "--" for missing data, never show stale values as if current
5. **iPad is the primary target** — big screen, visible in cockpit. iPhone is secondary but fully supported
6. **Colors from nature** — use coral reefs or birds for inspiration (all colors naturally match)
7. **NMEA 2000 is a separate project** — different hardware, different software
8. **Modules = interface + implementation** — changing internals without changing the interface reduces complexity
9. **Each function does one thing completely** — no splitting logical operations across multiple places
10. **If users must read code to use a method, there's no abstraction** — provide clear interface comments
