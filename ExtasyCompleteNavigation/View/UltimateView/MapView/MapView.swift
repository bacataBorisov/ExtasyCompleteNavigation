import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(SettingsManager.self) private var settingsManager
    @Environment(\.dismiss) private var dismiss // Allows going back to the previous view
    @Query private var waypoints: [Waypoints]
    @Namespace var mapScope
    
    @State private var animatedBoatLocation: CLLocationCoordinate2D?
    @State private var animatedStarboardLayline: CLLocationCoordinate2D?
    @State private var animatedPortsideLayline: CLLocationCoordinate2D?
    @State private var timer: Timer?
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    
    @State private var retryCount = 0
    private let maxRetryAttempts = 10
    
    @AppStorage("isMapInitialized") private var firstTimeMapInit: Bool = false // Persist zoom level
    @AppStorage("savedZoomLevel") private var savedZoomLevel: Double = 200000 // Persist zoom level
    @AppStorage("savedCenterLat") private var savedCenterLat: Double = 0.0
    @AppStorage("savedCenterLon") private var savedCenterLon: Double = 0.0
    @AppStorage("isPositionSet") private var isPositionSet: Bool = false

    
    @State private var allowZoomUpdate = false
    
    @State private var zoomLevel: Double = 200000
    @State private var lastSavedZoomLevel: Double = 200000
    
    @State private var starboardIntersection: CLLocationCoordinate2D?
    @State private var portsideIntersection: CLLocationCoordinate2D?
    
    @State private var isMapCentered = true // Track if the map is centered
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            MapReader { reader in
                
                // Main Map with rounded corners
                Map(position: $mapCameraPosition, scope: mapScope, content: {
                    boatAnnotation() // Boat a=][nnotation with animation
                    waypointAnnotations()
                    if navigationReadings.gpsData?.isTargetSelected == true && navigationReadings.waypointData?.isVMCNegative == false {
                        laylinePolylinesToWaypoint() // Show laylines to waypoint
                        intersectionAnnotations()
                    }
                    if settingsManager.isWindModeActive {
                        laylinePolylines(opacity: navigationReadings.gpsData?.isTargetSelected == true ? 0.4 : 1.0) // Wind mode laylines with adjusted opacity
                    }
                })
                .onMapCameraChange { context in
                    let newCenter = context.camera.centerCoordinate
                    let newDistance = context.camera.distance

                    // Save the center coordinates and zoom level only if they have changed significantly
                    let positionChanged = abs(newCenter.latitude - savedCenterLat) > 0.0001 ||
                                          abs(newCenter.longitude - savedCenterLon) > 0.0001
                    let zoomChanged = abs(newDistance - savedZoomLevel) > 100

                    if positionChanged || zoomChanged {
                        savedCenterLat = newCenter.latitude
                        savedCenterLon = newCenter.longitude
                        
                        if !firstTimeMapInit {
                            zoomLevel = 200000  // Set the default zoom level only on first init
                            firstTimeMapInit = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                allowZoomUpdate = true
                            }
                        } else if allowZoomUpdate {
                            zoomLevel = max(newDistance, 50000) // Prevent zoom from going too low
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if zoomLevel != lastSavedZoomLevel || positionChanged {
                                lastSavedZoomLevel = zoomLevel
                                savedZoomLevel = zoomLevel
                                debugLog("Updated map position: Lat \(savedCenterLat), Lon \(savedCenterLon), Zoom \(savedZoomLevel)")
                            }
                        }
                    }
                }
                // User taps and waypoint is being created
                .onTapGesture() { screenCoord in
                    if let pinLocation = reader.convert(screenCoord, from: .local) {
                        addWaypoint(at: pinLocation)
                    }
                }
            }
            
            .mapStyle(.standard(elevation: .flat))
            .mapControls() {
                MapCompass(scope: mapScope).mapControlVisibility(.hidden)
                
            }
            // extension is at the bottom of the file
            .if(DeviceType.isIPad) { view in
                view
                    .clipShape(RoundedRectangle(cornerRadius: 12)) // Round corners
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 2) // Optional border
                    )
                    .padding(8) // Extra padding for iPad
            }
            
            
            // Back Button in the top left corner
            if DeviceType.isIPad {
                VStack {
                    Button(action: {
                        dismiss() // Go back to the previous view
                    }) {
                        IconButton(systemName: "arrow.backward", color: Color.blue.opacity(0.8))
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 26)
                .padding(.top, 26)
            }
            
            
            // Controls in the top right corner
            VStack(spacing: 12) {
                // Center Boat Button
                Button(action: centerBoat) {
                    IconButton(systemName: "location.fill", color: Color.blue.opacity(0.8))
                }
                
                //                // Zoom Controls (HStack for + and -)
                //                HStack(spacing: 5) {
                //                    Button(action: zoomOut) {
                //                        IconButton(systemName: "minus.magnifyingglass", color: Color.gray.opacity(0.8))
                //                    }
                //                    Button(action: zoomIn) {
                //                        IconButton(systemName: "plus.magnifyingglass", color: Color.gray.opacity(0.8))
                //                    }
                //                }
                
                // Wind Mode Button (enabled even if waypoint is selected)
                Button(action: {
                    settingsManager.isWindModeActive.toggle()
                    if settingsManager.isWindModeActive {
                        updateLaylines() // Calculate laylines when toggled on
                    }
                }) {
                    IconButton(
                        systemName: settingsManager.isWindModeActive ? "wind.circle.fill" : "wind",
                        color: settingsManager.isWindModeActive ? Color.green.opacity(0.8) : Color.gray.opacity(0.8)
                    )
                }
                
                if navigationReadings.gpsData?.isTargetSelected == true {
                    // Center Boat and Waypoint in the Map
                    Button(action: {
                        adjustZoomLevel()
                    }) {
                        IconButton(
                            systemName: "rectangle.grid.2x2",
                            color: Color.gray.opacity(0.8)
                        )
                    }
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 26)
            .padding(.top, 26)
        }
        .onAppear {
            restoreZoomLevel()
            setupAnimationTimer() // Start the timer for periodic updates
            initializeMapView()
            
        }
        
        .onDisappear {
            saveZoomLevel()
            timer?.invalidate() // Stop the timer when the view disappears
            
        }
        .navigationBarHidden(true) // Hide the navigation bar
    }
    
    // Timer for periodic location updates
    private func setupAnimationTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            updateBoatLocation()
            updateLaylines() // Update laylines when toggled
            updateIntersections()
            
        }
    }
    
    // MARK: - Zoom Persistence
    private func saveZoomLevel() {
        savedZoomLevel = zoomLevel
        debugLog("Zoom level saved: \(savedZoomLevel)")
    }
    
    private func restoreZoomLevel() {
        zoomLevel = savedZoomLevel
        debugLog("Zoom level restored: \(zoomLevel)")
    }
    




    private func initializeMapView() {
        
        // Ensure we have valid GPS data before initializing the map
        guard let gpsData = navigationReadings.gpsData, gpsData.isGPSDataValid else {
            if retryCount < maxRetryAttempts {
                debugLog("Waiting for valid GPS data... Attempt \(retryCount + 1) of \(maxRetryAttempts)")
                
                // Retry initialization after a short delay if GPS data is not yet valid
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    retryCount += 1
                    initializeMapView()
                }
            } else {
                debugLog("Max retry attempts reached. Using last known or default map center.")
                fallbackToLastKnownOrDefaultLocation()
            }
            return
        }

        // Reset retry count upon successful GPS fix
        retryCount = 0

        // Check if saved map position is valid
        let isValidLat = savedCenterLat >= -90.0 && savedCenterLat <= 90.0
        let isValidLon = savedCenterLon >= -180.0 && savedCenterLon <= 180.0
        let isValidZoom = savedZoomLevel > 0.0 && savedZoomLevel < 5000000 // Reasonable zoom range

        if isPositionSet && isValidLat && isValidLon && isValidZoom {
            // Restore the last known position of the map
            let lastPosition = CLLocationCoordinate2D(latitude: savedCenterLat, longitude: savedCenterLon)
            mapCameraPosition = .camera(MapCamera(centerCoordinate: lastPosition, distance: savedZoomLevel))
            debugLog("Restored last known position: \(lastPosition.latitude), \(lastPosition.longitude) with zoom \(savedZoomLevel)")
        } else {
            if gpsData.isGPSDataValid, let boatLocation = gpsData.boatLocation {
                // If a valid GPS fix is available, center the map on the boat's position
                mapCameraPosition = .camera(MapCamera(centerCoordinate: boatLocation, distance: 200000))
                savedCenterLat = boatLocation.latitude
                savedCenterLon = boatLocation.longitude
                savedZoomLevel = 200000
                isPositionSet = true  // Mark position as set
                debugLog("Centered map on boat location with default zoom \(savedZoomLevel)")
            } else {
                fallbackToLastKnownOrDefaultLocation()
            }
        }
    }

    // Function to fallback to the last known position or default location
    private func fallbackToLastKnownOrDefaultLocation() {
        let isValidLastLat = savedCenterLat >= -90.0 && savedCenterLat <= 90.0
        let isValidLastLon = savedCenterLon >= -180.0 && savedCenterLon <= 180.0
        let isValidLastZoom = savedZoomLevel > 0.0 && savedZoomLevel < 5000000

        if isValidLastLat && isValidLastLon && isValidLastZoom {
            let lastKnownLocation = CLLocationCoordinate2D(latitude: savedCenterLat, longitude: savedCenterLon)
            mapCameraPosition = .camera(MapCamera(centerCoordinate: lastKnownLocation, distance: savedZoomLevel))
            debugLog("Using last known location: \(lastKnownLocation.latitude), \(lastKnownLocation.longitude) with zoom \(savedZoomLevel)")
        } else {
            let defaultLocation = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
            mapCameraPosition = .camera(MapCamera(centerCoordinate: defaultLocation, distance: 200000))
            savedCenterLat = 0.0
            savedCenterLon = 0.0
            savedZoomLevel = 200000
            debugLog("No valid last known location. Using default map center at 0.0, 0.0 with zoom \(savedZoomLevel)")
        }
    }
    
    
    // Center the map on the boat's current location
    private func centerBoat() {
        
        if let boatLocation = navigationReadings.gpsData?.boatLocation {
            withAnimation(.easeInOut(duration: 1)) {
                mapCameraPosition = .camera(MapCamera(centerCoordinate: boatLocation, distance: savedZoomLevel))
            }
        }
    }
    
    // Smoothly update boat location
    private func updateBoatLocation() {
        if let newLocation = navigationReadings.gpsData?.boatLocation {
            withAnimation(.easeInOut(duration: 1)) {
                animatedBoatLocation = newLocation
            }
        }
    }
    
    // Smoothly update laylines
    private func updateLaylines() {
        if let starboardLayline = navigationReadings.vmgData?.starboardLayline,
           let portsideLayline = navigationReadings.vmgData?.portsideLayline {
            withAnimation(.easeInOut(duration: 1)) {
                animatedStarboardLayline = starboardLayline
                animatedPortsideLayline = portsideLayline
            }
        }
    }
    
    // Smoothly update intersections
    private func updateIntersections() {
        if let newStarboardIntersection = navigationReadings.waypointData?.starboardIntersection?.intersection,
           let newPortsideIntersection = navigationReadings.waypointData?.portsideIntersection?.intersection {
            
            withAnimation(.easeInOut(duration: 1)) {
                starboardIntersection = newStarboardIntersection
                portsideIntersection = newPortsideIntersection
            }
        } else {
            // Handle case where one or both intersections are nil
            withAnimation(.easeInOut(duration: 1)) {
                starboardIntersection = navigationReadings.waypointData?.starboardIntersection?.intersection
                portsideIntersection = navigationReadings.waypointData?.portsideIntersection?.intersection
            }
        }
    }
    
    private func updateCameraPosition() {
        if let boatLocation = animatedBoatLocation {
            mapCameraPosition = .camera(MapCamera(centerCoordinate: boatLocation, distance: zoomLevel))
        }
    }
    
    // MARK: - Dynamic Zoom Level
    private func adjustZoomLevel() {
        if navigationReadings.gpsData?.isTargetSelected == true,
           let boatLocation = navigationReadings.gpsData?.boatLocation,
           let waypointLocation = navigationReadings.gpsData?.markerCoordinate {
            
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
        let newWaypoint = Waypoints(title: "Waypoint \(waypoints.count + 1)", lat: location.latitude, lon: location.longitude, isTargetSelected: true)
        
        // Save the waypoint in the database or state
        modelContext.insert(newWaypoint)
        
        // Immediately select it as the target
        navigationReadings.waypointProcessor.resetWaypointCalculations()
        navigationReadings.gpsProcessor.updateMarker(to: location, newWaypoint.title)
        navigationReadings.gpsData?.isTargetSelected = true
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
    //Boat annotation and surrounding elements
    @MapContentBuilder
    private func boatAnnotation() -> some MapContent {
        if let boatLocation = animatedBoatLocation {
            Annotation("", coordinate: boatLocation) { // Empty label for the system
                ZStack {
                    
                    // Circle around the boat
                    Circle()
                        .stroke(Color.yellow.opacity(0.5), lineWidth: 4)
                        .frame(width: 40, height: 40)
                    // True Wind Direction (TWD) Arrow
                    if let twa = navigationReadings.windData?.trueWindDirection {
                        Path { path in
                            path.move(to: CGPoint(x: 20, y: 20)) // Center of the circle
                            path.addLine(to: CGPoint(x: 20, y: -20)) // Arrow length
                        }
                        .stroke(Color.blue, lineWidth: 2) // Blue line for TWD
                        .rotationEffect(Angle(degrees: twa)) // Rotate based on TWD
                    }
                    
                    // Course Over Ground (COG) Arrow
                    if let cog = navigationReadings.gpsData?.courseOverGround {
                        Path { path in
                            path.move(to: CGPoint(x: 20, y: 20)) // Center of the circle
                            path.addLine(to: CGPoint(x: 20, y: -20)) // Arrow length
                        }
                        .stroke(Color.black, lineWidth: 2) // Black line for COG
                        .rotationEffect(Angle(degrees: cog)) // Rotate based on COG
                    }
                    
                    // Boat Icon
                    if let heading = navigationReadings.gpsData?.courseOverGround {
                        Image(systemName: "location.north.line")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40) // Matches circle size
                            .foregroundColor(Color.black) // Boat color
                            .rotationEffect(Angle(degrees: heading)) // Rotate based on heading
                            .animation(.easeInOut(duration: 0.5), value: heading) // Smooth animation
                    }
                    
                    
                    // Static "Boat" Label
                    Text("Extasy")
                        .font(.caption)
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .offset(y: 30) // Position below the boat
                }
            }
        }
    }
    
    
    // Annotations for selected waypoints
    @MapContentBuilder
    private func waypointAnnotations() -> some MapContent {
        if navigationReadings.gpsData?.isTargetSelected == true,
           let lat = navigationReadings.gpsData?.markerCoordinate?.latitude,
           let lon = navigationReadings.gpsData?.markerCoordinate?.longitude,
           let title = navigationReadings.gpsData?.markerName {
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
            // Starboard Layline
            if let sailingState =  navigationReadings.vmgData?.sailingState {
                
                
                //Colors are swapped depending on the sailing state
                // TODO: - write it in a better way, more elegant
                
                if sailingState == "Upwind" {
                    if let starboardLayline = animatedStarboardLayline {
                        
                        MapPolyline(coordinates: [boatLocation, starboardLayline])
                            .stroke(Color.green.opacity(opacity), lineWidth: 2)
                    }
                    
                    // Portside Layline
                    if let portsideLayline = animatedPortsideLayline {
                        MapPolyline(coordinates: [boatLocation, portsideLayline])
                            .stroke(Color.red.opacity(opacity), lineWidth: 2)
                    }
                } else {
                    if let starboardLayline = animatedStarboardLayline {
                        
                        MapPolyline(coordinates: [boatLocation, starboardLayline])
                            .stroke(Color.red.opacity(opacity), lineWidth: 2)
                    }
                    
                    // Portside Layline
                    if let portsideLayline = animatedPortsideLayline {
                        MapPolyline(coordinates: [boatLocation, portsideLayline])
                            .stroke(Color.green.opacity(opacity), lineWidth: 2)
                    }
                }
            }
        }
    }
    
    // MARK: - Layline to Waypoint
    @MapContentBuilder
    private func laylinePolylinesToWaypoint() -> some MapContent {
        if let boatLocation = animatedBoatLocation {
            // Starboard Layline
            if let starboardIntersection = starboardIntersection {
                MapPolyline(coordinates: [boatLocation, starboardIntersection])
                    .stroke(Color.purple.opacity(0.7), lineWidth: 2)
                
                if let waypointCoordinate = navigationReadings.gpsData?.markerCoordinate {
                    MapPolyline(coordinates: [starboardIntersection, waypointCoordinate])
                        .stroke(Color.orange.opacity(0.7), lineWidth: 2)
                }
            } else if let waypointCoordinate = navigationReadings.gpsData?.markerCoordinate {
                MapPolyline(coordinates: [boatLocation, waypointCoordinate])
                    .stroke(Color.yellow.opacity(0.7), lineWidth: 2)
            }
            
            // Portside Layline
            if let portsideIntersection = portsideIntersection {
                MapPolyline(coordinates: [boatLocation, portsideIntersection])
                    .stroke(Color.purple.opacity(0.7), lineWidth: 2)
                
                if let waypointCoordinate = navigationReadings.gpsData?.markerCoordinate {
                    MapPolyline(coordinates: [portsideIntersection, waypointCoordinate])
                        .stroke(Color.orange.opacity(0.7), lineWidth: 2)
                }
            } else if let waypointCoordinate = navigationReadings.gpsData?.markerCoordinate {
                MapPolyline(coordinates: [boatLocation, waypointCoordinate])
                    .stroke(Color.yellow.opacity(0.7), lineWidth: 2)
            }
        }
    }
}

struct Layline: Hashable {
    let start: CLLocationCoordinate2D
    let end: CLLocationCoordinate2D
    
    // Custom Equatable conformance
    static func == (lhs: Layline, rhs: Layline) -> Bool {
        return lhs.start.latitude == rhs.start.latitude &&
        lhs.start.longitude == rhs.start.longitude &&
        lhs.end.latitude == rhs.end.latitude &&
        lhs.end.longitude == rhs.end.longitude
    }
    
    // Custom Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(start.latitude)
        hasher.combine(start.longitude)
        hasher.combine(end.latitude)
        hasher.combine(end.longitude)
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

// MARK: - Preview
#Preview {
    NavigationStack {
        MapView()
            .environment(NMEAParser())
            .modelContainer(for: Waypoints.self)
    }
}
