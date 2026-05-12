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
    @Environment(\.dismiss) private var dismiss
    @Query private var waypoints: [Waypoints]

    /// iPad-only; default keeps the back arrow when the map is pushed from Ultimate.
    var iPadLeadingControl: MapIPadLeadingControl = .dismissBack

    /// iPad dashboard (`.settingsLink`): show settings inside the map column.
    @State private var iPadDashboardSettingsPresented = false

    // MARK: - Navigation overlay state (GPS-rate, ~1 Hz)

    @State private var targetBoatLocation:      CLLocationCoordinate2D?
    @State private var targetStarboardLayline:  CLLocationCoordinate2D?
    @State private var targetPortsideLayline:   CLLocationCoordinate2D?
    @State private var targetHeading:           Double = 0.0
    @State private var targetTWD:               Double = 0.0
    @State private var starboardIntersection:   CLLocationCoordinate2D?
    @State private var portsideIntersection:    CLLocationCoordinate2D?

    // MARK: - Camera (MKMapView, programmatic changes only)

    /// Set by `centerBoat()`, `adjustZoomLevel()`, or `onAppear`.
    /// Incrementing `programmaticCameraVersion` triggers the bridge to apply it.
    @State private var programmaticCamera:        MKMapCamera? = nil
    @State private var programmaticCameraVersion: Int          = 0

    // MARK: - Persistent camera position (AppStorage)

    @AppStorage("savedCenterLat")   private var savedCenterLat:  Double = .nan
    @AppStorage("savedCenterLon")   private var savedCenterLon:  Double = .nan
    @AppStorage("savedZoomLevel")   private var savedZoomLevel:  Double = 200_000
    @AppStorage("showNauticalLayer") private var showNauticalLayer: Bool = true

    @State private var allowSave = false  // prevents premature AppStorage writes

    // MARK: - Derived keys (used by onChange to detect GPS-rate updates)

    private var boatLocationKey: String {
        let lat = navigationReadings.gpsData?.boatLocation?.latitude  ?? .nan
        let lon = navigationReadings.gpsData?.boatLocation?.longitude ?? .nan
        return "\(lat),\(lon)"
    }
    private var headingKey: Double { navigationReadings.gpsData?.courseOverGround ?? .nan }
    private var windDirectionKey: Double { navigationReadings.windData?.trueWindDirection ?? .nan }
    private var laylineKey: String {
        let sl = navigationReadings.vmgData?.starboardLayline
        let pl = navigationReadings.vmgData?.portsideLayline
        return "\(sl?.latitude ?? .nan),\(sl?.longitude ?? .nan),\(pl?.latitude ?? .nan),\(pl?.longitude ?? .nan)"
    }
    private var intersectionKey: String {
        let s = navigationReadings.waypointData?.starboardIntersection?.intersection
        let p = navigationReadings.waypointData?.portsideIntersection?.intersection
        return "\(s?.latitude ?? .nan),\(s?.longitude ?? .nan),\(p?.latitude ?? .nan),\(p?.longitude ?? .nan)"
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {

            // MARK: Map bridge (replaces SwiftUI Map)
            MKMapViewBridge(
                boatLocation:          targetBoatLocation,
                heading:               targetHeading,
                twd:                   targetTWD,
                starboardLayline:      targetStarboardLayline,
                portsideLayline:       targetPortsideLayline,
                starboardIntersection: starboardIntersection,
                portsideIntersection:  portsideIntersection,
                waypointLocation:      navigationReadings.gpsData?.waypointLocation,
                waypointName:          navigationReadings.gpsData?.waypointName,
                isTargetSelected:      navigationReadings.gpsData?.isTargetSelected == true,
                waypointData:          navigationReadings.waypointData,
                isWindModeActive:      settingsManager.isWindModeActive,
                sailingState:          navigationReadings.vmgData?.sailingState,
                boatName:              settingsManager.boatName,
                showNauticalLayer:     showNauticalLayer,
                programmaticCamera:    programmaticCamera,
                programmaticCameraVersion: programmaticCameraVersion,
                onTap: { coordinate in
                    addWaypoint(at: coordinate)
                },
                onUserCameraChange: { center, distance in
                    guard allowSave else { return }
                    savedCenterLat = center.latitude
                    savedCenterLon = center.longitude
                    savedZoomLevel = distance
                }
            )
            .ignoresSafeArea()
            .onAppear {
                allowSave = false
                if !savedCenterLat.isNaN, !savedCenterLon.isNaN {
                    let pos = CLLocationCoordinate2D(latitude: savedCenterLat,
                                                     longitude: savedCenterLon)
                    programmaticCamera = MKMapCamera(lookingAtCenter: pos,
                                                     fromDistance: savedZoomLevel,
                                                     pitch: 0, heading: 0)
                    programmaticCameraVersion += 1
                    allowSave = true
                } else if let boat = navigationReadings.gpsData?.boatLocation {
                    programmaticCamera = MKMapCamera(lookingAtCenter: boat,
                                                     fromDistance: savedZoomLevel,
                                                     pitch: 0, heading: 0)
                    programmaticCameraVersion += 1
                    savedCenterLat = boat.latitude
                    savedCenterLon = boat.longitude
                    allowSave = true
                }
                syncTargetState()
            }
            // First GPS fix while no saved position
            .onChange(of: navigationReadings.gpsData?.boatLocation?.latitude) {
                if !allowSave, let boat = navigationReadings.gpsData?.boatLocation {
                    programmaticCamera = MKMapCamera(lookingAtCenter: boat,
                                                     fromDistance: savedZoomLevel,
                                                     pitch: 0, heading: 0)
                    programmaticCameraVersion += 1
                    savedCenterLat = boat.latitude
                    savedCenterLon = boat.longitude
                    allowSave = true
                }
            }
            .onChange(of: boatLocationKey)     { updateBoatLocation() }
            .onChange(of: headingKey)          { updateHeading() }
            .onChange(of: windDirectionKey)    { updateWindDirection() }
            .onChange(of: laylineKey)          { updateLaylines() }
            .onChange(of: intersectionKey)     { updateIntersections() }

            // MARK: iPad top-left chrome
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

            // MARK: Floating pill toolbar — bottom centre
            HStack(spacing: 0) {
                // Centre on boat
                Button(action: centerBoat) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 52, height: 44)
                }
                .buttonStyle(.plain)

                toolbarDivider

                // Wind-mode toggle
                Button(action: {
                    settingsManager.isWindModeActive.toggle()
                    if settingsManager.isWindModeActive { updateLaylines() }
                }) {
                    Image(systemName: settingsManager.isWindModeActive ? "wind.circle.fill" : "wind")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(settingsManager.isWindModeActive ? .green : .white)
                        .frame(width: 52, height: 44)
                }
                .buttonStyle(.plain)

                toolbarDivider

                // Nautical chart layer toggle
                Button(action: { showNauticalLayer.toggle() }) {
                    Image(systemName: showNauticalLayer ? "chart.bar.xaxis" : "chart.bar.xaxis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(showNauticalLayer ? .cyan : .white.opacity(0.5))
                        .frame(width: 52, height: 44)
                        .overlay(alignment: .topTrailing) {
                            if !showNauticalLayer {
                                Image(systemName: "line.diagonal")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red.opacity(0.8))
                                    .offset(x: 2, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)

                if navigationReadings.gpsData?.isTargetSelected == true {
                    toolbarDivider

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

            // MARK: In-map settings (dashboard only)
            if DeviceType.isIPad, iPadLeadingControl == .settingsLink,
               iPadDashboardSettingsPresented {
                MapDashboardSettingsInMapColumn(
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            iPadDashboardSettingsPresented = false
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal:   .opacity))
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: iPadDashboardSettingsPresented)
        .navigationBarHidden(true)
    }

    // MARK: - Toolbar helpers

    private var toolbarDivider: some View {
        Divider()
            .frame(width: 1, height: 24)
            .background(Color.white.opacity(0.3))
    }

    // MARK: - State sync helpers

    private func syncTargetState() {
        targetBoatLocation      = navigationReadings.gpsData?.boatLocation
        targetHeading           = navigationReadings.gpsData?.courseOverGround ?? 0
        targetTWD               = navigationReadings.windData?.trueWindDirection ?? 0
        targetStarboardLayline  = navigationReadings.vmgData?.starboardLayline
        targetPortsideLayline   = navigationReadings.vmgData?.portsideLayline
        updateIntersections()
    }

    private func updateBoatLocation() {
        targetBoatLocation = navigationReadings.gpsData?.boatLocation
    }

    private func updateHeading() {
        if let cog = navigationReadings.gpsData?.courseOverGround {
            withAnimation(.easeInOut(duration: 0.6)) { targetHeading = cog }
        }
    }

    private func updateWindDirection() {
        if let twd = navigationReadings.windData?.trueWindDirection {
            withAnimation(.easeInOut(duration: 0.6)) { targetTWD = twd }
        }
    }

    private func updateLaylines() {
        targetStarboardLayline = navigationReadings.vmgData?.starboardLayline
        targetPortsideLayline  = navigationReadings.vmgData?.portsideLayline
    }

    private func updateIntersections() {
        starboardIntersection = navigationReadings.waypointData?.starboardIntersection?.intersection
        portsideIntersection  = navigationReadings.waypointData?.portsideIntersection?.intersection
    }

    // MARK: - Actions

    private func centerBoat() {
        guard let boat = navigationReadings.gpsData?.boatLocation else { return }
        programmaticCamera = MKMapCamera(lookingAtCenter: boat,
                                         fromDistance: savedZoomLevel,
                                         pitch: 0, heading: 0)
        programmaticCameraVersion += 1
    }

    private func adjustZoomLevel() {
        guard navigationReadings.gpsData?.isTargetSelected == true,
              let boat     = navigationReadings.gpsData?.boatLocation,
              let waypoint = navigationReadings.gpsData?.waypointLocation else { return }

        let latDelta = abs(boat.latitude  - waypoint.latitude)  * 1.5
        let lonDelta = abs(boat.longitude - waypoint.longitude) * 1.5
        let center   = CLLocationCoordinate2D(
            latitude:  (boat.latitude  + waypoint.latitude)  / 2,
            longitude: (boat.longitude + waypoint.longitude) / 2
        )
        // Approximate altitude: 1° latitude ≈ 111 km; add view-angle factor
        let approxAltitude = max(latDelta, lonDelta) * 111_000 * 1.5
        let clamped = max(approxAltitude, 500)  // minimum sensible altitude

        programmaticCamera = MKMapCamera(lookingAtCenter: center,
                                         fromDistance: clamped,
                                         pitch: 0, heading: 0)
        programmaticCameraVersion += 1
    }

    private func addWaypoint(at location: CLLocationCoordinate2D) {
        let newWaypoint = Waypoints(title: "Waypoint \(waypoints.count + 1)",
                                   lat: location.latitude,
                                   lon: location.longitude)
        modelContext.insert(newWaypoint)
        navigationReadings.selectWaypoint(at: location, name: newWaypoint.title)
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
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done", action: onDismiss)
                        }
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

// MARK: - Gear control chrome

private struct MapGearChromeLabel: View {
    private let buttonSize: CGFloat = 40

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: buttonSize / 4)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.6), Color.black]),
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
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

// MARK: - Reusable icon button

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

// MARK: - CLLocationCoordinate2D midpoint helper

extension CLLocationCoordinate2D {
    func midpoint(to coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lat1 = toRadians(self.latitude),   lon1 = toRadians(self.longitude)
        let lat2 = toRadians(coordinate.latitude), lon2 = toRadians(coordinate.longitude)
        let dLon = lon2 - lon1
        let Bx   = cos(lat2) * cos(dLon)
        let By   = cos(lat2) * sin(dLon)
        let midLat = atan2(sin(lat1) + sin(lat2),
                           sqrt((cos(lat1) + Bx) * (cos(lat1) + Bx) + By * By))
        let midLon = lon1 + atan2(By, cos(lat1) + Bx)
        return CLLocationCoordinate2D(latitude: toDegrees(midLat),
                                      longitude: toDegrees(midLon))
    }
}

// MARK: - Conditional view modifier

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool,
                              transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Map Boat Marker
struct MapBoatMarker: View {
    let heading: Double

    var body: some View {
        ZStack {
            PseudoBoat()
                .stroke(Color.black.opacity(0.45),
                        style: StrokeStyle(lineWidth: 6.5, lineCap: .round, lineJoin: .round))
                .frame(width: 20, height: 44)
                .scaleEffect(x: 0.72, y: 1.0)
                .rotationEffect(.degrees(heading))

            PseudoBoat()
                .stroke(Color.white,
                        style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))
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
struct WindDirectionArrow: View {
    let twd: Double

    private var displayTWD: Int {
        let d = twd.truncatingRemainder(dividingBy: 360)
        return Int(d < 0 ? d + 360 : d)
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.teal.opacity(0.85))
                .frame(width: 2, height: 28)
                .offset(y: -44)

            ArrowTip()
                .fill(Color.teal)
                .frame(width: 10, height: 8)
                .rotationEffect(.degrees(180))
                .offset(y: -26)

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
        LinearGradient(colors: [Color.blue.opacity(0.35), Color.cyan.opacity(0.2)],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        MapBoatMarker(heading: 37)
    }
    .frame(width: 160, height: 160)
}
