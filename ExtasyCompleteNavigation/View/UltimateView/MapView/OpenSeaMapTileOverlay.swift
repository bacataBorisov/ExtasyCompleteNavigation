import MapKit
import Foundation

/// `MKTileOverlay` that fetches transparent OpenSeaMap seamark tiles and caches them to disk.
/// Seamark tiles are PNGs with a clear background — only nautical symbols (buoys, depth
/// contours, shipping lanes) are rendered; the Apple Maps base layer shows through.
///
/// Cache strategy: `URLCache` with 100 MB disk quota.  Tiles already on disk are served
/// immediately without a network round-trip, giving basic offline support once an area has
/// been viewed online at least once.
final class OpenSeaMapTileOverlay: MKTileOverlay {

    private static let urlTemplate =
        "https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png"

    private let tileURLCache: URLCache = {
        URLCache(
            memoryCapacity: 10 * 1024 * 1024,   // 10 MB in-memory
            diskCapacity:  100 * 1024 * 1024,   // 100 MB on disk
            diskPath: "extasy_openseamap_tiles"
        )
    }()

    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.urlCache = tileURLCache
        // Serve cached tile immediately; fall through to network only on cache miss.
        cfg.requestCachePolicy = .returnCacheDataElseLoad
        cfg.timeoutIntervalForRequest = 8
        cfg.timeoutIntervalForResource = 15
        return URLSession(configuration: cfg)
    }()

    init() {
        super.init(urlTemplate: Self.urlTemplate)
        canReplaceMapContent = false    // transparent — do NOT hide the Apple Maps base
        maximumZ = 18
        minimumZ = 3
    }

    override func loadTile(at path: MKTileOverlayPath,
                           result: @escaping (Data?, Error?) -> Void) {
        let urlStr = Self.urlTemplate
            .replacingOccurrences(of: "{z}", with: "\(path.z)")
            .replacingOccurrences(of: "{x}", with: "\(path.x)")
            .replacingOccurrences(of: "{y}", with: "\(path.y)")

        guard let url = URL(string: urlStr) else { result(nil, nil); return }

        let request = URLRequest(url: url,
                                 cachePolicy: .returnCacheDataElseLoad,
                                 timeoutInterval: 8)

        let task = session.dataTask(with: request) { data, _, error in
            // On connectivity errors return nil silently — a blank tile is preferable to a crash.
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost,
                     .timedOut, .cannotConnectToHost:
                    result(nil, nil)
                default:
                    result(data, error)
                }
                return
            }
            result(data, error)
        }
        task.resume()
    }
}
