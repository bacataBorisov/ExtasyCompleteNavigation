# Extasy Complete Navigation

## Developer Testing Devices

- **Primary device**: iPhone 13 Pro, iOS 26.3.1
- **Simulator**: iOS 26 simulator has known issues (MapKit gestures, slow launch, map rendering). Use iOS 17/18 simulators for reliable testing.
- **iPad**: Primary deployment target (cockpit use), not currently available for testing

## What Is This

A real-time sailing navigation system for iOS and Apple Watch. Built for the sailing yacht **Extasy**, it receives NMEA 0183 instrument data over UDP from the boat's onboard WiFi network and provides:

- Live instrument displays (compass, anemometer, depth, speed, heading)
- VMG (Velocity Made Good) calculations using the boat's specific polar diagram
- Optimal tack angles via cubic spline interpolation of polar data
- Layline visualization on a live map
- Waypoint management with distance, ETA, tack planning, and VMC
- Performance bars comparing actual vs. polar speed/VMG
- Apple Watch companion for glanceable metrics at the helm
- CSV data logging for post-race analysis

## Architecture

**Modular MVVM-like** with `@Observable` environment objects as the data backbone.

```
Boat WiFi (NMEA 0183)
    │
    ▼
UDPHandler (CocoaAsyncSocket, port 4950)
    │
    ▼
NMEAParser (checksum → split → route to processors)
    │
    ├─► HydroProcessor   → depth, temp, speed log, distance
    ├─► WindProcessor     → AWA/AWS/TWA/TWS/TWD/AWD + Kalman
    ├─► CompassProcessor  → magnetic heading + Kalman
    ├─► GPSProcessor      → lat/lon, COG, SOG + Kalman
    ├─► VMGProcessor      → polar speed, VMG, performance, laylines
    └─► WaypointProcessor → bearing, distance, tack geometry, VMC
           │
           ▼
    Cached data → @MainActor periodic update (~1s)
           │
           ├─► SwiftUI Views (iPhone / iPad adaptive layouts)
           └─► DataCoordinator → WatchConnectivity → Apple Watch
```

## Key Technical Details

| Aspect | Detail |
|--------|--------|
| **Platform** | iOS 17+, watchOS 10+ |
| **UI Framework** | SwiftUI (no UIKit/Storyboards) |
| **Networking** | UDP via CocoaAsyncSocket (SPM) |
| **Data Smoothing** | Single-variable Kalman filters on wind, compass, GPS, hydro |
| **VMG Engine** | Cubic spline interpolation over polar diagram + optimal tack table |
| **Persistence** | SwiftData for waypoints, UserDefaults for settings |
| **Watch Comms** | WatchConnectivity (message-based, delta-only sends) |
| **Logging** | CSV files (raw, filtered, waypoint-specific) every 5s |
| **Background** | UDP polling (15s cycle, 5s listen) when backgrounded |

## NMEA Sentences Handled

| Sentence | Data |
|----------|------|
| DPT | Depth |
| HDG | Magnetic heading + variation |
| MTW | Sea water temperature |
| MWV | Wind speed and angle (apparent + true) |
| VHW | Speed through water (log) |
| VLW | Distance travelled |
| GGA | GPS fix (lat/lon) |
| GLL | Geographic position |
| RMC | Recommended minimum (lat/lon, COG, SOG, time) |
| GSA/GSV | Satellite info (logged, not processed) |
| RMB | Waypoint navigation (reserved for autopilot) |
| VTG | Track made good (reserved) |

## Guides

How-tos and test-path notes live under **[`guides/`](guides/)** — for example **[`guides/testing-core-math.md`](guides/testing-core-math.md)** (Swift package tests for navigation math without the iOS simulator).

## File Organization

```
ExtasyCompleteNavigation/
├── Model/                    # Data structs (GPS, Wind, Compass, Hydro, VMG, Waypoint)
│   └── PersistanceModels/    # SwiftData + UserDefaults models
├── Managers/                 # NavigationManager, SettingsManager, AudioManager
├── Modules/                  # Domain processors + VMGCalculator
├── Networking/               # UDPHandler
├── Parsing/                  # NMEAParser + UtilsNMEA
├── Utilities/                # Kalman, math, logging, constants, extensions
├── WatchConnectivity/        # DataCoordinator, WatchDataSender, WatchConnectivityManager
├── Resources/                # Fonts, preview helpers
├── View/
│   ├── Common/               # Reusable cells and bars
│   ├── UltimateView/         # Main nav: compass, anemometer, map, settings
│   ├── MultiDisplay/         # 3x3 metric grid
│   ├── PerformanceSection/   # Speed/VMG performance bars
│   ├── VMGView/              # VMG and waypoint cards
│   ├── Waypoints/            # Waypoint list, detail, form
│   ├── InfoWaypointSection/  # Info cards
│   └── Shapes/               # Custom SwiftUI shapes
└── NMEATestScripts/          # Test data

ExtasyCompleteNavigationWatchApp Watch App/
├── WatchMainView.swift       # TabView root
├── CoreMetricsView.swift     # Depth, heading, speed, SOG
├── WindMetricsView.swift     # TWS/AWS, TWA/AWA, TWD/AWD
├── MetricRow.swift           # Reusable metric display
└── WatchSessionManager.swift # WCSession delegate
```

## Dependencies

- **CocoaAsyncSocket** (7.6.5) — UDP socket via GCDAsyncUdpSocket
- Apple frameworks: MapKit, SwiftData, WatchConnectivity, CoreLocation, AVFoundation

## Agent OS (repository index)

**Where everything lives (human vs generated, scan exclusions):** [DOCUMENTATION.md](DOCUMENTATION.md).

This repo uses **Agent OS** via the **`agentos`** Python CLI: a local SQLite index of the codebase, Markdown handoff/cache, and JSON/Markdown **context packs** for AI-assisted work.

| Path | Purpose |
|------|---------|
| [`AGENT_OS.md`](../AGENT_OS.md) (repo root) | Entry point: where files live, Xcode notes (auto-updated by `agentos`) |
| `.agent-os/` | Generated data: `data/agent_os.db`, `context/scanned-summary.md`, `state/cache.md`, `state/current-handoff.md`, `exports/context-pack.{json,md}` |
| `.agent/` | Human-written project docs (this file, `ROADMAP.md`, `CHANGELOG.md`, etc.) — **not** replaced by Agent OS; link here for architecture |

**Refresh after meaningful code or doc changes** (from repo root):

```bash
# Full rescan + regenerate cache, handoff, exports (same as first-time init)
agentos init .

# Lighter refresh (uses existing DB only — does NOT re-scan the tree)
agentos cache update && agentos handoff update && agentos export
```

**Git:** Everything under `.agent-os/` except **`config.json`** is **gitignored**. Regenerated `cache.md`, handoff, and context packs update **locally** only; they will not show up in commits unless you change `.gitignore`. Use **`agentos init .`** after changing scan exclusions or if handoff lists build artifacts (e.g. `.build/`).

**Optional:** `agentos drift check` — documentation vs index (useful in CI; exit code 2 on failure). `agentos xcode integrate` — ensure `AGENT_OS.md` / `.agent-os` are referenced in the Xcode project.

**Current index snapshot** (see also `.agent-os/context/scanned-summary.md`): on last scan, **~106 Swift files** and the main Xcode project were indexed; counts update each scan.
