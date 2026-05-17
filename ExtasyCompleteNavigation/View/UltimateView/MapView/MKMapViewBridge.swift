import SwiftUI
import MapKit
import CoreLocation

// MARK: - Annotation data models

/// Carries heading, TWD and boat name alongside the coordinate so the annotation
/// view can re-render the SwiftUI boat marker without accessing the environment.
final class BoatMapAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var heading: Double
    var twd: Double
    var boatName: String

    init(coordinate: CLLocationCoordinate2D,
         heading: Double, twd: Double, boatName: String) {
        self.coordinate = coordinate
        self.heading = heading
        self.twd = twd
        self.boatName = boatName
        super.init()
    }
}

final class WaypointMapAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var waypointName: String

    init(coordinate: CLLocationCoordinate2D, waypointName: String) {
        self.coordinate = coordinate
        self.waypointName = waypointName
        super.init()
    }
}

final class IntersectionMapAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}

// MARK: - Annotation views

private let kBoatReuseID         = "BoatAnnotation"
private let kWaypointReuseID     = "WaypointAnnotation"
private let kIntersectionReuseID = "IntersectionAnnotation"

/// Hosts the SwiftUI `MapBoatMarker` + `WindDirectionArrow` inside a UIKit annotation view.
/// The hosting controller is created once and its `rootView` is updated on reuse.
final class BoatAnnotationView: MKAnnotationView {
    private var hostVC: UIHostingController<AnyView>?

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        // Wide enough so boat names up to ~15 chars never clip; boat icon is still centred
        frame        = CGRect(x: 0, y: 0, width: 120, height: 84)
        centerOffset = .zero
        backgroundColor = .clear
        isOpaque        = false
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(annotation: BoatMapAnnotation) {
        let root = AnyView(
            ZStack {
                WindDirectionArrow(twd: annotation.twd)
                MapBoatMarker(heading: annotation.heading)
                Text(annotation.boatName)
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .offset(y: 36)
            }
            .frame(width: 120, height: 84)
        )
        if let vc = hostVC {
            vc.rootView = root
        } else {
            let vc = UIHostingController(rootView: root)
            vc.view.backgroundColor = .clear
            vc.view.frame           = bounds
            addSubview(vc.view)
            hostVC = vc
        }
    }
}

/// Hosts the SwiftUI waypoint pyramid + name label.
final class WaypointAnnotationView: MKAnnotationView {
    private var hostVC: UIHostingController<AnyView>?

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        // 160 px wide so waypoint names up to ~20 chars show in full on one line
        frame        = CGRect(x: 0, y: 0, width: 160, height: 64)
        centerOffset = CGPoint(x: 0, y: -32)   // anchor bottom-centre at coordinate
        backgroundColor = .clear
        isOpaque        = false
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(annotation: WaypointMapAnnotation) {
        let root = AnyView(
            VStack(spacing: 4) {
                Image(systemName: "pyramid.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.orange)
                Text(annotation.waypointName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.88))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        )
        if let vc = hostVC {
            vc.rootView = root
        } else {
            let vc = UIHostingController(rootView: root)
            vc.view.backgroundColor = .clear
            vc.view.frame           = bounds
            addSubview(vc.view)
            hostVC = vc
        }
    }
}

/// Small filled circle for tack-intersection dots.
final class IntersectionAnnotationView: MKAnnotationView {
    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame       = CGRect(x: 0, y: 0, width: 10, height: 10)
        centerOffset = .zero
        backgroundColor = .clear
        isOpaque        = false
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        UIColor.systemBlue.setFill()
        UIBezierPath(ovalIn: rect).fill()
    }
}

// MARK: - Polyline style tags

/// Each navigation polyline is tagged with a rendering style so the delegate
/// can look up colours/widths without subclassing `MKPolyline`.
enum BridgePolylineStyle {
    case headingLine
    case stbdWind(opacity: Double)
    case portWind(opacity: Double)
    case stbdMarkRay
    case portMarkRay
    case stbdBoatOuterRay
    case portBoatOuterRay
    case tackLeg           // white semi-transparent: boat → tack point
    case nextLegStbd       // teal: tack → mark (stbd side)
    case nextLegPort       // purple: tack → mark (port side)
    case directFallback    // yellow: boat → mark (no intersections)
}

// MARK: - MKMapViewBridge

/// `UIViewRepresentable` that owns an `MKMapView`.
/// Replaces the SwiftUI `Map(...)` block in `MapView.swift` to enable `MKTileOverlay`
/// support (OpenSeaMap / MBTiles) which SwiftUI's `Map` API does not expose.
///
/// All navigation data is passed as value-type inputs; the `Coordinator` holds the
/// mutable UIKit state and implements `MKMapViewDelegate`.
struct MKMapViewBridge: UIViewRepresentable {

    // MARK: Navigation overlays
    var boatLocation: CLLocationCoordinate2D?
    var heading: Double
    var twd: Double
    /// Wind-mode laylines (from VMGData).
    var starboardLayline: CLLocationCoordinate2D?
    var portsideLayline:  CLLocationCoordinate2D?
    /// Tack-intersection dots.
    var starboardIntersection: CLLocationCoordinate2D?
    var portsideIntersection:  CLLocationCoordinate2D?

    // MARK: Waypoint
    var waypointLocation: CLLocationCoordinate2D?
    var waypointName:     String?
    var isTargetSelected: Bool
    var waypointData:     WaypointData?

    // MARK: Sailing mode
    var isWindModeActive: Bool
    var sailingState:     String?

    // MARK: Display
    var boatName:          String
    var showNauticalLayer: Bool

    // MARK: Camera — programmatic changes only
    /// Set by the parent (`MapView`) when centering on the boat, adjusting zoom, or restoring
    /// a saved position.  Incremented `programmaticCameraVersion` tells the coordinator to
    /// apply the new camera even if the value itself hasn't changed.
    var programmaticCamera:        MKMapCamera?
    var programmaticCameraVersion: Int

    // MARK: Callbacks
    var onTap:              (CLLocationCoordinate2D) -> Void
    var onUserCameraChange: (CLLocationCoordinate2D, CLLocationDistance) -> Void

    // MARK: UIViewRepresentable

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate         = context.coordinator
        mapView.isRotateEnabled  = false
        mapView.isPitchEnabled   = false
        mapView.showsUserLocation = false
        mapView.mapType          = .standard

        mapView.register(BoatAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: kBoatReuseID)
        mapView.register(WaypointAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: kWaypointReuseID)
        mapView.register(IntersectionAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: kIntersectionReuseID)

        // Long-press to add waypoint (fires on .began so the mark appears while still holding)
        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.6   // 0.6 s feels deliberate without being sluggish
        longPress.delegate = context.coordinator
        mapView.addGestureRecognizer(longPress)

        // When a region finishes downloading, reload the tile overlay so the new
        // local tiles are used without requiring the user to toggle the layer off/on.
        context.coordinator.observeDownloadCompletion(mapView: mapView)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.update(mapView: mapView)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }
}

// MARK: - Coordinator

extension MKMapViewBridge {

    final class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {

        var parent: MKMapViewBridge

        // Camera tracking
        private var lastCameraVersion: Int = -1
        private var isProgrammaticChange   = false

        // Tile overlay (fallback chain: MBTiles → OpenSeaMap → silent empty)
        private var tileOverlay:        NauticalChartOverlay?
        private var nauticalLayerActive = false

        // Navigation overlays (rebuilt each update cycle at ~1 Hz)
        private var navPolylines: [MKPolyline] = []
        private var navPolygons:  [MKPolygon]  = []
        // Style lookup keyed on each polyline's ObjectIdentifier
        private var polylineStyles: [ObjectIdentifier: BridgePolylineStyle] = [:]

        // Persistent annotations (updated in place)
        private var boatAnnotation:  BoatMapAnnotation?
        private var wpAnnotation:    WaypointMapAnnotation?
        private var stbdAnnotation:  IntersectionMapAnnotation?
        private var portAnnotation:  IntersectionMapAnnotation?

        init(_ parent: MKMapViewBridge) { self.parent = parent }

        // MARK: - Download-completion reload

        /// Subscribes to `TileSeeder.didCompleteRegion` so the tile overlay is transparently
        /// swapped for a new `NauticalChartOverlay` (which picks up the downloaded file).
        func observeDownloadCompletion(mapView: MKMapView) {
            NotificationCenter.default.addObserver(
                forName: TileSeeder.didCompleteRegion,
                object: nil,
                queue: .main
            ) { [weak self, weak mapView] _ in
                guard let self, let mapView,
                      self.nauticalLayerActive else { return }
                // Remove the old overlay and add a fresh one that includes the new region.
                if let old = self.tileOverlay {
                    mapView.removeOverlay(old)
                }
                let fresh = NauticalChartOverlay()
                self.tileOverlay = fresh
                mapView.addOverlay(fresh, level: .aboveRoads)
            }
        }

        // MARK: - Main update entry point

        func update(mapView: MKMapView) {
            updateNauticalLayer(mapView: mapView)
            updateCamera(mapView: mapView)
            updateNavigationOverlays(mapView: mapView)
            updateAnnotations(mapView: mapView)
        }

        // MARK: - Tile overlay

        private func updateNauticalLayer(mapView: MKMapView) {
            if parent.showNauticalLayer, !nauticalLayerActive {
                let overlay = NauticalChartOverlay()
                tileOverlay = overlay
                mapView.addOverlay(overlay, level: .aboveRoads)
                nauticalLayerActive = true
            } else if !parent.showNauticalLayer, nauticalLayerActive,
                      let overlay = tileOverlay {
                mapView.removeOverlay(overlay)
                tileOverlay = nil
                nauticalLayerActive = false
            }
        }

        // MARK: - Camera

        private func updateCamera(mapView: MKMapView) {
            guard parent.programmaticCameraVersion != lastCameraVersion,
                  let camera = parent.programmaticCamera else { return }
            lastCameraVersion     = parent.programmaticCameraVersion
            isProgrammaticChange  = true
            mapView.setCamera(camera, animated: true)
        }

        // MARK: - Navigation overlays

        private func updateNavigationOverlays(mapView: MKMapView) {
            // Remove previous cycle's overlays
            for p in navPolylines { polylineStyles[ObjectIdentifier(p)] = nil }
            mapView.removeOverlays(navPolylines)
            mapView.removeOverlays(navPolygons)
            navPolylines.removeAll()
            navPolygons.removeAll()

            guard let boat = parent.boatLocation else { return }

            // COG heading line — 185 km so MapKit clips it at the screen edge
            if parent.heading.isFinite {
                let far = projectedCoordinate(from: boat,
                                              bearingDegrees: parent.heading,
                                              distanceMeters: 185_000)
                addPolyline([boat, far], style: .headingLine, to: mapView)
            }

            // Wind-mode laylines
            if parent.isWindModeActive {
                let opacity = parent.isTargetSelected ? 0.4 : 1.0
                let isUpwind = parent.sailingState == "Upwind"
                if let stbd = parent.starboardLayline {
                    addPolyline([boat, stbd],
                                style: isUpwind ? .stbdWind(opacity: opacity) : .portWind(opacity: opacity),
                                to: mapView)
                }
                if let port = parent.portsideLayline {
                    addPolyline([boat, port],
                                style: isUpwind ? .portWind(opacity: opacity) : .stbdWind(opacity: opacity),
                                to: mapView)
                }
            }

            // Tactical diamond laylines to the selected waypoint
            if parent.isTargetSelected,
               let mark  = parent.waypointLocation,
               let wp    = parent.waypointData,
               let stbdB = wp.starboardLayline,
               let portB = wp.portsideLayline,
               let stbdM = wp.extendedStarboardLayline,
               let portM = wp.extendedPortsideLayline {

                let anchor = stbdB.start
                let si     = parent.starboardIntersection
                let pi     = parent.portsideIntersection

                let stbdBFar = trimFarEnd(anchor: stbdB.start, far: stbdB.end, lookToward: mark, ix: si)
                let portBFar = trimFarEnd(anchor: portB.start, far: portB.end, lookToward: mark, ix: pi)
                let stbdMFar = trimFarEnd(anchor: stbdM.start, far: stbdM.end, lookToward: anchor, ix: pi)
                let portMFar = trimFarEnd(anchor: portM.start, far: portM.end, lookToward: anchor, ix: si)

                addPolyline([stbdM.start, stbdMFar], style: .stbdMarkRay, to: mapView)
                addPolyline([portM.start, portMFar], style: .portMarkRay, to: mapView)

                if let sInt = si, let pInt = pi {
                    addPolyline(outerBoatSegment(boat: anchor, far: stbdBFar, tack: sInt),
                                style: .stbdBoatOuterRay, to: mapView)
                    addPolyline(outerBoatSegment(boat: anchor, far: portBFar, tack: pInt),
                                style: .portBoatOuterRay, to: mapView)

                    if let corners = diamondFillPolygon(boat: anchor, mark: mark, si: sInt, pi: pInt) {
                        let poly = MKPolygon(coordinates: corners, count: corners.count)
                        mapView.addOverlay(poly, level: .aboveRoads)
                        navPolygons.append(poly)
                    }

                    // Inner tack legs
                    addPolyline([anchor, sInt], style: .tackLeg, to: mapView)
                    addPolyline([sInt,  mark],  style: .nextLegPort, to: mapView)
                    addPolyline([anchor, pInt], style: .tackLeg, to: mapView)
                    addPolyline([pInt,  mark],  style: .nextLegStbd, to: mapView)
                } else {
                    // No intersections — raw boat-side rays + direct line
                    addPolyline([anchor, stbdBFar], style: .stbdBoatOuterRay, to: mapView)
                    addPolyline([anchor, portBFar], style: .portBoatOuterRay, to: mapView)
                    addPolyline([anchor, mark],     style: .directFallback,   to: mapView)
                }
            }
        }

        private func addPolyline(_ coords: [CLLocationCoordinate2D],
                                  style: BridgePolylineStyle,
                                  to mapView: MKMapView) {
            var c = coords
            let poly = MKPolyline(coordinates: &c, count: c.count)
            polylineStyles[ObjectIdentifier(poly)] = style
            mapView.addOverlay(poly, level: .aboveRoads)
            navPolylines.append(poly)
        }

        // MARK: - Annotations

        private func updateAnnotations(mapView: MKMapView) {
            // Boat
            if let loc = parent.boatLocation {
                if let ann = boatAnnotation {
                    ann.coordinate = loc
                    ann.heading    = parent.heading
                    ann.twd        = parent.twd
                    ann.boatName   = parent.boatName
                    (mapView.view(for: ann) as? BoatAnnotationView)?.configure(annotation: ann)
                } else {
                    let ann = BoatMapAnnotation(coordinate: loc,
                                               heading: parent.heading,
                                               twd: parent.twd,
                                               boatName: parent.boatName)
                    boatAnnotation = ann
                    mapView.addAnnotation(ann)
                }
            } else if let ann = boatAnnotation {
                mapView.removeAnnotation(ann); boatAnnotation = nil
            }

            // Waypoint
            if parent.isTargetSelected,
               let loc  = parent.waypointLocation,
               let name = parent.waypointName {
                if let ann = wpAnnotation {
                    ann.coordinate   = loc
                    ann.waypointName = name
                    (mapView.view(for: ann) as? WaypointAnnotationView)?.configure(annotation: ann)
                } else {
                    let ann = WaypointMapAnnotation(coordinate: loc, waypointName: name)
                    wpAnnotation = ann
                    mapView.addAnnotation(ann)
                }
            } else if let ann = wpAnnotation {
                mapView.removeAnnotation(ann); wpAnnotation = nil
            }

            // Starboard intersection dot
            if parent.isTargetSelected, let loc = parent.starboardIntersection {
                if let ann = stbdAnnotation { ann.coordinate = loc }
                else {
                    let ann = IntersectionMapAnnotation(coordinate: loc)
                    stbdAnnotation = ann; mapView.addAnnotation(ann)
                }
            } else if let ann = stbdAnnotation {
                mapView.removeAnnotation(ann); stbdAnnotation = nil
            }

            // Portside intersection dot
            if parent.isTargetSelected, let loc = parent.portsideIntersection {
                if let ann = portAnnotation { ann.coordinate = loc }
                else {
                    let ann = IntersectionMapAnnotation(coordinate: loc)
                    portAnnotation = ann; mapView.addAnnotation(ann)
                }
            } else if let ann = portAnnotation {
                mapView.removeAnnotation(ann); portAnnotation = nil
            }
        }

        // MARK: - MKMapViewDelegate: renderers

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // Tile overlays (NauticalChartOverlay, OpenSeaMapTileOverlay, MBTilesOverlay)
            if let tileOverlay = overlay as? MKTileOverlay {
                return MKTileOverlayRenderer(tileOverlay: tileOverlay)
            }

            // Diamond fill
            if let polygon = overlay as? MKPolygon {
                let r = MKPolygonRenderer(polygon: polygon)
                r.fillColor   = UIColor.white.withAlphaComponent(0.16)
                r.strokeColor = UIColor.clear
                r.lineWidth   = 0
                return r
            }

            // Navigation polylines
            if let polyline = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: polyline)
                r.lineCap = .round
                switch polylineStyles[ObjectIdentifier(polyline)] {
                case .headingLine:
                    r.strokeColor = UIColor.white.withAlphaComponent(0.85); r.lineWidth = 1.5
                case .stbdWind(let o):
                    r.strokeColor = UIColor.systemTeal.withAlphaComponent(o); r.lineWidth = 2
                case .portWind(let o):
                    r.strokeColor = UIColor.purple.withAlphaComponent(o);    r.lineWidth = 2
                case .stbdMarkRay, .stbdBoatOuterRay:
                    r.strokeColor = UIColor.systemTeal.withAlphaComponent(0.85); r.lineWidth = 2.5
                case .portMarkRay, .portBoatOuterRay:
                    r.strokeColor = UIColor.purple.withAlphaComponent(0.85);     r.lineWidth = 2.5
                case .tackLeg:
                    r.strokeColor = UIColor.white.withAlphaComponent(0.5); r.lineWidth = 1.5
                case .nextLegStbd:
                    r.strokeColor = UIColor.systemTeal.withAlphaComponent(0.72); r.lineWidth = 1.5
                case .nextLegPort:
                    r.strokeColor = UIColor.purple.withAlphaComponent(0.72); r.lineWidth = 1.5
                case .directFallback:
                    r.strokeColor = UIColor.yellow.withAlphaComponent(0.55); r.lineWidth = 1.5
                case nil:
                    r.strokeColor = UIColor.gray; r.lineWidth = 1
                }
                return r
            }

            return MKOverlayRenderer(overlay: overlay)
        }

        // MARK: - MKMapViewDelegate: annotation views

        func mapView(_ mapView: MKMapView,
                     viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            if let ann = annotation as? BoatMapAnnotation {
                let v = mapView.dequeueReusableAnnotationView(
                    withIdentifier: kBoatReuseID, for: ann) as! BoatAnnotationView
                v.configure(annotation: ann)
                return v
            }
            if let ann = annotation as? WaypointMapAnnotation {
                let v = mapView.dequeueReusableAnnotationView(
                    withIdentifier: kWaypointReuseID, for: ann) as! WaypointAnnotationView
                v.configure(annotation: ann)
                return v
            }
            if annotation is IntersectionMapAnnotation {
                return mapView.dequeueReusableAnnotationView(
                    withIdentifier: kIntersectionReuseID, for: annotation)
            }
            return nil
        }

        // MARK: - MKMapViewDelegate: camera

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            if isProgrammaticChange { isProgrammaticChange = false; return }
            parent.onUserCameraChange(mapView.camera.centerCoordinate,
                                      mapView.camera.altitude)
        }

        // MARK: - Long-press gesture

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            // Fire once on .began — don't repeat if the user keeps holding.
            guard gesture.state == .began,
                  let mapView = gesture.view as? MKMapView else { return }
            let point      = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            // Haptic confirmation so the user feels the mark being placed.
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            parent.onTap(coordinate)
        }

        /// Allow the map's built-in pan/pinch gestures to coexist with the long-press recogniser.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            false
        }
    }
}

// MARK: - Layline geometry helpers (ported from MapView.swift, module-level)

/// Returns the outer segment of a boat-side layline ray:
/// `tack → far` when the tack lies on the forward segment; `boat → far` otherwise.
func outerBoatSegment(boat: CLLocationCoordinate2D,
                      far:  CLLocationCoordinate2D,
                      tack: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
    let a = MKMapPoint(boat), f = MKMapPoint(far), t = MKMapPoint(tack)
    let vx = f.x - a.x, vy = f.y - a.y
    let len2 = vx * vx + vy * vy
    guard len2 > 1e-10 else { return [boat, far] }
    let inv  = 1.0 / sqrt(len2)
    let ux = vx * inv, uy = vy * inv
    let tT = (t.x - a.x) * ux + (t.y - a.y) * uy
    let tF = (f.x - a.x) * ux + (f.y - a.y) * uy
    return (tT > 1 && tT < tF - 1) ? [tack, far] : [boat, far]
}

/// Clips a layline ray past the intersection toward the tactical area.
func trimFarEnd(anchor: CLLocationCoordinate2D,
                far:    CLLocationCoordinate2D,
                lookToward: CLLocationCoordinate2D,
                ix:     CLLocationCoordinate2D?) -> CLLocationCoordinate2D {
    guard let ix else { return far }
    let a = MKMapPoint(anchor), f = MKMapPoint(far)
    let t = MKMapPoint(lookToward), i = MKMapPoint(ix)
    let vx = f.x - a.x, vy = f.y - a.y
    let len2 = vx * vx + vy * vy
    guard len2 > 1e-10 else { return far }
    let inv = 1.0 / sqrt(len2)
    let ux = vx * inv, uy = vy * inv
    let tI = (i.x - a.x) * ux + (i.y - a.y) * uy
    let tF = (f.x - a.x) * ux + (f.y - a.y) * uy
    guard tI >= 0, tI <= tF else { return far }
    let tailX = f.x - i.x, tailY = f.y - i.y
    let toX   = t.x - i.x, toY   = t.y - i.y
    if tailX * toX + tailY * toY >= 0 { return far }
    let margin = min(tF - tI, max(400.0, 0.08 * tI))
    return MKMapPoint(x: a.x + ux * (tI + margin), y: a.y + uy * (tI + margin)).coordinate
}

/// Returns the four corner coordinates for the tactical diamond fill, or `nil` if
/// the quad is degenerate or not convex in map-point space.
func diamondFillPolygon(boat: CLLocationCoordinate2D,
                        mark: CLLocationCoordinate2D,
                        si:   CLLocationCoordinate2D,
                        pi:   CLLocationCoordinate2D) -> [CLLocationCoordinate2D]? {
    let ringA = [boat, si, mark, pi]
    let ringB = [boat, pi, mark, si]
    let minEdge = 3.0
    if isConvexQuad(ringA) && quadMinEdgeMeters(ringA) >= minEdge { return ringA }
    if isConvexQuad(ringB) && quadMinEdgeMeters(ringB) >= minEdge { return ringB }
    return nil
}

private func quadMinEdgeMeters(_ v: [CLLocationCoordinate2D]) -> Double {
    guard v.count == 4 else { return 0 }
    var m = Double.greatestFiniteMagnitude
    for i in 0..<4 {
        m = min(m, MKMapPoint(v[i]).distance(to: MKMapPoint(v[(i + 1) % 4])))
    }
    return m
}

private func isConvexQuad(_ v: [CLLocationCoordinate2D]) -> Bool {
    guard v.count == 4 else { return false }
    let p  = v.map { MKMapPoint($0) }
    var span = 0.0
    for pt in p { span = max(span, abs(pt.x), abs(pt.y)) }
    let eps = max(0.25, span * 1e-12)
    var sign: Int?
    for i in 0..<4 {
        let p0 = p[i], p1 = p[(i + 1) % 4], p2 = p[(i + 2) % 4]
        let cross = (p1.x - p0.x) * (p2.y - p1.y) - (p1.y - p0.y) * (p2.x - p1.x)
        let s: Int
        if cross > eps { s = 1 } else if cross < -eps { s = -1 } else { continue }
        if let prev = sign, prev != s { return false }
        sign = s
    }
    return sign != nil
}
