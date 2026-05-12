import MapKit
import Foundation

/// Single `MKTileOverlay` that implements the nautical-chart fallback chain:
///
/// 1. **MBTiles bundle** (`nautical_charts.mbtiles`) — instantaneous, fully offline.
/// 2. **OpenSeaMap live** (`tiles.openseamap.org`) — transparent seamark PNG tiles
///    with a 100 MB URLCache disk tier, so previously-seen tiles survive offline.
/// 3. **Empty tile** — silent nil; the Apple Maps base layer shows through.
///
/// Usage: add one instance of this overlay to the `MKMapView`; remove it when the
/// nautical layer is toggled off.  `MBTilesOverlay.bundled()` returns `nil` until the
/// `.mbtiles` file is added to the app bundle (Phase 2 hardware step), at which point
/// the bundled data automatically takes priority.
final class NauticalChartOverlay: MKTileOverlay {

    private let mbTiles:    MBTilesOverlay?       // nil until bundle is shipped
    private let openSeaMap: OpenSeaMapTileOverlay

    init() {
        mbTiles    = MBTilesOverlay.bundled()     // nil when file not yet bundled
        openSeaMap = OpenSeaMapTileOverlay()
        super.init(urlTemplate: nil)
        canReplaceMapContent = false              // transparent overlay
        maximumZ = 18
        minimumZ = 3
    }

    override func loadTile(at path: MKTileOverlayPath,
                           result: @escaping (Data?, Error?) -> Void) {
        // Step 1 — Try the bundled MBTiles (fast, offline, no network)
        if let mbTiles {
            mbTiles.loadTile(at: path) { [weak self] data, _ in
                if let data {
                    result(data, nil)   // served from bundle ✓
                    return
                }
                // Step 2 — fall through to OpenSeaMap (network + disk cache)
                self?.openSeaMap.loadTile(at: path, result: result)
            }
        } else {
            // No bundle yet — go straight to OpenSeaMap
            openSeaMap.loadTile(at: path, result: result)
        }
    }
}
