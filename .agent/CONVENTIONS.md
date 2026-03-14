# Project Conventions

Rules and patterns established in this codebase for consistent development.

---

## Architecture

- **Pattern**: MVVM-like with `@Observable` environment objects. Views read from `NMEAParser` and `SettingsManager` injected via `.environment()`.
- **No standalone ViewModels** at present — `NMEAParser` acts as the central state holder. If views grow complex, extract ViewModels per-screen.
- **Processors** are pure-ish computation units. They receive parsed NMEA fields and return updated data structs. They should not hold UI state.
- **Data structs** (in `Model/`) are plain Swift structs with `reset()` methods.

## Data Flow

1. `UDPHandler` receives raw string via CocoaAsyncSocket callback (background queue)
2. `NMEAParser.processRawString()` validates and routes to the appropriate processor
3. Processors return updated data structs
4. Results are cached in `NMEAParser` (dispatched to main)
5. `performPeriodicUpdate()` runs on `@MainActor` every ~1s, copying cache to published state
6. SwiftUI views react to changes via `@Environment(NMEAParser.self)`

## Naming

- **Processors**: `{Domain}Processor` (e.g., `WindProcessor`, `GPSProcessor`)
- **Data models**: `{Domain}Data` (e.g., `WindData`, `GPSData`)
- **Views**: Descriptive names, grouped by feature folder
- **NMEA keys**: Use standard abbreviations (TWS, TWA, TWD, AWS, AWA, AWD, SOG, COG, DPT, HDG)

## Settings

- All persistent settings go through `AppSettings` using the `@UserDefault` property wrapper
- Keys are centralized in `UserDefaultsKeys`
- `DefaultSettings.initializeDefaults()` sets first-launch values

## Watch Communication

- Metrics are sent as `[String: Double]` dictionaries via `WatchConnectivity`
- `DataCoordinator` buffers values and only sends when changed (delta compression)
- Keys must match between `NMEAParser.performPeriodicUpdate()` and `WatchSessionManager.fieldMap`

## Units

- Wind speed: knots (default), meters/second (when `metricWind` enabled)
- Distance: nautical miles
- Angles: degrees (0-360 for directions, -180 to 180 for relative)
- Depth: meters
- Temperature: Celsius
- Speed: knots (SOG, boat speed log)

## Error Handling

- Use `debugLog()` for diagnostic messages (DEBUG only)
- Prefer graceful degradation (return nil, show "--") over crashes
- Never use `fatalError` in production paths
