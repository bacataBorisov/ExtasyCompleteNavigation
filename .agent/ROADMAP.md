# Improvement Roadmap

Prioritized list of improvements, organized by impact and effort.

---

## Priority 1 — Robustness & Stability

### Thread Safety Audit
- **Status**: Done (Session 3, Mar 2026)
- **Issue**: Processors are called from the UDP delegate queue (`.global()`), but their mutable state (`gpsData`, `hydroData`, etc.) is read on `@MainActor` by SwiftUI views. The periodic cache-and-copy helps, but cached data can be written concurrently.
- **Approach**: Convert processors to `actor` types, or synchronize all shared state with a lock/queue. Evaluate whether the whole parsing pipeline should run on a dedicated actor.
- **Files**: `GPSProcessor.swift`, `HydroProcessor.swift`, `WindProcessor.swift`, `CompassProcessor.swift`, `NMEAParser.swift`

### Connection Status UI
- **Status**: Done (Session 2, Mar 2026)
- **Issue**: No visual feedback when the boat network is disconnected, UDP data stops, or NMEA data goes stale. The watchdog (`checkForStaleData`) prints to console but doesn't notify the UI.
- **Approach**: Add a connection state enum (`connected` / `stale` / `disconnected`) to `NMEAParser` or `UDPHandler`, surface it in the navigation views as a status indicator.
- **Files**: `NMEAParser.swift`, `UDPHandler.swift`, `UltimateView.swift`

### Error Recovery
- **Status**: Partial (Session 3, Mar 2026) — auto-reconnect done, structured error types deferred
- **Issue**: UDP errors, NMEA parse failures, and invalid sentences are only logged via `print`. No retry logic, no user notification.
- **Done**: Auto-reconnection with exponential backoff, ConnectionState enum, socket recreation on error, UI integration.
- **Remaining**: Structured NMEA error types, user-facing alerts for persistent failures.

---

## Priority 2 — Code Modernization

### Swift Concurrency Migration
- **Status**: Not started
- **What**: Replace closure-based UDP callback chain with `AsyncStream`. Replace `Timer` + `DispatchQueue.main.async` with `Task` + `@MainActor`.
- **Benefit**: Eliminates manual thread management, makes data flow explicit and testable.
- **Scope**: `UDPHandler`, `NMEAParser`, `NavigationManager`

### Protocol-Based Processors
- **Status**: Done (Apr 2026) — first slice
- **What**: `NMEASentenceProcessor` lists `supportedNMEASentenceFormats` per domain processor; registry tests guard duplicates and parser coverage. `NMEAParser` routing unchanged; next step is optional dynamic dispatch table.
- **Benefit**: Uniform discoverability, compile-time processor list, safer refactors when adding sentences.

### Consolidate waypoint & layline core (package vs app)
- **Status**: Next session (Apr 2026)
- **What**: `Package.swift` now declares **iOS 17** alongside macOS so the app can link `ExtasyNavigationCore`. Authoritative `WaypointProcessor` + `WaypointData` still live in the app; the package holds a partial mirror for `swift test`. **Next:** add `XCLocalSwiftPackageReference` to the Xcode project, `import ExtasyNavigationCore` in the app target, then move the full waypoint pipeline and delete the duplicate core types.
- **Benefit**: One place to add **downwind path advisor**, new marks, and routing features — no duplicate drift between package and app.

### Structured Logging
- **Status**: Done (Session 4, Mar 2026)
- **What**: Replace `print` / `debugLog` with `os.Logger` using appropriate subsystems and categories.
- **Benefit**: Filterable in Console.app, zero-cost in release builds, proper log levels.

### Move Shared Models
- **Status**: Done (Session 4, Mar 2026)
- **What**: `Layline` struct is defined in `MapView.swift` but used by `WaypointProcessor` and `WaypointData`. Move to its own file in `Model/`.
- **Files**: `MapView.swift` → `Model/Layline.swift`

---

## Priority 3 — Testing

### Unit Tests for Core Logic
- **Status**: In progress (Session 5, Mar 2026; extended Apr 2026)
- **What**: Add tests for:
  - `MathUtilities` — angle normalization, distance, bearing ✅ (planned)
  - `VMGCalculator` — polar diagram B-spline, tack table interpolation, sailing state ✅ (planned)
  - `VMGProcessor` — performance ratio, tack deviation ✅ (planned)
  - `KalmanFilter` — damping level mapping ✅ (planned)
  - `NMEAParser` sentence routing and validation — not started
  - Each processor (known NMEA input → expected output) — **started** (`HydroProcessorTests`, `NMEASentenceProcessorRegistryTests`)
  - `WaypointProcessor` layline intersection — **in progress** (`WaypointProcessorTests` in app target)
- **Note**: B-spline interpolation does NOT return exact VPP table values at grid points — use ±5% tolerances or pre-computed expected values in tests. See `SKILL.md` for details.
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
- **Status**: Done (Apr 2026)
- **What**: `SettingsManager.uiRefreshIntervalPreset` (0.5s / 1s / 2s) drives `NMEAParser.setPeriodicUIUpdateInterval`; General Settings segmented control + `onChange` in `ExtasyCompleteNavigationApp`.

### Route / Track Persistence
- **Status**: Not started
- **What**: Record boat tracks using SwiftData (like waypoints). Enable post-race review with track overlay on the map. Use Kalman-filtered positions.
- **Origin**: From v1.0 notes

### Polar Diagram Visualization
- **Status**: Done — first slice (Apr 2026); **UI tightened** same pass — caption-only polar (no large title, no legend) for maximum diagram size; paging-friendly layout on iPhone.
- **What**: `PolarInstrumentView` (own tab on iPhone; **Performance | Polar** segment on iPad) uses `PolarDiagramCanvasView`; `VMGCalculator.polarBoatSpeedCurve(forTrueWindSpeedKnots:)` at live TWS; overlays boat (TWA + STW), optimal up/down TWA ticks. Further polish: optional compact legend as setting, wind-column highlight, theming.
- **Origin**: From v2.0 notes

### Polar Diagram Import & Multi-Boat Support
- **Status**: Not started
- **What**: Allow importing a polar from ORC `.pol` format or a custom CSV (`TWA, TWS, speed`). Store polars per boat in SwiftData. Select active polar in Settings. Current boat: Beneteau First 40.7 (Farr VPP, `Resources/first407_performance_prediction.pdf`).
- **Origin**: From v1.0 + v2.0 notes

### Real-Data Polar Calibration
- **Status**: Not started
- **What**: Collect actual boat speed / TWA / TWS triplets onboard and persist them. Compute correction offsets vs the theoretical polar. Apply corrections to improve accuracy over time. Requires on-boat data collection and a fitting algorithm.
- **Origin**: v2.0 notes + user request Mar 2026

### Stale Data Visual Reset / Per-Value Watchdog
- **Status**: Done (Session 2, Mar 2026)
- **What**: Implement a watchdog/heartbeat for **every individual value** (not just wind). Display relevant messages, icons, or greyed-out state when specific data goes stale. Different from connection status — handles individual sensor failures.
- **Origin**: From v2.0 notes — "Implement watchdog or heartbeat for every single value"

### Depth Alarm Enhancement
- **Status**: Done (Session 4, Mar 2026) — configurable threshold, haptic + sound, settings toggle
- **What**: Add configurable depth threshold, sound/vibration alert, toggle in settings.
- **Origin**: From v1.0 notes

### Kalman Filter UI Controls
- **Status**: Done (Session 5, Mar 2026)
- **What**: 0–11 "Sensor Smoothing" sliders per group (Wind, Speed & Course, Heading, Depth & Hydro) in Advanced Settings. Logarithmic Q/R mapping via `KalmanFilter.params(forDampingLevel:)`. Settings persisted in `UserDefaults`, applied on launch.
- **Origin**: From v2.0 notes

### True Wind Direction — Vector Kalman Filter
- **Status**: Done (Session 5, Mar 2026)
- **What**: Replaced scalar TWD Kalman filter with two filters operating on East/North wind vector components. Seeded on first measurement to avoid cold-start convergence delay. Reconstructed via `atan2`. Eliminates 0°/360° wrap-around artefacts and gives ~5s convergence.
- **Files**: `WindProcessor.swift`, `KalmanFilter.swift` (added `seed(to:)`)

### Layline Stability
- **Status**: Done (Session 5, Mar 2026) — **refined Apr 2026**
- **What**: Laylines were heading-dependent because `sailingState` (from boat TWA) was used. Replaced with `waypointSailingState` derived from bearing-to-mark vs TWD (stable). Extended `laylineDistance` to `max(4× distance, 200 km)` to guarantee intersection. Added `waypointApproachState` to `WaypointData`. Guard restructured to always persist computed laylines even if tack intersection fails. `MapView` condition `isVMCNegative` removed so laylines always show.
- **Apr 2026**: Diamond **tack angle** (`generateDiamondLaylines`) prefers **`VMGData.sailingState`** (live TWA vs polar threshold) when `Upwind`/`Downwind`, so mark geometry matches **optimal up/down angles you are actually sailing**; falls back to `waypointApproachState` if polar mode unknown. `waypointApproachState` kept for context (e.g. debug “Mark”). `MapView` draws the processor diamond + trim logic.
- **Files**: `WaypointProcessor.swift`, `WaypointData.swift`, `MapView.swift`

### Waypoint View — Tack Display Redesign
- **Status**: Done (Session 5, Mar 2026)
- **What**: `iPhoneVMGView` redesigned with explicit text labels. Two rows:
  - **CURRENT**: current tack leg (boat → tack intersection). PORT/STBD from live TWA (> 180° = PORT). Sailing mode (UPWIND/DOWNWIND) from bearing-to-mark vs TWD.
  - **NEXT**: second leg (tack intersection → mark). PORT/STBD computed from `second-leg TWA = (TWD − bearing_intersection_to_mark) mod 360°` — independent of the current tack. Sailing mode from `intersectionAoM` vs `sailingStateLimit`. Added `nextLegTack` and `nextLegSailingState` to `WaypointData`.
- **Key insight**: On a downwind approach, the boat can still be on PORT gybe (wind from port stern quarter) even though it just tacked off a PORT upwind leg — because it bears away rather than tacking through the bow. Always compute leg tack from leg geometry, not by inverting the current tack.
- **Files**: `WaypointProcessor.swift`, `WaypointData.swift`, `iPhoneVMGView.swift`

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

### Downwind path advisor — straight vs gybe(s)
- **Status**: Not started (noted Apr 2026)
- **What**: On downwind legs, estimate whether **sailing straight toward the mark** (fewer maneuvers) or **heating up / gybing** at **polar-optimal TWA** yields **shorter time to mark**. Compare **VMC toward the mark** on candidate headings with **polar boat speed** at relevant TWAs; start with a simple **stay vs one gybe** (or rhumb vs one “VMG leg”) ETA using existing `WaypointData` / dual-tack VMC fields before full route search.
- **Benefit**: Answers “sometimes straight is faster, sometimes not” inside the app instead of crew guesswork alone.
- **Related**: `.cursor/skills/sailing-racing-tactics/SKILL.md` (VMC vs VMG, fastest-path notes).

### Lock Screen Widget
- **Status**: Not started
- **What**: Display remaining distance and time to waypoint on the iOS lock screen.
- **Origin**: From v2.0 notes

### iPad — primary cockpit layout (design direction)
- **Status**: **In progress (Apr 2026)** — iPhone polar tab + `TabView` paging stabilized; **first implementation task**: default **landscape “cockpit dashboard”** preset (see targets below). Additional layout presets later.
- **Context**: iPad is **typically mounted landscape** for readability on the boat.
- **Target (v1 dashboard)**: Landscape-first **chart + instruments** on one surface (no map only behind a push). Rebalance column widths (~45/55 or similar), optional **Performance + Polar** side-by-side in the lower band when width allows; single root `NavigationStack` or map as **sheet/overlay** TBD. Waypoint-active mode may allocate more vertical space to VMG when navigating.
- **Slice 1 (Apr 2026)**: `iPadView` uses a fixed **45% / 55%** main column split (instruments-left / multi+waypoint-right). When **full window width ≥ 1000 pt**, the lower-left band shows **Performance** and **Polar** side by side; narrower widths keep the segmented picker.
- **Files (expected)**: `iPadView.swift`, `ContentView.swift`, possibly `MapView.swift` / `UltimateView.swift` for split sizing.

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
- **Status**: Partial (Session 4, Mar 2026) — boat name done; logo and login not started
- **What**:
  - Custom boat name (entered on first launch, shown on map) ✅
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
- **Status**: Done (Session 4, Mar 2026) — NM, cables, meters via `MarineDistanceUnit` enum in `SettingsManager`
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
- **Status**: Done (Session 4, Mar 2026) — 20 terms in `GlossaryView` accessible from Settings
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
- Refactor MapView for better scalability and first-run experience ✅ (reactive `onChange` for GPS centering, Session 4)
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
