# Technical Lessons Learned

Hard-won knowledge from building a real-time marine navigation app in SwiftUI.

---

## SwiftUI

- **GeometryReader** is essential for dynamic sizing. Never hard-code dimensions — views are reused across iPhone, iPad, and different orientations.
- **ZStack** overlays views; `.overlay()` modifier is the alternative for single overlays.
- **10-container limit**: Each SwiftUI view body can hold max 10 direct children. Restructure with `Group` or extract subviews.
- **`transaction`**: Prevents labels from fading during rotation animations. Critical for the compass ring labels.
- **`.minimumScaleFactor(0.2)`**: Works on the whole ZStack. Excellent for fitting variable-length values into fixed-width cells.
- **VHStack / HVStack**: Custom wrappers that switch between VStack and HStack based on orientation. Natural for scroll direction too (portrait = horizontal scroll, landscape = vertical).
- iPhone and iPad draw shapes differently — always test both.

## Observable & Data Flow

- **Single source of truth**: Multiple `@Observable` classes that depend on each other are nearly impossible to synchronize. Consolidate into one observable (NMEAParser) and pass via `@Environment`.
- **`DispatchQueue.main.async{}`**: All UI-affecting updates must be on the main thread. Without this, views update inconsistently or not at all. Later replaced with `@MainActor` for cleaner syntax.
- **Views should not think**: Views display data. All calculations belong in processors or the parser. This was a hard lesson after putting logic in MapView.
- **Environment > Singleton**: Using `@Environment` to pass the observable class is cleaner and more testable than shared instances.
- **Cache-and-update pattern**: Don't call `DispatchQueue.main.async` from every processor individually — it floods the main thread. Instead, let processors calculate and return results, hold them in temporary variables, then do one single main-thread update at the end of `parseSentence()`. This was a breakthrough that eliminated UI freezing.
- **`@ObservationIgnored` for processors**: Mark processor instances as `@ObservationIgnored` in the parser. Only the data structs should trigger SwiftUI updates. This prevents redundant view recalculations.
- **Formatting belongs in ViewModel, not View**: Data formatting (decimal places, units, date strings) should happen before the view sees it. Keeps views purely declarative.

## SwiftData & Persistence

- **Separate `@Model` per entity**: Don't mix different persistent concepts into one model. Each display configuration, each waypoint, each setting gets its own class.
- **`ModelContainer` in app init**: Pre-loaded data doesn't work unless the container is created at the top-level app `init`. This solved multiple "empty data" issues.
- **`isStoredInMemory: true` for previews**: SwiftData previews crash without this configuration. Create a separate preview container.
- **Dynamic `#Predicate` not supported**: As of early 2024, you can't build predicates dynamically. Use manual filtering instead.
- **Enum persistence**: Enum must conform to `Codable` to be stored in SwiftData. This wasn't documented well initially.
- **Duplicate names**: Saving with the same name crashes the simulator but works on device. Keep an eye on this.
- **Bindable vars**: When using `@Bindable` with SwiftData models, changes propagate automatically. Verified that data count stays at 1 per cell (no accumulation).
- **SwiftData → AppStorage for simple state**: Display cell configurations were migrated from SwiftData to `AppStorage`. Simpler, more reliable, no model container overhead. Reserve SwiftData for complex relational data (waypoints).
- **UserDefaults via `@UserDefault` wrapper + `SettingsManager`**: For settings like tack tolerance, wind units, calibration coefficients — lightweight `UserDefaults` with a property wrapper is the cleanest approach. `SettingsManager` as `@Observable` makes settings reactive and accessible everywhere.
- **`@Query` is view-only**: SwiftData's `@Query` macro only works inside SwiftUI views, making strict MVVM impractical. Adopted a hybrid MVSU-like approach where views can own queries.

## Networking

- **CocoaAsyncSocket is rock-solid**: Tried `NWListener` first — it fails with "too many open files" after sustained UDP traffic. CocoaAsyncSocket handles continuous marine data streams without issues.
- **Socket lifecycle matters**: If you don't close the socket before reusing it (e.g., switching from simulator to device), the app crashes silently. No error, no log, just gone.
- **Always check IPs first**: When data doesn't appear, the problem is almost always network configuration, not code.

## NMEA Parsing

- **Checksum format**: Use `String(format: "%02X", value)` — the leading zero matters. `A` != `0A`.
- **Empty strings vs. missing sentences**: An empty field in a valid sentence means the sensor exists but has no data. A completely missing sentence type means the instrument isn't connected. Handle differently.
- **Wind sensor alternation**: MWV alternates TRUE and APPARENT on consecutive sends. Can read directly instead of calculating, but keep calculation as fallback.
- **Coordinate conversion**: NMEA `DDMM.MMM` → decimal degrees = `DD + (MM.MMM / 60)`. Negate for South and West.

## Navigation & VMG

- **Apple Maps is not for maritime navigation**: Accuracy is insufficient for sailing. Use the map only for visual display of positions, not for distance/bearing calculations.
- **VMG vs VMC**: Different things, different inputs:
  - **Polar VMG** = polar speed × cos(TWA), uses speed through water. Assumes properly trimmed sails.
  - **VMC** (to waypoint) = SOG × cos(angle to waypoint). Measures actual progress toward a point.
  - Upwind: ideally VMG ≈ VMC. Downwind: sailor chooses to optimize VMG or VMC depending on conditions.
- **Tack detection**: When the bearing to mark forms a 90° angle (cos = 0), it's time to tack. Compare both tacks, show the shortest.
- **Laylines are hard**: Drawing and rotating laylines on a map was one of the most difficult visual problems. Eventually solved with coordinate geometry projection.
- **Diamond laylines**: Boat laylines + waypoint laylines form a kite shape. Finding the intersection point gives you the next tack location. This was a major breakthrough.
- **Angle normalization for tack comparison**: When comparing intersection angles >90°, normalize to [-90°, 90°] range. An angle of 163° is actually -17° from the reference — `abs()` comparison then works correctly.
- **Separate VMG from Waypoint processing**: Polar speed and polar VMG should always be calculated (they don't need a target). Waypoint-specific data (distance, tacks, VMC, laylines) should only run when a target is selected. This split simplified the code enormously.
- **ETA based on VMC, not speed**: Trip duration to waypoint is more accurate when calculated from VMC (actual closing speed toward target) rather than raw boat speed.
- **Sailing state from tack table**: Don't use fixed angle thresholds for upwind/downwind. Interpolate the boundary from the optimal tack table — it varies with wind speed.
- **`freopen` is dangerous**: Redirecting stdin to read files works but is globally shared state and not thread-safe. Use `String(contentsOfFile:)`.

## Architecture & Design Principles

*Lessons from reading "A Philosophy of Software Design" and the SEI architecture course.*

- **Modules = interface + implementation**: The interface part interacts with other modules. If you change the implementation without changing the interface, complexity is reduced.
- **General-purpose first, then specialize**: Start with general-purpose methods and add specialized versions only when needed.
- **Each function should do one thing completely**: Don't split a logical operation across multiple places.
- **If users must read the code to use a method, there's no abstraction**: Provide clear interface comments and use informational variable/method names.
- **Comments should make code reading unnecessary**: A developer should be able to invoke a method by reading only its interface comment, not its body.
- **Data formatting in the wrong layer causes pain**: When display formatting was in views, changes required touching many files. Moving it to ViewModels centralized the logic.
- **Over-engineering is real**: Strict MVVM with SwiftData is impractical. A pragmatic hybrid is better than an ideologically pure but painful architecture.

## SwiftUI (v2.0 additions)

- **0°/360° wraparound for rotating views**: Don't try to smooth the angle in the processor. Use the raw angle as a delta directly in the view's rotation modifier. This avoids the "jump from 359° to 1°" animation glitch for compass, anemometer, and bearing markers.
- **Preserve view state on disappear**: When a view disappears and reappears, instruments shouldn't "recalibrate" from zero. Save the last known angle and restore it, then animate only the delta.
- **`max(width/30, 14)` for font fallbacks**: Smart pattern — calculate dynamic font size but set a minimum so text never becomes unreadable on small screens.
- **GeometryProvider for consistency**: Create a shared geometry wrapper that passes dimensions from the parent (UltimateView) to all child views. Ensures consistent sizing without each child running its own GeometryReader.
- **Map: `onAppear` before `onMapPositionChange`**: Order of modifiers matters. If position change handler fires before appear setup, you get incorrect initialization.
- **Disable map rotation**: For marine navigation, only pan + zoom are useful. Rotation adds confusion. Can be re-enabled later.

## General iOS Development

- **Extensions are powerful**: Used to cleanly add NMEA reading capabilities to the socket manager class.
- **OOP with @Model**: When you modify a property of a SwiftData model class, all views observing it update automatically. No manual refresh needed.
- **Colors from nature**: Use coral reefs or birds for color inspiration — all colors naturally match.
- **Scaled fonts**: Use `.minimumScaleFactor()` and dynamic type for consistent appearance across all device sizes.
- **Brain breaks work**: When stuck (like the Jan 26 Observable crisis), stepping away and coming back with fresh eyes leads to breakthroughs.
- **Preview with `isPreview` flag**: Check if running in preview mode to skip UDP socket connection. Prevents crashes and unnecessary network activity during development.
- **systemd for test scripts**: Running the NMEA simulator as a systemd service on the RPi means it auto-restarts on failure and survives reboots. Essential for reliable testing.
- **Avg calculation time matters**: Measured ~0.2ms per update cycle — confirms the processing pipeline is efficient and leaves plenty of headroom.

## Watch Development

- **Keep it simple**: Numbers only on the watch. No complex animations or instruments — the screen is too small and the use case (helming) demands instant readability.
- **`@Observable` + `@Environment` works the same**: WatchSessionManager follows the exact same pattern as NMEAParser on the phone side. Consistency across platforms.
- **Delta-only sending**: Only transmit metrics to the watch when values actually change. Reduces battery drain and WatchConnectivity traffic.
- **Latency is acceptable**: ~500ms phone-to-watch latency measured in simulator. Fine for navigation data that updates every ~1 second.

## Testing

- **Simulation limits**: Many navigation features can only be properly validated on the actual boat with real sensor data. Compass heading anomalies, wind sensor behavior, and GPS accuracy all require real conditions.
- **Shell scripts → Python NMEA simulator**: Simple shell scripts with recorded data were the starting point. Evolved into a Python script with configurable random NMEA generation. Eventually needs a full macOS simulator app for proper testing.
- **Google Maps for test waypoints**: Used to create coordinate sets for testing distance/bearing calculations.
- **Unit tests earn their keep**: The KalmanFilter test was the first and proved valuable. Processors and math utilities are highly testable but still lack coverage.
