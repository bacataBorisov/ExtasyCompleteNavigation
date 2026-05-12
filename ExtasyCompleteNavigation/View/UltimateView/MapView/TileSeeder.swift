import Foundation
import SQLite3
import Observation

// MARK: - Region definitions

struct ChartRegion: Identifiable, Sendable {
    let id:      String
    let name:    String
    let minLon:  Double
    let minLat:  Double
    let maxLon:  Double
    let maxLat:  Double
    let zoomMin: Int
    let zoomMax: Int

    /// All predefined sailing regions.
    static let all: [ChartRegion] = [blackSea, mediterranean]

    static let blackSea = ChartRegion(
        id: "black_sea", name: "Black Sea",
        minLon: 27.0,  minLat: 40.5,
        maxLon: 42.0,  maxLat: 47.0,
        zoomMin: 4, zoomMax: 13
    )
    static let mediterranean = ChartRegion(
        id: "mediterranean", name: "Mediterranean",
        minLon: -6.0,  minLat: 35.0,
        maxLon: 18.0,  maxLat: 48.0,
        zoomMin: 4, zoomMax: 12
    )

    /// Approximate tile count across all zoom levels.
    var estimatedTileCount: Int {
        (zoomMin...zoomMax).reduce(0) { sum, z in
            let (x0, y0) = lonLatToTileXY(lon: minLon, lat: maxLat, zoom: z)
            let (x1, y1) = lonLatToTileXY(lon: maxLon, lat: minLat, zoom: z)
            return sum + (abs(x1 - x0) + 1) * (abs(y1 - y0) + 1)
        }
    }

    /// URL for the local MBTiles file stored in the app's Documents directory.
    var localURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("nautical_\(id).mbtiles")
    }
}

// MARK: - Download status

struct DownloadStatus: Sendable {
    var isRunning:    Bool    = false
    var progress:     Double  = 0       // 0–1
    var downloaded:   Int     = 0
    var total:        Int     = 0
    var isCancelled:  Bool    = false
    var isComplete:   Bool    = false
    var errorMessage: String? = nil
}

// MARK: - TileSeeder

/// Downloads OpenSeaMap seamark tiles for one or more `ChartRegion`s and stores
/// them in an MBTiles SQLite file in the app's Documents directory.
///
/// Only non-empty tiles are saved (< 150 bytes → blank transparent PNG → skipped).
/// Concurrency is capped at 4 simultaneous HTTP requests so we don't hammer the server.
///
/// Notification `TileSeeder.didCompleteRegion` is posted when a region finishes
/// so `MKMapViewBridge` can reload the overlay without user action.
@Observable
@MainActor
final class TileSeeder {

    static let didCompleteRegion = Notification.Name("TileSeeder.didCompleteRegion")

    private(set) var statusByID: [String: DownloadStatus] = [:]
    private var cancellationByID: [String: Bool] = [:]
    private let maxConcurrent = 4

    // MARK: - Public API

    func status(for region: ChartRegion) -> DownloadStatus {
        statusByID[region.id] ?? DownloadStatus()
    }

    func isDownloaded(_ region: ChartRegion) -> Bool {
        FileManager.default.fileExists(atPath: region.localURL.path)
    }

    func fileSizeMB(_ region: ChartRegion) -> Double? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: region.localURL.path),
              let size = attrs[.size] as? Int64 else { return nil }
        return Double(size) / (1024 * 1024)
    }

    func deleteRegion(_ region: ChartRegion) {
        guard !isDownloading(region) else { return }
        try? FileManager.default.removeItem(at: region.localURL)
    }

    func isDownloading(_ region: ChartRegion) -> Bool {
        statusByID[region.id]?.isRunning == true
    }

    func cancelDownload(_ region: ChartRegion) {
        cancellationByID[region.id] = true
    }

    func startDownload(_ region: ChartRegion) {
        Task { await download(region) }
    }

    // MARK: - Download logic (nonisolated so it doesn't block the main actor)

    private func download(_ region: ChartRegion) async {
        let id = region.id
        await setStatus(id, DownloadStatus(
            isRunning: true,
            total: region.estimatedTileCount
        ))
        cancellationByID[id] = false

        // Open / create the MBTiles SQLite file
        guard let db = openDatabase(at: region.localURL, region: region) else {
            await setStatus(id, DownloadStatus(errorMessage: "Cannot open database"))
            return
        }
        defer { sqlite3_close(db) }

        let session = makeTileSession()
        var downloaded = 0
        var cancelled  = false

        // Commit every N tiles to avoid one giant transaction
        let batchSize = 500
        var batchCount = 0
        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil)

        let insertSQL = "INSERT OR REPLACE INTO tiles VALUES (?,?,?,?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK else {
            await setStatus(id, DownloadStatus(errorMessage: "Cannot prepare statement"))
            return
        }
        defer { sqlite3_finalize(stmt) }

        // Throttled concurrent downloads using a semaphore-style actor
        let throttle = ConcurrencyThrottle(limit: maxConcurrent)

        outerLoop:
        for z in region.zoomMin...region.zoomMax {
            let (x0, y0) = lonLatToTileXY(lon: region.minLon, lat: region.maxLat, zoom: z)
            let (x1, y1) = lonLatToTileXY(lon: region.maxLon, lat: region.minLat, zoom: z)
            let xs = min(x0, x1)...max(x0, x1)
            let ys = min(y0, y1)...max(y0, y1)

            for x in xs {
                for y in ys {
                    if await isCancelled(id) { cancelled = true; break outerLoop }

                    await throttle.acquire()
                    let tileURL = openSeaMapURL(z: z, x: x, y: y)

                    // Fetch asynchronously but write serially on caller
                    let data = await fetchTile(url: tileURL, session: session)
                    await throttle.release()

                    // Skip blank transparent tiles (< 150 bytes)
                    if let data, data.count >= 150 {
                        let tmsY = (1 << z) - 1 - y   // XYZ → TMS y
                        sqlite3_bind_int(stmt, 1, Int32(z))
                        sqlite3_bind_int(stmt, 2, Int32(x))
                        sqlite3_bind_int(stmt, 3, Int32(tmsY))
                        sqlite3_bind_blob(stmt, 4, (data as NSData).bytes, Int32(data.count), nil)
                        sqlite3_step(stmt)
                        sqlite3_reset(stmt)

                        batchCount += 1
                        if batchCount >= batchSize {
                            sqlite3_exec(db, "COMMIT", nil, nil, nil)
                            sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil)
                            batchCount = 0
                        }
                    }

                    downloaded += 1

                    // Update UI every 20 tiles
                    if downloaded % 20 == 0 {
                        let prog = Double(downloaded) / Double(region.estimatedTileCount)
                        await updateProgress(id: id, downloaded: downloaded, progress: prog)
                    }
                }
            }
        }

        sqlite3_exec(db, "COMMIT", nil, nil, nil)

        let finalStatus = DownloadStatus(
            isRunning:   false,
            progress:    cancelled ? (statusByID[id]?.progress ?? 0) : 1.0,
            downloaded:  downloaded,
            total:       region.estimatedTileCount,
            isCancelled: cancelled,
            isComplete:  !cancelled
        )
        await setStatus(id, finalStatus)

        if !cancelled {
            NotificationCenter.default.post(name: TileSeeder.didCompleteRegion,
                                            object: region.id)
        }
    }

    // MARK: - Helpers

    @MainActor
    private func setStatus(_ id: String, _ s: DownloadStatus) {
        statusByID[id] = s
    }

    @MainActor
    private func updateProgress(id: String, downloaded: Int, progress: Double) {
        statusByID[id]?.downloaded = downloaded
        statusByID[id]?.progress   = progress
    }

    @MainActor
    private func isCancelled(_ id: String) -> Bool {
        cancellationByID[id] == true
    }

    private func fetchTile(url: URL, session: URLSession) async -> Data? {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 8)
        return try? await session.data(for: request).0
    }

    private func openSeaMapURL(z: Int, x: Int, y: Int) -> URL {
        URL(string: "https://tiles.openseamap.org/seamark/\(z)/\(x)/\(y).png")!
    }

    private func makeTileSession() -> URLSession {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest  = 8
        cfg.timeoutIntervalForResource = 30
        cfg.httpMaximumConnectionsPerHost = maxConcurrent
        return URLSession(configuration: cfg)
    }

    private func openDatabase(at url: URL, region: ChartRegion) -> OpaquePointer? {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(url.path, &db, flags, nil) == SQLITE_OK,
              let db else { return nil }

        let schema = """
            PRAGMA journal_mode=WAL;
            CREATE TABLE IF NOT EXISTS metadata (name TEXT, value TEXT);
            CREATE TABLE IF NOT EXISTS tiles (
                zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER,
                tile_data BLOB
            );
            CREATE UNIQUE INDEX IF NOT EXISTS tile_index
                ON tiles (zoom_level, tile_column, tile_row);
            INSERT OR REPLACE INTO metadata VALUES ('name',        '\(region.name)');
            INSERT OR REPLACE INTO metadata VALUES ('type',        'overlay');
            INSERT OR REPLACE INTO metadata VALUES ('version',     '1.0');
            INSERT OR REPLACE INTO metadata VALUES ('description', 'OpenSeaMap seamark tiles');
            INSERT OR REPLACE INTO metadata VALUES ('format',      'png');
            INSERT OR REPLACE INTO metadata VALUES ('minzoom',     '\(region.zoomMin)');
            INSERT OR REPLACE INTO metadata VALUES ('maxzoom',     '\(region.zoomMax)');
            INSERT OR REPLACE INTO metadata VALUES (
                'bounds', '\(region.minLon),\(region.minLat),\(region.maxLon),\(region.maxLat)'
            );
            """
        sqlite3_exec(db, schema, nil, nil, nil)
        return db
    }
}

// MARK: - Concurrency throttle (caps simultaneous tasks)

/// Simple actor that limits how many tasks run concurrently, acting as a counting semaphore.
private actor ConcurrencyThrottle {
    private let limit: Int
    private var active = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(limit: Int) { self.limit = limit }

    func acquire() async {
        if active < limit { active += 1; return }
        await withCheckedContinuation { waiters.append($0) }
        active += 1
    }

    func release() {
        active -= 1
        if !waiters.isEmpty {
            let next = waiters.removeFirst()
            next.resume()
        }
    }
}

// MARK: - Tile coordinate math (XYZ / Slippy Map convention)

/// Converts (longitude, latitude) to the tile (x, y) at a given zoom level.
/// Uses the standard Slippy Map / XYZ convention (y = 0 at the top).
func lonLatToTileXY(lon: Double, lat: Double, zoom: Int) -> (x: Int, y: Int) {
    let n    = 1 << zoom
    let nD   = Double(n)
    let x    = Int((lon + 180.0) / 360.0 * nD)
    let latR = lat * .pi / 180.0
    let y    = Int((1.0 - log(tan(latR) + 1.0 / cos(latR)) / .pi) / 2.0 * nD)
    return (max(0, min(x, n - 1)), max(0, min(y, n - 1)))
}
