import MapKit
import Foundation

/// Single `MKTileOverlay` that implements the nautical-chart fallback chain:
///
/// 1. **User-downloaded MBTiles** (one per region in Documents) — instantaneous, fully offline.
/// 2. **Bundled MBTiles** (`nautical_charts.mbtiles` in app bundle, if present) — offline.
/// 3. **OpenSeaMap live** (`tiles.openseamap.org`) — transparent seamark PNG tiles
///    with a 100 MB URLCache disk tier, so previously-seen tiles survive offline.
/// 4. **Empty tile** — silent nil; Apple Maps base layer shows through.
///
/// `NauticalChartOverlay` re-evaluates available local files on each `init`, so
/// toggling the nautical layer off → on after a download completes picks up the new data.
final class NauticalChartOverlay: MKTileOverlay {

    /// `MKMapViewBridge` posts this notification after a download completes so the
    /// map can automatically reload the tile overlay with the new region.
    static let reloadNotification = Notification.Name("NauticalChartOverlay.reload")

    private let localOverlays: [MBTilesOverlay]   // downloaded regions
    private let openSeaMap:    OpenSeaMapTileOverlay

    init() {
        // Downloaded regions (Documents) + bundled fallback
        var local = MBTilesOverlay.allDownloaded()
        if local.isEmpty, let bundled = MBTilesOverlay.bundled() {
            local = [bundled]
        }
        localOverlays = local
        openSeaMap    = OpenSeaMapTileOverlay()

        super.init(urlTemplate: nil)
        canReplaceMapContent = false    // transparent overlay — Apple Maps shows through
        maximumZ = 18
        minimumZ = 3
    }

    override func loadTile(at path: MKTileOverlayPath,
                           result: @escaping (Data?, Error?) -> Void) {
        // Try each local overlay in sequence; fall through to live tiles on a miss.
        tryLocal(index: 0, path: path, result: result)
    }

    // MARK: - Recursive local fallback

    private func tryLocal(index: Int,
                           path: MKTileOverlayPath,
                           result: @escaping (Data?, Error?) -> Void) {
        guard index < localOverlays.count else {
            // All local sources exhausted → try OpenSeaMap live
            openSeaMap.loadTile(at: path, result: result)
            return
        }
        localOverlays[index].loadTile(at: path) { [weak self] data, _ in
            if let data {
                result(data, nil)
            } else {
                self?.tryLocal(index: index + 1, path: path, result: result)
            }
        }
    }
}
