import SwiftUI
import CoreLocation

/// Waypoint / VMC summary for the iPad lower strip — flat chrome to match `PerformanceView`.
struct VMGSimpleView: View {
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(SettingsManager.self) private var settingsManager
    var waypointName: String

    var body: some View {
        GeometryReader { geo in
            let m = StripMetrics(size: geo.size)

            VStack(alignment: .leading, spacing: 0) {
                headerRow(metrics: m)

                Divider().padding(.vertical, m.dividerPad)

                metricsRow(metrics: m)

                Divider().padding(.vertical, m.dividerPad)

                tackPairRow(metrics: m)

                if navigationReadings.waypointData?.isVMCNegative == true {
                    Text("Moving away from waypoint")
                        .font(.system(size: m.warningFont, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, m.warningVerticalPad)
                        .padding(.horizontal, 8)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.red.opacity(0.85)))
                        .padding(.top, m.sectionGap)
                }

                Spacer(minLength: 0)
            }
            .padding(m.edgePad)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(Color(UIColor.systemBackground))
    }

    private func headerRow(metrics m: StripMetrics) -> some View {
        HStack(spacing: m.headerSpacing) {
            NavigationLink(destination: WaypointListView()) {
                Image(systemName: "list.bullet")
                    .font(.system(size: m.headerIcon, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: m.headerChrome, height: m.headerChrome)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(waypointName)
                .font(.system(size: m.headerTitle, weight: .semibold))
                .foregroundStyle(Color("display_font"))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity)

            Button(action: deselectWaypoint) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: m.closeIcon))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func metricsRow(metrics m: StripMetrics) -> some View {
        HStack(alignment: .top, spacing: m.metricsColumnGap) {
            stripMetric(
                title: "DTM",
                value: "\(settingsManager.formatDistance(meters: navigationReadings.waypointData?.distanceToMark ?? 0)) \(settingsManager.distanceAbbreviation)",
                metrics: m
            )
            stripMetric(
                title: "Trip",
                value: formatTripDuration(navigationReadings.waypointData?.tripDurationToWaypoint),
                metrics: m
            )
            stripMetric(
                title: "ETA",
                value: formatETA(navigationReadings.waypointData?.etaToWaypoint),
                metrics: m
            )
        }
    }

    private func tackPairRow(metrics m: StripMetrics) -> some View {
        HStack(alignment: .top, spacing: m.tackColumnGap) {
            tackStrip(
                stateLabel: navigationReadings.vmgData?.sailingState ?? "—",
                distanceNM: navigationReadings.waypointData?.tackDistance ?? 0,
                duration: navigationReadings.waypointData?.tackDuration,
                metrics: m
            )
            tackStrip(
                stateLabel: navigationReadings.waypointData?.oppositeTackState ?? "—",
                distanceNM: navigationReadings.waypointData?.distanceOnOppositeTack ?? 0,
                duration: navigationReadings.waypointData?.tripDurationOnOppositeTack,
                metrics: m
            )
        }
    }

    private func stripMetric(title: String, value: String, metrics m: StripMetrics) -> some View {
        VStack(spacing: m.metricTitleValueGap) {
            Text(title.uppercased())
                .font(.system(size: m.metricLabel, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)

            Text(value)
                .font(.system(size: m.metricValue, weight: .bold, design: .rounded))
                .foregroundStyle(Color("display_font"))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private func tackStrip(stateLabel: String, distanceNM: Double, duration: Double?, metrics m: StripMetrics) -> some View {
        VStack(alignment: .leading, spacing: m.tackStateToDetailGap) {
            Text(stateLabel)
                .font(.system(size: m.tackState, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            VStack(alignment: .leading, spacing: m.tackLineGap) {
                Label {
                    Text("\(settingsManager.formatDistanceFromNM(distanceNM)) \(settingsManager.distanceAbbreviation)")
                        .font(.system(size: m.tackDetail, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                } icon: {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: m.tackIcon, weight: .medium))
                }
                .labelStyle(.titleAndIcon)
                .foregroundStyle(Color("display_font"))

                Label {
                    Text(formatTripDuration(duration))
                        .font(.system(size: m.tackDetail, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                } icon: {
                    Image(systemName: "timer")
                        .font(.system(size: m.tackIcon, weight: .medium))
                }
                .labelStyle(.titleAndIcon)
                .foregroundStyle(Color("display_font"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatTripDuration(_ eta: Double?) -> String {
        guard let eta = eta, eta.isFinite, eta >= 0 else { return "—" }
        let totalSeconds = Int(eta * 3600)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }

    private func formatETA(_ eta: Date?) -> String {
        guard let eta = eta else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: eta)
    }

    private func deselectWaypoint() {
        navigationReadings.deselectWaypoint()
    }
}

// MARK: - Geometry-derived sizes (fills strip; avoids tiny type + large empty bands)

private struct StripMetrics {
    let edgePad: CGFloat
    let dividerPad: CGFloat
    let sectionGap: CGFloat
    let headerSpacing: CGFloat
    let headerChrome: CGFloat
    let headerIcon: CGFloat
    let closeIcon: CGFloat
    let headerTitle: CGFloat
    let metricsColumnGap: CGFloat
    let metricTitleValueGap: CGFloat
    let metricLabel: CGFloat
    let metricValue: CGFloat
    let tackColumnGap: CGFloat
    let tackStateToDetailGap: CGFloat
    let tackLineGap: CGFloat
    let tackState: CGFloat
    let tackDetail: CGFloat
    let tackIcon: CGFloat
    let warningFont: CGFloat
    let warningVerticalPad: CGFloat

    init(size: CGSize) {
        let w = max(size.width, 120)
        let h = max(size.height, 80)

        edgePad = max(6, min(14, w * 0.035))
        let innerW = w - edgePad * 2
        let innerH = h - edgePad * 2
        /// Slightly upsize type when the strip is tall so the block does not look underscaled.
        let vScale = min(1.22, max(1.0, innerH / 100))

        dividerPad = max(3, min(10, innerH * 0.045))
        sectionGap = max(4, innerH * 0.03)
        headerSpacing = max(6, innerW * 0.02)
        headerChrome = max(28, min(40, innerW * 0.1))
        headerIcon = max(15, headerChrome * 0.48)
        closeIcon = max(18, min(26, headerChrome * 0.62))
        headerTitle = max(14, min(22, innerW * 0.065))

        metricsColumnGap = max(4, innerW * 0.02)
        let colCount: CGFloat = 3
        let colW = max(40, (innerW - metricsColumnGap * (colCount - 1)) / colCount)
        metricTitleValueGap = max(2, innerH * 0.018)
        metricValue = min(32, max(15, colW * 0.22) * vScale)
        metricLabel = max(8, min(14, metricValue * 0.42))

        tackColumnGap = max(6, innerW * 0.025)
        let tackHalfW = max(50, (innerW - tackColumnGap) / 2)
        tackStateToDetailGap = max(3, innerH * 0.028)
        tackLineGap = max(2, innerH * 0.02)
        tackState = min(18, max(11, tackHalfW * 0.09) * vScale)
        tackDetail = min(19, max(10, tackHalfW * 0.095) * vScale)
        tackIcon = max(10, tackDetail * 0.92)

        warningFont = max(11, min(15, innerW * 0.035))
        warningVerticalPad = max(5, innerH * 0.035)
    }
}

#Preview {
    VMGSimpleView(waypointName: "Balchik")
        .environment(NMEAParser())
        .environment(SettingsManager())
        .frame(height: 220)
        .background(Color(.systemGroupedBackground))
}
