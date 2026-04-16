import SwiftUI
import SwiftData
import MapKit
import CoreLocation

/// Top-left chrome on iPad only (`MapView` is full-screen on iPhone; no leading control there).
enum MapIPadLeadingControl: Equatable {
    /// Pushed from Ultimate: arrow pops the pushed map.
    case dismissBack
    /// Dashboard map (`iPadView`): gear opens **Settings** inside the map column (metrics column stays visible).
    case settingsLink
}

struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(SettingsManager.self) private var settingsManager
    @Environment(\.dismiss) private var dismiss // Allows going back to the previous view
    @Query private var waypoints: [Waypoints]
    @Namespace var mapScope

    /// iPad-only; default keeps the back arrow when the map is pushed from Ultimate.
    var iPadLeadingControl: MapIPadLeadingControl = .dismissBack

    /// iPad dashboard (`.settingsLink`): show settings **inside the map column** so cockpit metrics stay visible.
    @State private var iPadDashboardSettingsPresented = false

    @State private var animatedBoatLocation: CLLocationCoordinate2D?
    @State private var animatedStarboardLayline: CLLocationCoordinate2D?
    @State private var animatedPortsideLayline: CLLocationCoordinate2D?
    @State private var animatedHeading: Double = 0.0
    @State private var animatedTWD: Double = 0.0
    @State private var targetBoatLocation: CLLocationCoordinate2D?
    @State private var targetStarboardLayline: CLLocationCoordinate2D?
    @State private var targetPortsideLayline: CLLocationCoordinate2D?
    @State private var targetHeading: Double = 0.0
    @State private var targetTWD: Double = 0.0
    @State private var smoothingTimer: Timer?
    @State private var mapCameraPosition: MapCameraPosition = .automatic

    @AppStorage("savedCenterLat") private var savedCenterLat: Double = .nan
    @AppStorage("savedCenterLon") private var savedCenterLon: Double = .nan
    @AppStorage("savedZoomLevel") private var savedZoomLevel: Double = 200000

    @State private var allowSave = false // To prevent premature saving

    @State private var starboardIntersection: CLLocationCoordinate2D?
    @State private var portsideIntersection: CLLocationCoordinate2D?
    
    private var boatLocationKey: String {
        let lat = navigationReadings.gpsData?.boatLocation?.latitude ?? .nan
        let lon = navigationReadings.gpsData?.boatLocation?.longitude ?? .nan
        return "\(lat),\(lon)"
    }
    
    private var headingKey: Double {
        navigationReadings.gpsData?.courseOverGround ?? .nan
    }
    
    private var windDirectionKey: Double {
        navigationReadings.windData?.trueWindDirection ?? .nan
    }
    
    private var laylineKey: String {
        let stbdLat = navigationReadings.vmgData?.starboardLayline?.latitude ?? .nan
        let stbdLon = navigationReadings.vmgData?.starboardLayline?.longitude ?? .nan
        let portLat = navigationReadings.vmgData?.portsideLayline?.latitude ?? .nan
        let portLon = navigationReadings.vmgData?.portsideLayline?.longitude ?? .nan
        return "\(stbdLat),\(stbdLon),\(portLat),\(portLon)"
    }
    
    private var intersectionKey: String {
        let stbdLat = navigationReadings.waypointData?.starboardIntersection?.intersection.latitude ?? .nan
        let stbdLon = navigationReadings.waypointData?.starboardIntersection?.intersection.longitude ?? .nan
        let portLat = navigationReadings.waypointData?.portsideIntersection?.intersection.latitude ?? .nan
        let portLon = navigationReadings.waypointData?.portsideIntersection?.intersection.longitude ?? .nan
        return "\(stbdLat),\(stbdLon),\(portLat),\(portLon)"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            
            MapReader { reader in
                
                // Main Map with rounded corners
                Map(position: $mapCameraPosition, interactionModes: [.pan, .zoom], scope: mapScope, content: {
                    boatAnnotation() // Boat a=][nnotation with animation
                    waypointAnnotations()
                    if navigationReadings.gpsData?.isTargetSelected == true {
                        laylinePolylinesToWaypoint() // Show laylines to waypoint
                        intersectionAnnotations()
                    }
                    if settingsManager.isWindModeActive {
                        laylinePolylines(opacity: navigationReadings.gpsData?.isTargetSelected == true ? 0.4 : 1.0) // Wind mode laylines with adjusted opacity
                    }
                })
                .onAppear {
                    allowSave = false

                    if !savedCenterLat.isNaN, !savedCenterLon.isNaN {
                        let lastPosition = CLLocationCoordinate2D(latitude: savedCenterLat, longitude: savedCenterLon)
                        mapCameraPosition = .camera(MapCamera(centerCoordinate: lastPosition, distance: savedZoomLevel))
                        allowSave = true
                    } else if let boatLocation = navigationReadings.gpsData?.boatLocation {
                        mapCameraPosition = .camera(MapCamera(centerCoordinate: boatLocation, distance: savedZoomLevel))
                        savedCenterLat = boatLocation.latitude
                        savedCenterLon = boatLocation.longitude
                        allowSave = true
                    }
                    // If no saved position and no GPS yet, map defaults to .automatic

                    syncAnimatedState()
                    startSmoothingTimer()
                }
                .onDisappear {
                    // Save the map position on disappearance if allowed
                    if allowSave {
                        if let camera = mapCameraPosition.camera {
                            savedCenterLat = camera.centerCoordinate.latitude
                            savedCenterLon = camera.centerCoordinate.longitude
                            savedZoomLevel = camera.distance
                        }
                    }
                    stopSmoothingTimer()
                }
                .onMapCameraChange { context in
                    guard allowSave else { return }

                    let newCenter = context.camera.centerCoordinate
                    let newDistance = context.camera.distance

                    savedCenterLat = newCenter.latitude
                    savedCenterLon = newCenter.longitude
                    savedZoomLevel = newDistance

                    debugLog("Updated map position: Lat \(savedCenterLat), Lon \(savedCenterLon), Zoom \(savedZoomLevel)")
                }

                .onChange(of: navigationReadings.gpsData?.boatLocation?.latitude) {
                    if !allowSave, let boatLocation = navigationReadings.gpsData?.boatLocation {
                        withAnimation(.easeInOut(duration: 1)) {
                            mapCameraPosition = .camera(MapCamera(centerCoordinate: boatLocation, distance: savedZoomLevel))
                        }
                        savedCenterLat = boatLocation.latitude
                        savedCenterLon = boatLocation.longitude
                        allowSave = true
                    }
                }
                .onChange(of: boatLocationKey) {
                    updateBoatLocation()
                }
                .onChange(of: headingKey) {
                    updateHeading()
                }
                .onChange(of: windDirectionKey) {
                    updateWindDirection()
                }
                .onChange(of: laylineKey) {
                    updateLaylines()
                }
                .onChange(of: intersectionKey) {
                    updateIntersections()
                }
                // User taps and waypoint is being created
                .gesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            if let pinLocation = reader.convert(value.location, from: .local) {
                                addWaypoint(at: pinLocation)
                            }
                        }
                )
            }
            
            .mapStyle(.standard(elevation: .flat))
            .mapControls() {
                MapCompass(scope: mapScope).mapControlVisibility(.hidden)
                
            }
            
            // iPad — top left: back (pushed map) or settings (dashboard map)
            if DeviceType.isIPad {
                VStack {
                    switch iPadLeadingControl {
                    case .dismissBack:
                        Button(action: { dismiss() }) {
                            IconButton(systemName: "arrow.backward", color: Color.blue.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    case .settingsLink:
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                iPadDashboardSettingsPresented.toggle()
                            }
                        } label: {
                            MapGearChromeLabel()
                        }
                        .buttonStyle(.plain)
                        .zIndex(3)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .safeAreaPadding([.top, .leading])
            }

            // Floating pill toolbar — bottom center
            HStack(spacing: 0) {
                // Center on boat
                Button(action: centerBoat) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 52, height: 44)
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(width: 1, height: 24)
                    .background(Color.white.opacity(0.3))

                // Wind mode toggle
                Button(action: {
                    settingsManager.isWindModeActive.toggle()
                    if settingsManager.isWindModeActive { updateLaylines() }
                }) {
                    Image(systemName: settingsManager.isWindModeActive ? "wind.circle.fill" : "wind")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(settingsManager.isWindModeActive ? Color.green : .white)
                        .frame(width: 52, height: 44)
                }
                .buttonStyle(.plain)

                if navigationReadings.gpsData?.isTargetSelected == true {
                    Divider()
                        .frame(width: 1, height: 24)
                        .background(Color.white.opacity(0.3))

                    // Zoom to fit boat + waypoint
                    Button(action: adjustZoomLevel) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 52, height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
            .safeAreaPadding(.bottom)

            // In-map settings (dashboard only): occupies this view’s bounds — does not cover Ultimate / Multi.
            if DeviceType.isIPad, iPadLeadingControl == .settingsLink, iPadDashboardSettingsPresented {
                MapDashboardSettingsInMapColumn(
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            iPadDashboardSettingsPresented = false
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .opacity))
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: iPadDashboardSettingsPresented)
        .navigationBarHidden(true)
    }
    
    // Center the map on the boat's current location
    private func centerBoat() {
        
        if let boatLocation = navigationReadings.gpsData?.boatLocation {
            withAnimation(.easeInOut(duration: 1)) {
                mapCameraPosition = .camera(MapCamera(centerCoordinate: boatLocation, distance: savedZoomLevel))
            }
        }
    }
    
    private func syncAnimatedState() {
        updateBoatLocation()
        updateHeading()
        updateWindDirection()
        updateLaylines()
        animatedBoatLocation = targetBoatLocation
        animatedStarboardLayline = targetStarboardLayline
        animatedPortsideLayline = targetPortsideLayline
        animatedHeading = targetHeading
        animatedTWD = targetTWD
        updateIntersections()
    }
    
    private func updateBoatLocation() {
        targetBoatLocation = navigationReadings.gpsData?.boatLocation
    }
    
    private func updateHeading() {
        if let newCOG = navigationReadings.gpsData?.courseOverGround {
            targetHeading = newCOG
        }
    }
    
    private func updateWindDirection() {
        if let newTWD = navigationReadings.windData?.trueWindDirection {
            targetTWD = newTWD
        }
    }
    
    // Update wind-mode layline endpoints.
    private func updateLaylines() {
        targetStarboardLayline = navigationReadings.vmgData?.starboardLayline
        targetPortsideLayline  = navigationReadings.vmgData?.portsideLayline
    }

    // Update waypoint tack intersection dots.
    /// No implicit animation — small coordinate jitter every frame was restarting a 1s ease,
    /// which fought `MapPolyline` updates and read as flashing on the layline bundle.
    private func updateIntersections() {
        starboardIntersection = navigationReadings.waypointData?.starboardIntersection?.intersection
        portsideIntersection = navigationReadings.waypointData?.portsideIntersection?.intersection
    }
    
    private func startSmoothingTimer() {
        smoothingTimer?.invalidate()
        smoothingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            advanceAnimatedState()
        }
    }
    
    private func stopSmoothingTimer() {
        smoothingTimer?.invalidate()
        smoothingTimer = nil
    }
    
    private func advanceAnimatedState() {
        animatedBoatLocation = interpolatedCoordinate(from: animatedBoatLocation, to: targetBoatLocation, factor: 0.18)
        animatedStarboardLayline = interpolatedCoordinate(from: animatedStarboardLayline, to: targetStarboardLayline, factor: 0.12)
        animatedPortsideLayline = interpolatedCoordinate(from: animatedPortsideLayline, to: targetPortsideLayline, factor: 0.12)
        animatedHeading = interpolatedAngle(from: animatedHeading, to: targetHeading, factor: 0.18)
        animatedTWD = interpolatedAngle(from: animatedTWD, to: targetTWD, factor: 0.10)
    }
    
    private func interpolatedCoordinate(
        from current: CLLocationCoordinate2D?,
        to target: CLLocationCoordinate2D?,
        factor: Double
    ) -> CLLocationCoordinate2D? {
        guard let target else { return nil }
        guard let current else { return target }
        
        let latDelta = target.latitude - current.latitude
        let lonDelta = target.longitude - current.longitude
        
        if abs(latDelta) < 0.000001, abs(lonDelta) < 0.000001 {
            return target
        }
        
        return CLLocationCoordinate2D(
            latitude: current.latitude + latDelta * factor,
            longitude: current.longitude + lonDelta * factor
        )
    }
    
    private func interpolatedAngle(from current: Double, to target: Double, factor: Double) -> Double {
        let delta = (target - current).truncatingRemainder(dividingBy: 360)
        let shortest = delta > 180 ? delta - 360 : (delta < -180 ? delta + 360 : delta)
        if abs(shortest) < 0.1 {
            return target
        }
        return current + shortest * factor
    }
    
    // MARK: - Dynamic Zoom Level
    private func adjustZoomLevel() {
        if navigationReadings.gpsData?.isTargetSelected == true,
           let boatLocation = navigationReadings.gpsData?.boatLocation,
           let waypointLocation = navigationReadings.gpsData?.waypointLocation {
            
            // Calculate the region spanning the boat and waypoint
            let latitudeDelta = abs(boatLocation.latitude - waypointLocation.latitude) * 1.5 // Add padding
            let longitudeDelta = abs(boatLocation.longitude - waypointLocation.longitude) * 1.5 // Add padding
            
            // Define the map span
            let span = MKCoordinateSpan(latitudeDelta: max(latitudeDelta, 0.01), longitudeDelta: max(longitudeDelta, 0.01)) // Minimum span
            
            // Calculate the center coordinate
            let centerLatitude = (boatLocation.latitude + waypointLocation.latitude) / 2
            let centerLongitude = (boatLocation.longitude + waypointLocation.longitude) / 2
            let centerCoordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
            
            // Update the camera position
            withAnimation(.easeInOut(duration: 1)) {
                mapCameraPosition = .region(MKCoordinateRegion(center: centerCoordinate, span: span))
            }
        }
    }
    
    // Add a new waypoint at the tapped location
    private func addWaypoint(at location: CLLocationCoordinate2D) {
        let newWaypoint = Waypoints(title: "Waypoint \(waypoints.count + 1)", lat: location.latitude, lon: location.longitude)
        modelContext.insert(newWaypoint)
        navigationReadings.selectWaypoint(at: location, name: newWaypoint.title)
    }
    
    
    @MapContentBuilder
    private func intersectionAnnotations() -> some MapContent {
        // Add starboard intersection annotation
        if let starboard = starboardIntersection {
            Annotation("", coordinate: starboard) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                
            }
        }
        
        // Add portside intersection annotation
        if let portside = portsideIntersection {
            Annotation("", coordinate: portside) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                
            }
        }
    }
    // Boat annotation — custom hull shape + wind arrow
    @MapContentBuilder
    private func boatAnnotation() -> some MapContent {
        if let boatLocation = animatedBoatLocation {
            Annotation("", coordinate: boatLocation) {
                ZStack {
                    // TWD wind arrow — teal arrowhead pointing downwind, with degree badge
                    WindDirectionArrow(twd: animatedTWD)

                    MapBoatMarker(heading: animatedHeading)

                    // Boat name label
                    Text(settingsManager.boatName)
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .offset(y: 36)
                }
            }
        }
    }
    
    
    // Annotations for selected waypoints
    @MapContentBuilder
    private func waypointAnnotations() -> some MapContent {
        if navigationReadings.gpsData?.isTargetSelected == true,
           let lat = navigationReadings.gpsData?.waypointLocation?.latitude,
           let lon = navigationReadings.gpsData?.waypointLocation?.longitude,
           let title = navigationReadings.gpsData?.waypointName {
            Annotation("", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                VStack(spacing: 4) {
                    // System image (pyramid) in orange
                    Image(systemName: "pyramid.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30) // Adjust the size as needed
                        .foregroundColor(.orange)
                    
                    // Waypoint name
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.black)
                        .padding(4)
                        .background(Color.white.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }
    
    // Laylines for wind mode with adjustable opacity
    @MapContentBuilder
    private func laylinePolylines(opacity: Double) -> some MapContent {
        if let boatLocation = animatedBoatLocation {
            if let sailingState = navigationReadings.vmgData?.sailingState {
                // Colors are swapped depending on the sailing state.
                // STBD gradient: green → teal  |  PORT gradient: red → purple
                // (matches the AnemometerView wind sector palette)
                // STBD: teal  |  PORT: purple — matching the anemometer sector end-colors.
                // (Screen-space LinearGradient on map polylines renders mostly one colour,
                //  so solid distinctive colours give the clearest visual match.)
                let stbdColor = Color.teal.opacity(opacity)
                let portColor = Color.purple.opacity(opacity)

                if sailingState == "Upwind" {
                    if let starboardLayline = animatedStarboardLayline {
                        MapPolyline(coordinates: [boatLocation, starboardLayline])
                            .stroke(stbdColor, lineWidth: 2)
                    }
                    if let portsideLayline = animatedPortsideLayline {
                        MapPolyline(coordinates: [boatLocation, portsideLayline])
                            .stroke(portColor, lineWidth: 2)
                    }
                } else {
                    if let starboardLayline = animatedStarboardLayline {
                        MapPolyline(coordinates: [boatLocation, starboardLayline])
                            .stroke(portColor, lineWidth: 2)
                    }
                    if let portsideLayline = animatedPortsideLayline {
                        MapPolyline(coordinates: [boatLocation, portsideLayline])
                            .stroke(stbdColor, lineWidth: 2)
                    }
                }
            }
        }
    }
    
    // MARK: - Layline to Waypoint
    //
    // Uses the same diamond geometry as `WaypointProcessor.generateDiamondLaylines`
    // (mark approach state + TWD + opt up/down TWA). Four infinite rays: two from the
    // boat, two from the mark, forming a parallelogram / “diamond” regardless of
    // whether the mark is upwind or downwind — avoids duplicating bearings in MapView.
    @MapContentBuilder
    private func laylinePolylinesToWaypoint() -> some MapContent {
        if let mark = navigationReadings.gpsData?.waypointLocation,
           let wp = navigationReadings.waypointData,
           let stbdBoat = wp.starboardLayline,
           let portBoat = wp.portsideLayline,
           let stbdMark = wp.extendedStarboardLayline,
           let portMark = wp.extendedPortsideLayline {

            // One boat vertex for the whole bundle — must match `Layline.start` from
            // `WaypointProcessor`, not `animatedBoatLocation`. Mixing smoothed icon position
            // with raw geometry made inner legs and outer rays diverge by a few metres each
            // frame → strobes / “flashing” on overlapping MapPolylines.
            let boat = stbdBoat.start

            let teal = Color.teal.opacity(0.85)
            let purple = Color.purple.opacity(0.85)

            // si = starboard-named tack point (on boat’s stbd ray + mark’s port extension).
            // pi = port-named tack point (on boat’s port ray + mark’s stbd extension).
            let si = wp.starboardIntersection?.intersection
            let pi = wp.portsideIntersection?.intersection

            // Trim infinite rays past the tack when the tail points *away* from the tactical
            // area (mark for boat rays, boat for mark rays). Stops long segments that look
            // like they run “behind” the boat or off into empty chart.
            let stbdBoatFar = trimmedLaylineFarEnd(
                anchor: stbdBoat.start, nominalFar: stbdBoat.end, lookToward: mark, intersection: si)
            let portBoatFar = trimmedLaylineFarEnd(
                anchor: portBoat.start, nominalFar: portBoat.end, lookToward: mark, intersection: pi)
            let stbdMarkFar = trimmedLaylineFarEnd(
                anchor: stbdMark.start, nominalFar: stbdMark.end, lookToward: boat, intersection: pi)
            let portMarkFar = trimmedLaylineFarEnd(
                anchor: portMark.start, nominalFar: portMark.end, lookToward: boat, intersection: si)

            MapPolyline(coordinates: [stbdMark.start, stbdMarkFar]).stroke(teal, lineWidth: 2.5)
            MapPolyline(coordinates: [portMark.start, portMarkFar]).stroke(purple, lineWidth: 2.5)

            if let sInt = si, let pInt = pi {
                // Boat-side thick rays: start **at the tack** so they do not redraw the same
                // segment as the white boat→tack legs + polygon edge (reduces flashing).
                MapPolyline(coordinates: boatLaylineOuterSegment(boat: boat, far: stbdBoatFar, tack: sInt))
                    .stroke(teal, lineWidth: 2.5)
                MapPolyline(coordinates: boatLaylineOuterSegment(boat: boat, far: portBoatFar, tack: pInt))
                    .stroke(purple, lineWidth: 2.5)

                // `MapPolygon` triangulation uses **map point** space. Lat/lon convexity disagreed
                // with that projection, so we sometimes fed a self‑intersecting quad → MapKit
                // “Triangulator failed…” / index mismatch spam. Skip fill when not a simple convex quad.
                if let corners = laylineDiamondFillPolygon(boat: boat, mark: mark, si: sInt, pi: pInt) {
                    MapPolygon(coordinates: corners)
                        .foregroundStyle(Color.white.opacity(0.16))
                        .stroke(Color.white.opacity(0), lineWidth: 0)
                }

                MapPolyline(coordinates: [boat, sInt])
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                MapPolyline(coordinates: [sInt, mark])
                    .stroke(purple.opacity(0.72), lineWidth: 1.5)

                MapPolyline(coordinates: [boat, pInt])
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                MapPolyline(coordinates: [pInt, mark])
                    .stroke(teal.opacity(0.72), lineWidth: 1.5)
            } else {
                MapPolyline(coordinates: [boat, stbdBoatFar]).stroke(teal, lineWidth: 2.5)
                MapPolyline(coordinates: [boat, portBoatFar]).stroke(purple, lineWidth: 2.5)
                MapPolyline(coordinates: [boat, mark])
                    .stroke(Color.yellow.opacity(0.55), lineWidth: 1.5)
            }
        }
    }

    /// Outer boat ray **from tack toward `far`**, or full **boat→far** if the tack is not
    /// on the forward segment (degenerate / partial geometry).
    private func boatLaylineOuterSegment(
        boat: CLLocationCoordinate2D,
        far: CLLocationCoordinate2D,
        tack: CLLocationCoordinate2D
    ) -> [CLLocationCoordinate2D] {
        let a = MKMapPoint(boat)
        let f = MKMapPoint(far)
        let t = MKMapPoint(tack)
        let vx = f.x - a.x
        let vy = f.y - a.y
        let len2 = vx * vx + vy * vy
        guard len2 > 1e-10 else { return [boat, far] }
        let invLen = 1.0 / sqrt(len2)
        let ux = vx * invLen
        let uy = vy * invLen
        let tTack = (t.x - a.x) * ux + (t.y - a.y) * uy
        let tFar = (f.x - a.x) * ux + (f.y - a.y) * uy
        if tTack > 1, tTack < tFar - 1 {
            return [tack, far]
        }
        return [boat, far]
    }

    /// Clips a layline past the tack when the segment from the tack toward `nominalFar`
    /// points away from `lookToward` (reduces misleading “runaway” rays on the map).
    private func trimmedLaylineFarEnd(
        anchor: CLLocationCoordinate2D,
        nominalFar: CLLocationCoordinate2D,
        lookToward: CLLocationCoordinate2D,
        intersection: CLLocationCoordinate2D?
    ) -> CLLocationCoordinate2D {
        guard let ix = intersection else { return nominalFar }
        let a = MKMapPoint(anchor)
        let f = MKMapPoint(nominalFar)
        let t = MKMapPoint(lookToward)
        let i = MKMapPoint(ix)
        let vx = f.x - a.x
        let vy = f.y - a.y
        let len2 = vx * vx + vy * vy
        guard len2 > 1e-10 else { return nominalFar }
        let invLen = 1.0 / sqrt(len2)
        let ux = vx * invLen
        let uy = vy * invLen
        let tI = (i.x - a.x) * ux + (i.y - a.y) * uy
        let tF = (f.x - a.x) * ux + (f.y - a.y) * uy
        guard tI >= 0, tI <= tF else { return nominalFar }
        let tailX = f.x - i.x
        let tailY = f.y - i.y
        let toX = t.x - i.x
        let toY = t.y - i.y
        if tailX * toX + tailY * toY >= 0 { return nominalFar }
        let margin = min(tF - tI, max(400.0, 0.08 * tI))
        let tShow = tI + margin
        return MKMapPoint(x: a.x + ux * tShow, y: a.y + uy * tShow).coordinate
    }

    /// Closed ring for the tactical diamond fill: **boat → starboard tack → mark → port tack**
    /// or the swapped tack order. Returns `nil` if corners are degenerate or not a simple convex
    /// quad in **map point** space (avoids feeding `MapPolygon` a bow‑tie / collapsed polygon).
    private func laylineDiamondFillPolygon(
        boat: CLLocationCoordinate2D,
        mark: CLLocationCoordinate2D,
        si: CLLocationCoordinate2D,
        pi: CLLocationCoordinate2D
    ) -> [CLLocationCoordinate2D]? {
        let ringA = [boat, si, mark, pi]
        let ringB = [boat, pi, mark, si]
        let minEdgeMeters: Double = 3
        if isConvexQuadMapPoints(ringA), laylineQuadMinEdgeMeters(ringA) >= minEdgeMeters { return ringA }
        if isConvexQuadMapPoints(ringB), laylineQuadMinEdgeMeters(ringB) >= minEdgeMeters { return ringB }
        return nil
    }

    private func laylineQuadMinEdgeMeters(_ v: [CLLocationCoordinate2D]) -> Double {
        guard v.count == 4 else { return 0 }
        var m = Double.greatestFiniteMagnitude
        for i in 0..<4 {
            let a = MKMapPoint(v[i])
            let b = MKMapPoint(v[(i + 1) % 4])
            m = min(m, a.distance(to: b))
        }
        return m
    }

    /// Convexity in `MKMapPoint` space — matches how MapKit tessellates `MapPolygon`.
    private func isConvexQuadMapPoints(_ v: [CLLocationCoordinate2D]) -> Bool {
        guard v.count == 4 else { return false }
        let p = v.map { MKMapPoint($0) }
        var span: Double = 0
        for pt in p {
            span = max(span, abs(pt.x), abs(pt.y))
        }
        let colinearEps = max(0.25, span * 1e-12)
        var nonZeroSign: Int?
        for i in 0..<4 {
            let p0 = p[i]
            let p1 = p[(i + 1) % 4]
            let p2 = p[(i + 2) % 4]
            let cross = (p1.x - p0.x) * (p2.y - p1.y) - (p1.y - p0.y) * (p2.x - p1.x)
            let s: Int
            if cross > colinearEps { s = 1 } else if cross < -colinearEps { s = -1 } else { continue }
            if let prev = nonZeroSign, prev != s { return false }
            nonZeroSign = s
        }
        return nonZeroSign != nil
    }

}

// MARK: - Dashboard settings panel (map column only)

private struct MapDashboardSettingsInMapColumn: View {
    var onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            NavigationStack {
                SettingsMenuView()
                    .toolbar {
                        // Trailing so it does not clash with Advanced’s leading “Settings” back control.
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done", action: onDismiss)
                        }
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

// MARK: - Gear control (same look as `NavigationButton` in `UltimateNavigationView`)

private struct MapGearChromeLabel: View {
    private let buttonSize: CGFloat = 40

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: buttonSize / 4)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.6), Color.black]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: buttonSize, height: buttonSize)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)

            Image(systemName: "gear")
                .foregroundColor(.white)
                .font(.system(size: buttonSize * 0.5, weight: .bold))
        }
    }
}

// Reusable minimalist icon button style
struct IconButton: View {
    let systemName: String
    let color: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 40, height: 40)
            Image(systemName: systemName)
                .foregroundColor(.white)
                .font(.system(size: 20))
        }
    }
}

extension CLLocationCoordinate2D {
    func midpoint(to coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lat1 = toRadians(self.latitude)
        let lon1 = toRadians(self.longitude)
        let lat2 = toRadians(coordinate.latitude)
        let lon2 = toRadians(coordinate.longitude)
        
        let dLon = lon2 - lon1
        let Bx = cos(lat2) * cos(dLon)
        let By = cos(lat2) * sin(dLon)
        
        let midLat = atan2(sin(lat1) + sin(lat2), sqrt((cos(lat1) + Bx) * (cos(lat1) + Bx) + By * By))
        let midLon = lon1 + atan2(By, cos(lat1) + Bx)
        
        return CLLocationCoordinate2D(latitude: toDegrees(midLat), longitude: toDegrees(midLon))
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Map Boat Marker
struct MapBoatMarker: View {
    let heading: Double
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 2, height: 40)
                .offset(y: -27)
                .shadow(color: .black.opacity(0.2), radius: 2)
                .rotationEffect(.degrees(heading))
            
            PseudoBoat()
                .stroke(Color.black.opacity(0.45), style: StrokeStyle(lineWidth: 6.5, lineCap: .round, lineJoin: .round))
                .frame(width: 20, height: 44)
                .scaleEffect(x: 0.72, y: 1.0)
                .rotationEffect(.degrees(heading))
            
            PseudoBoat()
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))
                .frame(width: 20, height: 44)
                .scaleEffect(x: 0.72, y: 1.0)
                .rotationEffect(.degrees(heading))
            
            Rectangle()
                .fill(Color.black.opacity(0.45))
                .frame(width: 10, height: 5)
                .offset(y: 20)
                .rotationEffect(.degrees(heading))
            
            Rectangle()
                .fill(Color.white)
                .frame(width: 6, height: 2.5)
                .offset(y: 20)
                .rotationEffect(.degrees(heading))
            
            Circle()
                .fill(Color.green.opacity(0.92))
                .frame(width: 5, height: 5)
                .offset(y: -22)
                .rotationEffect(.degrees(heading))
        }
        .frame(width: 44, height: 84)
    }
}

// MARK: - True Wind Direction arrow + badge
// The arrowhead points TOWARD the boat bow (showing wind arriving at the sails).
// The shaft extends upwind — acting as the tail of the arrow.
// Whole view is rotated by TWD so the tail always aligns with the wind origin.
struct WindDirectionArrow: View {
    let twd: Double

    private var displayTWD: Int {
        let d = twd.truncatingRemainder(dividingBy: 360)
        return Int(d < 0 ? d + 360 : d)
    }

    var body: some View {
        ZStack {
            // Shaft — extends upwind (tail)
            Rectangle()
                .fill(Color.teal.opacity(0.85))
                .frame(width: 2, height: 28)
                .offset(y: -44)          // top at −58, bottom at −30

            // Arrowhead — points downward toward the boat bow (y = −22)
            ArrowTip()
                .fill(Color.teal)
                .frame(width: 10, height: 8)
                .rotationEffect(.degrees(180)) // flip so tip faces down
                .offset(y: -26)          // bottom of frame at −22 = bow

            // TWD badge sits at the upwind end of the shaft
            Text("\(displayTWD)°")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(Color.teal.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .offset(y: -66)
        }
        .rotationEffect(.degrees(twd))
    }
}

private struct ArrowTip: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to:    CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        MapView()
            .environment(NMEAParser())
            .modelContainer(for: Waypoints.self)
    }
}

#Preview("Boat Marker") {
    ZStack {
        LinearGradient(colors: [Color.blue.opacity(0.35), Color.cyan.opacity(0.2)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        MapBoatMarker(heading: 37)
    }
    .frame(width: 160, height: 160)
}
