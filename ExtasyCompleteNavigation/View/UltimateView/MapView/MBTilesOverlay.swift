import MapKit
import SQLite3
import Foundation

/// `MKTileOverlay` that reads raster tiles from a bundled `.mbtiles` SQLite file.
///
/// MBTiles schema (standard):
/// ```sql
/// CREATE TABLE tiles (
///   zoom_level  INTEGER,
///   tile_column INTEGER,
///   tile_row    INTEGER,   -- TMS y-axis: 0 = bottom; flip to get XYZ y
///   tile_data   BLOB
/// );
/// ```
///
/// Usage: bundle `nautical_charts.mbtiles` in the app's **Resources** group (do NOT commit
/// the file to git — it can be 200–500 MB). `MBTilesOverlay` opens the file read-only on
/// a dedicated serial queue so tile requests never block the main thread.
///
/// In the fallback chain this overlay is tried first (fast, offline); on a miss the caller
/// falls through to `OpenSeaMapTileOverlay` (network + disk cache).
final class MBTilesOverlay: MKTileOverlay {

    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.extasy.mbtiles", qos: .userInitiated)

    // MARK: - Init / Deinit

    /// - Parameter mbtilesURL: URL to the `.mbtiles` file (usually in the app bundle).
    init?(mbtilesURL: URL) {
        // Verify the file exists before trying to open it.
        guard FileManager.default.fileExists(atPath: mbtilesURL.path) else {
            debugLog("MBTilesOverlay: file not found at \(mbtilesURL.path)")
            return nil
        }

        super.init(urlTemplate: nil)

        var dbPtr: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX
        guard sqlite3_open_v2(mbtilesURL.path, &dbPtr, flags, nil) == SQLITE_OK,
              let opened = dbPtr else {
            debugLog("MBTilesOverlay: failed to open SQLite database")
            return nil
        }
        db = opened
        canReplaceMapContent = false    // transparent PNG tiles
        maximumZ = 14
        minimumZ = 3
    }

    deinit {
        if let db { sqlite3_close(db) }
    }

    // MARK: - MKTileOverlay

    override func loadTile(at path: MKTileOverlayPath,
                           result: @escaping (Data?, Error?) -> Void) {
        queue.async { [weak self] in
            guard let self, let db = self.db else { result(nil, nil); return }

            // MBTiles uses TMS y (0 = bottom); MapKit uses XYZ y (0 = top).
            let tmsY = (1 << path.z) - 1 - path.y

            let sql = """
                SELECT tile_data FROM tiles
                WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?
                LIMIT 1
                """
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                result(nil, nil)
                return
            }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_int(stmt, 1, Int32(path.z))
            sqlite3_bind_int(stmt, 2, Int32(path.x))
            sqlite3_bind_int(stmt, 3, Int32(tmsY))

            if sqlite3_step(stmt) == SQLITE_ROW {
                let bytes = sqlite3_column_blob(stmt, 0)
                let count = sqlite3_column_bytes(stmt, 0)
                if let bytes, count > 0 {
                    let data = Data(bytes: bytes, count: Int(count))
                    result(data, nil)
                    return
                }
            }
            // Tile not in bundle — return nil so the caller can fall through to OpenSeaMap.
            result(nil, nil)
        }
    }
}

// MARK: - Factory helpers

extension MBTilesOverlay {

    /// Looks for `nautical_charts.mbtiles` in the main bundle.
    /// Returns `nil` if the file has not been added to Resources yet.
    static func bundled() -> MBTilesOverlay? {
        guard let url = Bundle.main.url(forResource: "nautical_charts",
                                        withExtension: "mbtiles") else {
            debugLog("MBTilesOverlay: nautical_charts.mbtiles not found in bundle")
            return nil
        }
        return MBTilesOverlay(mbtilesURL: url)
    }

    /// Returns one overlay per user-downloaded `nautical_*.mbtiles` file found in Documents.
    /// Called by `NauticalChartOverlay` at init time so newly downloaded regions are picked up
    /// automatically the next time the nautical layer is toggled on.
    static func allDownloaded() -> [MBTilesOverlay] {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let files = (try? FileManager.default.contentsOfDirectory(
            at: docs, includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "mbtiles" &&
                   $0.lastPathComponent.hasPrefix("nautical_") }) ?? []
        return files.compactMap { MBTilesOverlay(mbtilesURL: $0) }
    }
}
