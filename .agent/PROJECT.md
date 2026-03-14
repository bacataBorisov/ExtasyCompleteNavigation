# Extasy Complete Navigation

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
