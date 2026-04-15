# Development History

Full development journal for Extasy Navigation, from first line of code to present.

**Motto**: "Точно, бързо, вярно!" (Борито така обича да се работи)

---

## Project Origins

The project began as an iOS counterpart to an existing Android app built by Joro. The goal: read NMEA 0183 data from the sailing yacht **Extasy**'s B&G instruments via a Raspberry Pi WiFi bridge and display it as a modern navigation interface.

**The team**:
- **Ivan** — hardware: bought the B&G-to-NMEA converter on eBay, built the RPi bridge, handles cable and electrical work on the boat
- **Joro** — wrote the original Android app and the VMG/polar diagram calculation engine (ported from Java)
- **Bori (Vasil)** — iOS app development, this project

**Hardware chain**: B&G instruments → NMEA 0183 level shifter → Raspberry Pi → WiFi broadcast (UDP port 4950) → iOS app

---

## Timeline

### Phase 1: Foundation (Jul–Oct 2023)

**~210 hours over 70 days**

- Started directly in SwiftUI without a formal design phase
- Connected to MQTT client first, then switched to UDP after discovering the RPi broadcasts on port 4950
- Password for "Extasy" network: `123456789`, RPi IP: `192.168.8.1`
- Tried `NWListener` for networking but it failed with "too many open files" after a while. Switched to **CocoaAsyncSocket** — simple, stable, works on simulator and device
- Ported Joro's VMG calculation from Java. Verified it matches the polar diagram accurately
- Built first versions of: compass, anemometer, NMEA parser (~80%), GPS coordinate display, basic MapView, multi-display grid, ultimate navigation view
- Implemented portrait and landscape modes
- Took design inspiration from B&G Triton 2 navigation displays
- Display cell values loaded from JSON files
- Corner view logic: top-left & bottom-right for speeds, top-right & bottom-left for angles
- Tested MapKit — found it unreliable for maritime use (inaccurate, warnings with small region deltas)

**14 Oct 2023 — First on-boat test (yacht Falkor)**:
- GPS data worked correctly
- NMEA parsing function validated
- VTG sentence not published by the GPS (unexpected)
- Lesson: always check IP addresses first when data doesn't appear

### Phase 2: Wind & Compass (Dec 2023)

- **5 Dec**: Infinite compass rotation was a major struggle. Tried multiple approaches
- **7 Dec**: Breakthrough with wind calculations. AWA and TWA now computed and displayed correctly. The `arccos` function always returns positive values, so true wind sign depends on apparent wind values
- **10 Dec**: Compass finally spins endlessly. Wind direction functions implemented. Display function created to show values without modifying the underlying data
- **11 Dec**: Fixed coordinate conversion. NMEA format (DDMM.MMM / DDDMM.MMM) → decimal degrees for `CLLocation`
- Discovered every second MWV string from the wind sensor alternates between TRUE and APPARENT wind — can use directly instead of calculating

**16 Dec 2023 — Hardware test 1**:
- Successfully read NMEA box with Elimex adapter
- Level shifter cables were swapped — after fixing, data readable via `cat /dev/ttyAMA4` on nanoPi
- Could not read data over WiFi — investigation needed
- Intermittent cable issues

**19 Dec 2023 — Hardware test 2**:
- Successfully read ALL boat navigation data
- Sea water temperature: no data (sensor possibly connected to depth meter, needs checking in better weather)
- GPS: cables cut, needs repair
- Speed log: cables rusty, Ivan will fix

### Phase 3: SwiftData & Waypoints (Jan 2024)

- **5 Jan**: Fixed checksum calculation — needed `%02X` format for single-digit hex values. Removed VMG calculations to redo properly. Created shell script with real boat data for testing
- **6 Jan**: Added talkerID and character validation functions
- **7–8 Jan**: SwiftData deep dive. Discovered you can use multiple models with one container. Persisted configuration for both MultiDisplay and UltimateDisplay simultaneously
- **9 Jan**: Marker with saved coordinates in SwiftData. Coordinates entered manually or captured from current position
- **10–11 Jan**: VMG understanding deepened. Polar speed, polar VMG (speed × cos(TWA)), and waypoint VMC now calculated. Polar VMG uses speed through water; VMC uses SOG — assumes sails are properly trimmed
- **12 Jan**: Boat marker rotates with heading animation on the map
- **13 Jan**: Calculations update as boat moves. Concluded Apple Maps is unreliable for precise maritime navigation
- **14 Jan**: Major pivot — moved all calculation logic from MapView into the NMEA reader class. Map now only displays boat location/heading and markers
- **15 Jan**: SwiftData for waypoints with delete function. Overlay data on map. Bearing marker on compass
- **16–18 Jan**: Waypoint detail view and list view. OOP breakthrough — using `@Model` class properties means edits auto-propagate. "Classes are very powerful, I must admit and learn how to use them properly"
- **19 Jan**: Marker visibility tied to target selection. Separate form for new waypoints. Bearing marker on UltimateView follows selection state
- **20–21 Jan**: Started iPad refactoring. Small map view with 5000m radius around marker

### Phase 4: The Great Refactor (Late Jan 2024)

- **22–23 Jan**: SwiftData struggles. Dynamic `#Predicate` not supported yet. Worked on the "--" conception (showing dashes for missing data). Decided all values should be Optional
- **24 Jan**: Separated UDP connection manager from NMEA parser into two classes. Key principle established: **"Views should not think, they should only display"**
- **25–26 Jan**: "Complete madness." Observable class synchronization issues. Tried `@MainActor`, shared instances, combining files — nothing worked. Posted on Stack Overflow. Took a brain break
- **27 Jan**: **Breakthrough.** Stack Overflow user "working dog support Ukraine" pointed to the Observable class article. Major rewrite:
  - `UDPHandler` became part of `NMEAReader` class
  - Single instance in ContentView, passed down via `@Environment`
  - All updates wrapped in `DispatchQueue.main.async{}` for synchronous view updates
- **28 Jan**: Everything working again with the new architecture. Environment-based data passing. Created `displayValue()` function returning `Double?`
- **29 Jan**: All values now Optional. Map zoom +/- buttons added
- **30 Jan**: SwiftData with pre-loaded data was painful. Finally solved by inserting `ModelContainer` in app-level `init`
- **31 Jan**: MultiDisplay and UltimateDisplay both persisting configuration via SwiftData. `isStoredInMemory: true` for previews. SwiftData duplicate name bug — crashes simulator only, works on device

### Phase 5: Polish & VMG Views (Feb 2024)

- **1 Feb**: Wind units switchable (knots ↔ m/s) from settings. Depth alarm: cell background changes color under 5m
- **2 Feb**: Sentence format validation. `VHStack` / `HVStack` for rotation-aware layouts. VMG view started
- **3 Feb**: ETA with time formatting. Navigation stack fills half display. iPad landscape looking "perfect." VMC color coding (green=good, red=bad). Realized tack calculation uses cosine — when angle = 90°, cos = 0, time to tack
- **4 Feb**: Tack calculations working but hard to test without precise GPS track. Google Maps used to create test waypoints
- **5–6 Feb**: Angle display functions for AWA, TWA, HDG on compass rings. Mark bearing split into true and relative
- **7 Feb**: Tap to switch true/relative bearing to mark. SwiftData enum persistence workaround (toggle var) until beta support lands
- **8 Feb**: SwiftData + Enums working via `Codable` conformance. Key insight: **use a separate `@Model` class for every distinct persistent entity**. Verified data count always stays at 1 per cell
- **9 Feb**: Tack ETA, distance menu. Boat position / waypoint position merged into one switchable view
- **10 Feb**: Stuck on layline drawing and animations
- **15 Feb**: Fixed VMG relative/true angle bug. Still struggling with layline rotations

### Phase 6: Gaps & Revisits (Jun–Oct 2024)

- **15 Jun 2024**: Returned after 4-month break. Implemented auto-deselect previous VMG target when selecting new one. Fixed Raw Data section. "Looks like you forget after few months. I will get back to it fast"
- Noticed: VMG and VMC occasionally drop to 0. Distance display needs more precision (2 decimal places)
- **13 Oct 2024**: Compass fading fixed. Heading/angle switching works with some edge cases (needs on-boat testing). Code optimization with Copilot assistance. Depth alarm colors corrected (triggers under 5m)

---

## v2.0 — ExtasyCompleteNavigation

**Context**: After a portfolio review by **Corinne** (mentor/colleague), she recommended pursuing formal software architecture education and adopting more modular, configurable code structure. This launched a major rewrite with professional development goals:

- Corinne's feedback: *"ExtasyCompleteNavigation is a really nice one for use as a portfolio example."*
- Recommended resources: SEI software architecture course ($500), professional certificate exam ($150), *"A Philosophy of Software Design"* book
- SAD (Software Architecture Document) template from SEI studied
- Goal: regular GitHub uploads with proper commit hygiene

### Phase 7: MVVM Architecture Overhaul (Oct–Dec 2024)

**26 Oct 2024**:
- Code walkthrough, marked TODOs throughout
- Replaced if/else with ternary operators where appropriate
- Reorganized all files according to MVVM concept (initial pass)

**18–22 Nov 2024 — MVVM Decomposition**:
- Studied layer architecture (Presentation / Domain / Data) as a future goal
- Decomposed SettingsView into `SettingsMenuView` + `SettingsMenuViewModel` with mock preview data
- Separated UDP connection logic and NMEA validation into their own files
- **WindProcessor** extracted: added last-known-value mechanism to prevent disappearing data on alternating strings, watchdog timer (30s configurable), Kalman filter for wind force
- **KalmanFilter unit tests** added — first test suite in the project
- **CompassProcessor** separated (struggled with wraparound problem, deferred)
- **HydroProcessor** created (depth, temperature, speed log, distance)
- **GPSProcessor** separated
- **VMGProcessor** separated — complex because of interconnected data. Defined VMGData/VMGProcessor/VMGCalculator pattern
- NMEAParser file "looks pretty clean now"
- Created **GeometryProvider** for consistent geometry across views
- Explored MVSU as alternative to MVVM for SwiftData-heavy views (SwiftData's `@Query` is view-only, making strict MVVM impractical)

**26–27 Nov 2024**:
- Project reorganized using `tree` command — folders and files restructured
- JSON menu files removed; replaced with Swift structs + static content (more native)
- VMGView freezing issue solved by adding ViewModel between VMGProcessor and VMGView
- Data formatting moved from View to ViewModel
- `vmgData` and `vmgProcessor` marked `@ObservationIgnored` in NMEAParser to avoid redundant updates

**30 Nov 2024**: Software architecture diagram created in Lucidchart

**16–23 Dec 2024 — Processor Pipeline Rewrite**:
- **17 Dec**: VMGProcessor completely rewritten. NMEAParser is now the single source of truth for all observation
- **18 Dec**: VMG metrics formatted for display. Background calculation + main thread UI update pattern established. Map freezing discovered
- **19 Dec**: Invented the **cache-and-update mechanism**: processors calculate and return data → held in temporary variables → all data updated on main thread at end of `parseSentence()`. Avoids multiple `DispatchQueue.main.async` calls blocking the main thread. Applied to all processors:
  - HydroData & HydroProcessor — done
  - WindData & WindProcessor — done
  - GPSData & GPSProcessor — done
  - CompassData & CompassProcessor — done
- **20 Dec**: All processors now calculate in background, update via NMEAParser on main thread. Processors marked `@ObservationIgnored`; only data structs are observed
- **21–22 Dec**: Separated VMGProcessor into **VMGProcessor** (polar speed, polar VMG — always calculated) and **WaypointProcessor** (mark-specific: distance, tacks, VMC — only when target selected). Splash screen created
- **23 Dec**: Total distance calculated in separate property. Data reset on view disappear for fresh calculations per mark
- **25 Dec**: VMG/Waypoint separation complete. VMC performance bar added. ETA now based on VMC (more relevant than raw speed). Optimal tack angles table integration started

### Phase 8: Feature Completion & Polish (Dec 2024–Feb 2025)

**26–31 Dec 2024**:
- **Tack alignment** implemented with adjustable tolerance
- **Dynamic sailing state** — upwind/downwind threshold now from interpolated tack table, not fixed boundaries
- **Tack card** fully updated: duration, distance, ETA (Date format), number of tacks
- **Laylines implemented** using optimal angles from tack table based on wind speed — "I am impressed how it happened"
- Map animations for boat location and laylines
- Design polish: shadows, gradients, wrapped buttons, weather card, waypoint card
- Waypoint selection/dismissal moved to card UI (removed UltimateView button)
- **SettingsManager** with `@Observable` + `UserDefaults` — lightweight, accessible everywhere
- Tack tolerances in settings, wind mode persistence via `AppSettings`
- Laylines in wind mode (without waypoint) added to VMGProcessor
- Waypoint laylines disable wind-mode laylines when active

**1–4 Jan 2025**:
- Waypoint form: long-press context menu for target selection
- Negative VMC handling with animated alert ("Moving away from waypoint")
- InfoWaypointView + SimpleVMGView combined
- Manual speed log calibration in settings
- SOG/Speed Log calibration comparison with **Simple Moving Average** (SMA, window=5)
- iPad view refactored

**6–14 Jan 2025**:
- Python NMEA simulator script created — generates random NMEA data with configurable limits. Deployed to RPi as a systemd service (`/etc/systemd/system/nmea.service`)
- **0°/360° wraparound solved** for compass, anemometer, and bearing to mark — delta-based animation directly in view
- Unnecessary smoothing calculations removed from processors — "everything becomes simple"
- Position preservation when views disappear (compass, bearing, anemometer)
- **Laylines corrected** — were very wrong, now using proper angle and distance calculations
- **Opposite tack calculations**: relative bearing computed with optimal attack angle, normalized to [-90°, 90°] for proper comparison
- **Diamond laylines** working: boat + waypoint laylines form a kite shape, intersection points calculated, distance from boat/waypoint to intersection
- Layline colors swap based on sailing state (port ↔ starboard)
- Double performance bar for VMC: current vs opposite tack effectiveness
- Tack alignment using heading vs optimal tack angle
- Sailing state dynamically updated from tack table threshold

**15–22 Jan 2025**:
- Intersection geometry handling fixed for both upwind and downwind
- Current tack determination: uses normalizeTo90 for angles >90°, compares absolute intersection angles
- Map animations, center waypoint+boat button
- VMGSimpleView simplified — warning message appears inline
- iPhone view optimization: font sizes, multi-display fit
- **Background UDP polling**: 5-second listen window every 15 seconds, socket lifecycle managed properly
- All persistent positions restored on view load (zoom, compass, anemometer, camera direction)
- Average calculation time: ~0.2ms per update cycle
- Python script enhanced with auto-restart (systemd), 10s restart delay on failure
- First-run MapView initialization: boat location if available → last known → fallback to 0,0
- Waypoint list sorted alphabetically, force-refresh via `.onChange`
- Map: boat entry animated, only pan+zoom enabled (rotation disabled for now)

**25–27 Jan 2025**:
- GitHub update with iPhone demo videos and screenshots
- Removed SwiftData for MultiDisplay/UltimateView → `AppStorage` (simpler, more reliable)
- Duplicate detection + smooth swapping for cell configurations
- Map initialization: wait for `boatLocation`, fallback to last saved, then fixed zoom at 200000

**1–4 Feb 2025 — Data Logging**:
- CSV logging implemented: files visible on-device via updated Info.plist
- iCloud sync attempted but deferred (too complex for now)
- Logging every 5 seconds
- Raw data fields added to all processors (`rawLatitude`, `rawDepth`, `rawApparentWindForce`, etc.)
- WindProcessor modified to always calculate both apparent and true wind regardless of incoming sentence type
- Kalman filters applied after calculations
- Three log files: `raw_data`, `filtered_data`, `waypoint_data`
- Thread safety improvements in processor update flow

### Phase 9: Apple Watch Companion (Jun 2025)

**4–6 Jun 2025**:
- WatchConnectivity implemented — phone → watch message-based streaming
- Measured latency between simulators: ~500ms (acceptable)
- Core metrics view (4 cells): depth, speed, heading, SOG
- Wind metrics view (6 cells): TWS, AWS, TWA, AWA, TWD, AWD
- `WatchSessionManager` as `@Observable` single source of truth, injected via `@Environment`
- `@MainActor` adopted for UI updates in NMEAParser (replacing `DispatchQueue.main.async{}`)
- Metric sending optimized: tuple array + for loop, delta-only via `DataCoordinator`
- Design philosophy: numbers only, no animations on watch — practical for helming

**7 Jun 2025**:
- Realized the NMEA simulator needs to be much better for proper testing without boat access
- Started planning a macOS NMEA simulator as a **separate project**
- Noted: background polling may conflict with Watch connectivity — needs investigation

### Phase 10: AI-Assisted Improvements (Mar 2026)

- First Cursor/AI session: codebase review, bug fixes, documentation
- Fixed 4 bugs: calibration coefficient type, Watch wind label, duplicate metric keys, thread-unsafe struct mutation
- Replaced `fatalError` with graceful error handling in VMGCalculator
- Replaced `freopen` file reading with `String(contentsOfFile:)`
- Created `.agent/` documentation folder with PROJECT, CHANGELOG, ROADMAP, CONVENTIONS, HISTORY, HARDWARE, LESSONS

### Phase 11: Polar surface, NMEA extensibility, iPad prep (Apr 2026)

- **Polar**: Live-TWS polar curve in-app (`VMGCalculator.polarBoatSpeedCurve`, `PolarDiagramCanvasView`); dedicated **Polar** tab/segment; caption-only layout (no nav title / legend) sized to fill the lower panel for reliable **`PageTabViewStyle`** swipes on iPhone.
- **iPhone paging fix**: Lower `TabView` no longer wrapped in a single **`NavigationStack`** (that blocked horizontal paging past Performance); **`NavigationStack`** only where **`NavigationLink`** is used (`UltimateView`).
- **`NMEASentenceProcessor`** protocol + registry tests; **`HydroProcessorTests`**; configurable **UI refresh** interval (Settings + parser).
- **Docs / Agent OS**: `agentos cache update && agentos handoff update && agentos export`; **ROADMAP** marks **iPad cockpit dashboard** as the next layout slice after iPhone polar stabilization.

---

## Cumulative Development Time

| Period | Estimated Hours |
|--------|----------------|
| Jul–Oct 2023 (Phase 1) | ~210 |
| Dec 2023 (Phase 2) | ~15 |
| Jan 2024 (Phases 3–4) | ~75 |
| Feb 2024 (Phase 5) | ~20 |
| Jun–Oct 2024 (Phase 6) | ~10 |
| Oct–Dec 2024 (Phase 7: MVVM) | ~80 |
| Dec 2024–Feb 2025 (Phase 8: Polish) | ~100 |
| Jun 2025 (Phase 9: Watch) | ~15 |
| Mar–Apr 2026 (Phase 10–11) | ~20 (estimate) |
| **Total** | **~545+ hours** |

---

## On-Boat Test Results

### Test 1 — 14 Oct 2023 (Falkor)
- GPS data: working
- NMEA parser: validated
- VTG sentence: not published by external GPS
- Overall: promising first test

### Hardware Test 1 — 16 Dec 2023
- NMEA box readable with Elimex adapter
- Level shifter cable swap fixed nanoPi reading
- WiFi broadcast: not working (investigation needed)
- Cable reliability: intermittent failures

### Hardware Test 2 — 19 Dec 2023
- Full NMEA data stream readable
- Non-functional: sea temperature, GPS (cables cut), speed log (rusty cables)
- Action items: Ivan to fix speed log cables, GPS cables

### Real-Environment Tests Still Needed
- Bearing to mark accuracy (many calculations depend on it)
- Compass and wind gauge behavior in real conditions
- Laylines in both wind mode and waypoint mode
- Sailing state detection accuracy
- Kalman filter fine-tuning (especially wind)

---

## Professional Development (v2.0 era)

Alongside the code rewrite, a learning track was established:

| Resource | Status |
|----------|--------|
| *A Philosophy of Software Design* (book) | ~70% read |
| Git/GitHub tutorials (Atlassian, GitHub Skills) | In progress |
| PyOpenSci — Python for Scientists | In progress |
| SEI Software Architecture course (V07, $500) | Evaluated |
| SEI Professional Certificate exam (V19, $150) | Passed (98%) |
| Software Architecture Document (SAD) template | Studied |

**Key architecture principles adopted**:
- Modules with interface + implementation: changing internals without changing the interface reduces complexity
- Start with general-purpose methods, specialize as needed
- Each function should do one thing completely
- If users need to read method code to use it, there's no abstraction — use comments and informational naming

---

## Key Decisions & Pivots

1. **MQTT → UDP**: Started with MQTT client, switched to raw UDP once the RPi broadcast setup was understood
2. **NWListener → CocoaAsyncSocket**: Apple's native networking couldn't handle continuous UDP reliably
3. **Apple Maps as navigation tool → display-only**: Maps too inaccurate for maritime use. All calculations moved to NMEA parser; map only shows positions
4. **Multiple Observable classes → single NMEAParser**: Failed to synchronize multiple observable objects. Consolidated to one source of truth
5. **JSON menus → SwiftData → AppStorage**: Display configuration moved from JSON to SwiftData, then simplified to `AppStorage` for cell configs
6. **Calculate true wind → read directly**: Discovered MWV alternates between true and apparent wind, can use sensor values directly
7. **Views compute → Views display**: Established principle that views should never contain calculation logic
8. **SwiftData for views → MVSU hybrid**: Strict MVVM impractical with `@Query` being view-only. Adopted a hybrid approach
9. **VMGProcessor → VMG + Waypoint split**: Polar speed/VMG always calculated; waypoint-specific data only when target selected
10. **Multiple DispatchQueue.main.async → cache-and-update**: Single main-thread update at end of parse cycle instead of per-processor
11. **SwiftData persistence → AppStorage**: Simpler, more reliable for display cell configurations
12. **Separate NMEA simulator project**: Real testing requires a sophisticated simulator — outgrew simple test scripts
