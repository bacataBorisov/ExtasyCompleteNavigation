# Extasy Complete Navigation

## Overview

**ExtasyCompleteNavigation** is a modular sailing navigation app that receives NMEA 0183 sentences over WiFi/UDP from boat instruments, processes and visualizes navigation data, and provides advanced calculations including VMG (Velocity Made Good) via polar diagrams.

This internal README outlines the app's architecture and key modules.

---

## Project Structure

```
├── ContentView.swift              # Root view, routes to iPad or iPhone layout
├── ExtasyCompleteNavigationApp.swift  # App entry point, environment setup
├── iPadView.swift                 # iPad-specific layout
├── iPhoneView.swift               # iPhone-specific layout
├── Managers/
│   ├── AudioManager.swift         # Alarm sound playback
│   ├── NavigationManager.swift    # Coordinates UDPHandler ↔ NMEAParser data flow
│   └── SettingsManager.swift      # UserDefaults-backed app settings
├── Model/
│   ├── CompassData.swift          # Compass readings (heading, normalized heading)
│   ├── GPSData.swift              # GPS readings (lat, lon, COG, SOG)
│   ├── HydroData.swift            # Hydro data (depth, temperature, boat speed)
│   ├── VMGData.swift              # VMG calculation results
│   ├── WindData.swift             # Wind data (apparent and true)
│   ├── WaypointData.swift         # Waypoint/layline computed data
│   ├── UserDefaultsKeys.swift     # Centralized UserDefaults key strings
│   └── PersistanceModels/
│       ├── AppSettings.swift      # SwiftData model for app settings
│       ├── DisplayCells.swift     # Display cell definitions (metric names, formats)
│       └── Waypoints.swift        # SwiftData model for saved waypoints
├── Modules/
│   ├── CompassProcessor.swift     # Processes NMEA compass sentences
│   ├── GPSProcessor.swift         # Processes NMEA GPS sentences (GLL, RMC, GGA)
│   ├── HydroProcessor.swift       # Processes depth, temperature, speed log
│   ├── WindProcessor.swift        # Processes apparent/true wind data
│   ├── VMGCalculator.swift        # Polar diagram interpolation (cubic spline)
│   ├── VMGProcessor.swift         # VMG/VMC calculations using VMGCalculator
│   └── WaypointProcessor.swift    # Bearing, distance, layline calculations
├── Networking/
│   └── UDPHandler.swift           # CocoaAsyncSocket UDP listener
├── Parsing/
│   └── NMEAParser.swift           # NMEA sentence routing, data watchdog, periodic updates
├── Utilities/
│   ├── Constants.swift            # App-wide constants
│   ├── DataLogger.swift           # CSV data logging
│   ├── DiagramLoader.swift        # Loads polar diagram from file
│   ├── GeometryProvider.swift     # Geometry utilities for views
│   ├── KalmanFilter.swift         # Kalman filter for sensor smoothing
│   ├── LayoutUtilities.swift      # VHStack/HVStack adaptive layout helpers
│   ├── Logging.swift              # debugLog wrapper
│   ├── MathUtilities.swift        # Angle normalization, distance, bearing
│   ├── UserDefaultWrapper.swift   # @UserDefault property wrapper
│   └── UtilsNMEA.swift            # NMEA checksum and parsing helpers
├── View/
│   ├── Common/                    # Reusable display cells (DisplayCell, speed, distance)
│   ├── InfoWaypointSection/       # Info card + waypoint card views
│   ├── MultiDisplay/              # Configurable multi-metric display
│   ├── PerformanceSection/        # VMG performance bars and tack alignment
│   ├── Shapes/                    # Custom SwiftUI shapes and grids
│   ├── SplashScreenView.swift     # App launch screen
│   ├── UltimateView/              # Main navigation instrument cluster
│   │   ├── AnemometerView/        # Wind gauge
│   │   ├── CompassView/           # Compass rose
│   │   ├── MapView/               # MapKit integration with waypoints/laylines
│   │   ├── SettingsView/          # Settings, calibration, raw NMEA viewer
│   │   ├── UltimateView.swift     # Top-level instrument layout
│   │   └── ...                    # Corner views, bearing marker, pseudo boat
│   ├── VMGView/                   # VMG-specific views
│   └── Waypoints/                 # Waypoint list, detail, and fill form
├── WatchConnectivity/
│   ├── DataCoordinator.swift      # Watch data coordination
│   ├── WatchConnectivityManager.swift  # WCSession management
│   └── WatchDataSender.swift      # Sends nav data to Apple Watch
└── Resources/
    ├── diagram.txt                # Polar diagram data
    ├── optimal_tack.txt           # Optimal tack angles per wind speed
    └── ...                        # Fonts, test scripts, audio
```

---

## Architecture

The project follows a **modular architecture** with `@Observable` for reactive state:

- **Data Layer**: Models (`CompassData`, `GPSData`, `HydroData`, `WindData`, `VMGData`, `WaypointData`) + `UDPHandler` networking + `DiagramLoader`/`KalmanFilter` utilities
- **Domain Layer**: Processors (`CompassProcessor`, `GPSProcessor`, `HydroProcessor`, `WindProcessor`, `VMGProcessor`, `WaypointProcessor`) + `VMGCalculator` + `NMEAParser` (sentence routing and data orchestration)
- **Presentation Layer**: SwiftUI views organized by feature area. Views only display; all logic lives in processors/parser.

Data flows: `UDPHandler` → `NMEAParser` (routes sentences to processors) → cached data → SwiftUI views via `@Environment`.

---

## Key Features

- **Real-time NMEA processing** with Kalman-filtered sensor smoothing
- **VMG calculation** using cubic spline interpolation on polar diagrams
- **Waypoint navigation** with bearing, distance, laylines, and map overlay
- **Adaptive layout** for iPad (primary) and iPhone
- **Apple Watch companion** with wind, speed, and heading metrics
- **Data freshness monitoring** with per-sensor stale detection and UI indicators
- **CSV data logging** for post-session analysis
