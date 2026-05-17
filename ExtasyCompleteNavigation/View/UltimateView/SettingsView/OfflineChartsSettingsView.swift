import SwiftUI

/// Settings screen for managing offline nautical chart regions.
/// Users can download, monitor progress, and delete region tile packages.
struct OfflineChartsSettingsView: View {

    @State private var seeder = TileSeeder()

    var body: some View {
        List {
            // How-to header
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Label("How it works", systemImage: "info.circle")
                        .font(.subheadline.bold())
                    Text(
                        "Downloading a region saves OpenSeaMap seamark tiles " +
                        "(buoys, depth contours, shipping lanes) to your device. " +
                        "Once downloaded, the chart layer works fully offline — " +
                        "even without cell coverage at sea."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            // Region rows
            Section(header: Text("Available Regions")) {
                ForEach(ChartRegion.all) { region in
                    RegionRow(region: region, seeder: seeder)
                }
            }

            // Tips
            Section(header: Text("Tips")) {
                tipRow(icon: "wifi.slash",
                       text: "Download over Wi-Fi — tile packages can be 50–200 MB.")
                tipRow(icon: "arrow.clockwise",
                       text: "Toggle the chart layer off/on after download to activate new tiles.")
                tipRow(icon: "map",
                       text: "Zoom levels 4–13 cover overview through harbour-approach detail. Useful content starts at z9+ near ports and marked channels.")
                tipRow(icon: "exclamationmark.circle",
                       text: "Only tiles with chart content are stored — open-sea areas with no buoys or marks will show 0 tiles stored, which is normal.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Offline Charts")
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 22)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Region row

private struct RegionRow: View {
    let region: ChartRegion
    let seeder: TileSeeder

    private var st: DownloadStatus { seeder.status(for: region) }
    private var isDownloaded:  Bool { seeder.isDownloaded(region) }
    private var isDownloading: Bool { st.isRunning }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title + action button
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(region.name)
                        .font(.headline)

                    // Subtitle changes based on state
                    Group {
                        if isDownloading {
                            Text("\(st.downloaded.formatted()) / ~\(region.estimatedTileCount.formatted()) tiles")
                        } else if isDownloaded {
                            downloadedSubtitle
                        } else if let err = st.errorMessage {
                            Text(err).foregroundStyle(.red)
                        } else {
                            Text("~\(region.estimatedTileCount.formatted()) tiles  ·  z\(region.zoomMin)–\(region.zoomMax)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.caption)
                }

                Spacer()

                actionButton
            }

            // Progress bar (only while downloading)
            if isDownloading {
                ProgressView(value: st.progress)
                    .tint(.cyan)
                    .animation(.linear(duration: 0.2), value: st.progress)
                Text("\(Int(st.progress * 100))%  ·  \(st.downloaded.formatted()) tiles written")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var downloadedSubtitle: some View {
        let count = seeder.storedTileCount(region) ?? 0
        let sizeStr = seeder.fileSizeString(region) ?? "?"

        if count == 0 {
            // File exists but no tiles were stored — region had no chart content
            Label {
                Text("No chart tiles stored — area may have no OpenSeaMap content at z\(region.zoomMin)–\(region.zoomMax). Try re-downloading or checking OpenSeaMap coverage for this region.")
                    .foregroundStyle(.orange)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
        } else {
            Text("\(sizeStr)  ·  \(count.formatted()) tiles  ·  z\(region.zoomMin)–\(region.zoomMax)  ·  Ready offline")
                .foregroundStyle(.green)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if isDownloading {
            Button(role: .destructive) {
                seeder.cancelDownload(region)
            } label: {
                Label("Cancel", systemImage: "xmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        } else if isDownloaded {
            Button(role: .destructive) {
                seeder.deleteRegion(region)
            } label: {
                Label("Delete", systemImage: "trash")
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        } else {
            Button {
                seeder.startDownload(region)
            } label: {
                Label("Download", systemImage: "arrow.down.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .foregroundStyle(.cyan)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OfflineChartsSettingsView()
    }
}
