# Changelog

All notable changes to this project will be documented in this file.

---

## [Unreleased] — 2026-04-14

### Features

- **Configurable UI / Watch refresh**: `SettingsManager.uiRefreshIntervalPreset` (0.5s, 1s, 2s), General Settings segmented control, `NMEAParser.setPeriodicUIUpdateInterval`, wired from `ExtasyCompleteNavigationApp` (`onAppear` + `onChange`). Default preset `1` in `DefaultSettings`.
- **Polar diagram (Canvas)**: `VMGCalculator.polarBoatSpeedCurve` / `VMGProcessor` / `NMEAParser` expose samples at live TWS; `PolarDiagramCanvasView` with boat dot and optimal TWA markers. **Polar** is its own surface: iPhone lower `TabView` tag 3 (waypoint/VMG → tag 4); iPad lower panel **Performance | Polar** segmented control. `PolarInstrumentView` keeps the **TWS** caption, **no** nav title or legend, and sizes the diagram to **fill remaining space** (nested `GeometryReader`) so `PageTabViewStyle` horizontal paging stays reliable.

### Improvements

- **iPad cockpit (v1 slice)**: `iPadView` main columns use a **45% / 55%** width split. On wide layouts (**window width ≥ 1000 pt**), the lower-left band shows **Performance** and **Polar** side by side; narrower layouts keep the segmented control.

### Bug Fixes

- **iPhone lower `TabView` paging**: A root **`NavigationStack` around the entire `PageTabViewStyle` `TabView`** in `iPhoneView` prevented horizontal swipes past the Performance page. The stack now wraps only **`UltimateView`** (tabs that use `NavigationLink`). Polar no longer needs its own stack after the title was removed.

### Refactors

- **`NMEASentenceProcessor`**: Protocol + per-processor `supportedNMEASentenceFormats`; `NMEASentenceProcessorRegistryTests` for duplicate/coverage checks. `NMEAParser` switch unchanged.

### Testing

- **`HydroProcessorTests`**: DPT valid/invalid, VHW speed field (split layout aligned with `UtilsNMEA.splitNMEAString`).

### Documentation

- **Repo doc layout:** Retired `ai/docs/` — **[`guides/testing-core-math.md`](guides/testing-core-math.md)** is the canonical math-test guide. Added root **[`AGENTS.md`](../AGENTS.md)** for Cursor. Cross-linked root vs **`ExtasyCompleteNavigation/README.md`**. Removed stray **`Untitled.ipynb`**; **`.gitignore`** now ignores Jupyter scratch (`Untitled.ipynb`, `.ipynb_checkpoints/`, `.virtual_documents/`). **`.agent-os/config.json`** also excludes **`DerivedData`**, **`.ipynb_checkpoints`**, **`.virtual_documents`**.

- **Doc hub**: Added [.agent/DOCUMENTATION.md](DOCUMENTATION.md) — layers (`.agent/`, `.agent-os/`, `.cursor/skills/`, READMEs), Agent OS scan hygiene, and optional consolidation notes. Linked from [README.md](../README.md), [PROJECT.md](PROJECT.md), and [AGENT_OS.md](../AGENT_OS.md). Expanded `.agent-os/config.json` **`exclude_dirs`** with **`.build`** so SwiftPM build trees are not indexed into handoff/context-pack.

- **Agent OS**: Initialized `.agent-os/` with `agentos init .` (SQLite index, scanned summary, cache, handoff, context pack exports). Documented refresh commands and paths in [.agent/PROJECT.md](PROJECT.md) and [README.md](../README.md). Root [AGENT_OS.md](../AGENT_OS.md) remains the CLI-maintained pointer for Xcode and hidden folders.

- **Agent OS (refresh)**: Ran `agentos cache update && agentos handoff update && agentos export` (local `.agent-os/state`, `context`, `exports` regenerated per `.gitignore`; **`AGENT_OS.md`** and Xcode **`project.pbxproj`** may be updated by the CLI, e.g. `AGENTS.md` registration).

- **Roadmap** ([.agent/ROADMAP.md](ROADMAP.md)): Added **Downwind path advisor** (straight vs gybe / VMC + polar ETA idea). Added **Consolidate waypoint & layline core** refactor (single implementation in `NavigationCorePackage`). Updated **Layline stability** bullet with Apr 2026 polar-mode refinement. **iPad cockpit dashboard** marked as the next layout slice after iPhone polar/paging stabilization.

---

## [Unreleased] — 2026-03-14

### Bug Fixes

- **AppSettings.swift**: Fixed `calibrationCoefficient` default value in `DefaultSettings.initializeDefaults()`. Was set to `false` (Bool), now correctly set to `1.0` (Double). This caused the speed log calibration to use a boolean instead of a multiplier.

- **WindMetricsView.swift (Watch)**: Fixed mislabeled metric in the bottom row. The second column showed "AWA" but displayed `awd` (Apparent Wind Direction). Label corrected to "AWD".

- **NMEAParser.swift**: Fixed duplicate dictionary keys in Watch metrics. Apparent wind data (`apparentWindForce`, `apparentWindAngle`, `apparentWindDirection`) was being sent with keys `"tws"`, `"twa"`, `"twd"` — identical to true wind — causing true wind values to be silently overwritten. Keys corrected to `"aws"`, `"awa"`, `"awd"` to match `WatchSessionManager`'s expected field map. **Apparent wind data now reaches the Apple Watch.**

- **VMGSimpleView.swift**: Removed direct struct mutation `gpsData.waypointLocation = nil` in `deselectWaypoint()`. The subsequent `disableMarker()` call already handles this on the correct serial queue, making the direct mutation both redundant and a thread-safety violation.

### Improvements

- **VMGCalculator.swift**: Replaced `fatalError` calls with graceful error handling:
  - `init(diagram:)` is now a failable initializer (`init?`) that returns `nil` on empty/malformed data instead of crashing.
  - Added validation for minimum diagram dimensions (needs >1 row and >1 column).

- **VMGCalculator.swift**: Replaced `freopen`/`readLine` file reading in `readOptimalTackTable()` with `String(contentsOfFile:encoding:)`. The old approach redirected `stdin` globally, which is fragile and not thread-safe. The new approach returns a `Bool` success indicator.

---

## [Unreleased] — 2026-03-14 (Session 2)

### Data Freshness & Connection Status (Stable Test Build)

Ensures all displayed navigation data can be trusted during on-boat testing. Previously, if a sensor stopped transmitting, the app showed frozen values with no indication — dangerous for navigation.

#### Per-Sensor Freshness Tracking

- **GPSData.swift, HydroData.swift, CompassData.swift**: Added `lastUpdated: Date?` field and reset it in `reset()`. WindData already had this.
- **GPSProcessor.swift**: Stamps `lastUpdated = Date()` in `processGLL`, `processRMC`, and `processGGA` on successful parse.
- **HydroProcessor.swift**: Stamps `lastUpdated = Date()` in `processDepth`, `processSeaTemperature`, `processSpeedLog`, and `processDistanceTravelled`.
- **CompassProcessor.swift**: Stamps `lastUpdated = Date()` in `processCompassSentence`.

#### Watchdog Expansion

- **NMEAParser.swift**: Added `SensorStatus` enum (`.active` / `.stale` / `.unavailable`) and `DataStatus` struct tracking all four sensor groups. The existing 1-second watchdog timer now checks all sensors against a 30-second staleness threshold and updates `dataStatus` on the main thread. Removed the old wind-only `lastWindUpdateTime` variable. Added `sensorStatus(forValueID:)` helper for mapping display cell IDs to the correct sensor.

#### UDP Connection Monitoring

- **UDPHandler.swift**: Added `isReceivingData: Bool` flag that tracks whether any UDP data has been received within the last 10 seconds. A 2-second polling timer checks `lastReceiveTime` and updates the flag. This is independent of per-sensor staleness (the socket could be receiving GPS but not wind).

#### Stale Data Display

- **DisplayCell.swift**: Now shows "--" when the sensor for the displayed value is stale or when no value has been received. Stale cells are dimmed to 35% opacity. Added `hasReceivedValue` state to distinguish "never received" from "received then lost".
- **SmallCornerView.swift**: Same pattern — shows "--" for stale/unavailable sensors with dimmed opacity.

#### Connection Status Indicator

- **UltimateView.swift**: Added a status dot at the top center of the compass view:
  - Green = all sensors active
  - Yellow = some sensors stale
  - Red = no data from any sensor
  - Tap to show a popover with per-sensor status detail (Wind, GPS, Depth/Speed, Compass)

---

## [Unreleased] — 2026-03-22 (Session 4)

### iOS 26 Compatibility Fixes
- **ExtasyCompleteNavigationApp.swift**: Added `nw_tls_create_options()` workaround for iOS 26 simulator TLS crash
- **VMGCalculator.swift, DiagramLoader.swift**: Replaced deprecated `String(contentsOfFile:)` with URL-based API
- **ExtasyCompleteNavigation.xcscheme**: Disabled debug executable to fix iOS 26 simulator "attaching" hang
- **MapView.swift**: Replaced `.onTapGesture` with `SpatialTapGesture` for more reliable map tap on iOS 26
- **All views**: Added `.buttonStyle(.plain)` to all custom buttons/menus to remove iOS 26 Liquid Glass chrome

### New Features
- **SettingsManager.swift**: Added `boatName`, `depthAlarmThreshold`, `depthAlarmEnabled`, `distanceUnit` settings
- **SettingsMenuView.swift**: Implemented full `AlarmsView` with configurable depth threshold slider (1–20m)
- **SettingsMenuView.swift**: Implemented full `GlossaryView` with 20 sailing/navigation term definitions
- **SettingsMenuView.swift**: Added boat name, distance unit, and metric wind settings to `GeneralSettingsView`
- **AudioManager.swift**: Added `playDepthAlarm()` with haptic feedback + system alert sound
- **MapView.swift**: Bottom floating pill toolbar replaces top-right buttons (center boat, wind mode, zoom-to-fit)
- **MapView.swift**: Replaced thread-blocking GPS poll loop with reactive `onChange` for first-run centering

### Refactoring / Code Quality
- **Logging.swift**: Replaced `print()` / `debugLog()` with categorized `os.Logger` (`Log.parsing`, `.network`, `.watch`, `.audio`, etc.)
- **Model/Layline.swift**: Moved `Layline` struct out of `MapView.swift` into its own model file
- **NMEAParser.swift**: Added `selectWaypoint(at:name:)` and `deselectWaypoint()` to fix race condition where periodic update overwrote waypoint state set by UI
- **UltimateNavigationView.swift**: Moved connection status dot + all sensor popover logic here; dot positioned at boat bow

### UI Polish
- **MultiDisplay.swift**: Removed `MultiDisplayGrid` separator lines; added card-style cells with 6pt gaps and rounded corners
- **DisplayCell.swift**: Redesigned with proper `VStack` layout — value dominant (54% width), label/unit small in corners
- **iPhoneView.swift**: Full-screen split layout using `.ignoresSafeArea()` for edge-to-edge map + instruments
- **WaypointListView.swift**: Added `.onTapGesture` to waypoint rows for direct selection

### Bug Fixes
- **NMEAParser.swift**: `selectWaypoint` now initialises `GPSData` if nil, fixing silent no-op when no NMEA data flowing
- **WaypointProcessor.swift**: Added explicit `() -> Void` return type to `serialQueue.sync` closure to fix `DispatchWorkItem` ambiguity with Whole Module Optimization
- **SettingsManager.swift**: Renamed `DistanceUnit` → `MarineDistanceUnit` to avoid MapKit framework collision

---

## [Unreleased] — 2026-03-14 (Session 3)

### Thread Safety Audit

Fixed data races between the UDP processing thread and the main (UI) thread.

#### Serial UDP Delegate Queue

- **UDPHandler.swift**: Replaced `.global()` (concurrent) delegate queue with a dedicated serial queue (`com.extasy.udp.delegate`). Ensures only one NMEA sentence is processed at a time, preventing concurrent mutation of processor state.

#### Lock-Protected Cached Data

- **NMEAParser.swift**: Added `NSLock` (`dataLock`) to protect all `cached*Data` properties, which bridge the processing thread and the main thread. `parseSentence` writes under lock; `performPeriodicUpdate` reads under lock.

#### Eliminated Cross-Thread Reads in parseSentence

- **NMEAParser.swift**: `parseSentence` previously read published `gpsData`, `hydroData`, `windData`, `compassData` (main-thread properties) from the background processing thread. Now snapshots cached data under lock at the start, and passes the latest available values (updated or cached) to downstream processors (`vmgProcessor`, `waypointProcessor`, `windProcessor`). Removed `DispatchQueue.main.async` wrapper for cached writes — now writes directly under lock on the processing thread.

#### GPSProcessor Serial Queue Consistency

- **GPSProcessor.swift**: `processGLL`, `processRMC`, `processGGA`, and `resetGPSData` now execute inside `serialQueue.sync`, matching the pattern already used by `updateMarker` and `disableMarker`. Prevents races between UI-triggered waypoint updates and NMEA processing.

### Cleanup

- **Extensions.swift**: Deleted empty file (not part of Xcode build).
- **VMGCalculator.swift**: Removed 240 lines of commented-out old implementation.
- **README.md**: Rewritten to reflect actual project structure. Removed references to non-existent `VMGViewModel` and `SettingsMenuViewModel`.
- **WaypointFillForm.swift**: Renamed from `WaypointFIllForm.swift` (typo). Updated Xcode project references.

### Error Recovery

- **UDPHandler.swift**: Added `ConnectionState` enum (`.disconnected` / `.connecting` / `.connected` / `.reconnecting` / `.error`). Automatic reconnection with exponential backoff (up to 10 attempts, max 30s delay) when socket closes with error. Socket is recreated after error close (GCDAsyncUdpSocket may not be reusable). Background polling also recreates socket. Added `intentionallyClosed` flag to prevent reconnection during deliberate close/background transitions.
- **UltimateView.swift**: Status dot and popover now show UDP connection state alongside sensor status. Dot turns orange during reconnection, red on error/disconnect.
