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

                tackPairRowCompact(metrics: m)

                if let directH = navigationReadings.waypointData?.directDownwindDuration {
                    Divider().padding(.vertical, m.dividerPad)
                    downwindAdvisorRow(
                        directHours: directH,
                        gybeHours: navigationReadings.waypointData?.gybePathDuration,
                        deltaHours: navigationReadings.waypointData?.downwindTimeDeltaHours,
                        metrics: m
                    )
                }

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

            }
            .padding(.horizontal, m.edgePad)
            .padding(.bottom, m.edgePad)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(Color(UIColor.systemBackground))
    }

    private func headerRow(metrics m: StripMetrics) -> some View {
        HStack(alignment: .center, spacing: m.headerSpacing) {
            NavigationLink(destination: WaypointListView()) {
                Image(systemName: "list.bullet")
                    .font(.system(size: m.headerIcon, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: m.headerRowHeight, height: m.headerRowHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(waypointName)
                .font(.system(size: m.headerTitle, weight: .semibold))
                .foregroundStyle(Color("display_font"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: m.headerRowHeight, alignment: .leading)

            Button(action: deselectWaypoint) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: m.closeIcon))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .frame(width: m.headerRowHeight, height: m.headerRowHeight)
        }
        .frame(height: m.headerRowHeight, alignment: .center)
    }

    private func metricsRow(metrics m: StripMetrics) -> some View {
        HStack(alignment: .top, spacing: m.metricsColumnGap) {
            stripMetricLeading(
                title: "DTM",
                value: "\(settingsManager.formatDistance(meters: navigationReadings.waypointData?.distanceToMark ?? 0)) \(settingsManager.distanceAbbreviation)",
                metrics: m
            )
            .frame(width: m.metricColumnMaxWidth, alignment: .leading)

            stripMetricLeading(
                title: "Trip",
                value: formatTripDuration(navigationReadings.waypointData?.tripDurationToWaypoint),
                metrics: m
            )
            .frame(width: m.metricColumnMaxWidth, alignment: .leading)

            stripMetricLeading(
                title: "ETA",
                value: formatETA(navigationReadings.waypointData?.etaToWaypoint),
                metrics: m
            )
            .frame(width: m.metricColumnMaxWidth, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// One **distance · time** line per tack column (was two icon rows) so the strip does not clip.
    private func tackPairRowCompact(metrics m: StripMetrics) -> some View {
        HStack(alignment: .top, spacing: m.tackColumnGap) {
            tackLegColumn(
                title: navigationReadings.vmgData?.sailingState ?? "—",
                distanceNM: navigationReadings.waypointData?.tackDistance ?? 0,
                duration: navigationReadings.waypointData?.tackDuration,
                metrics: m
            )
            tackLegColumn(
                title: navigationReadings.waypointData?.oppositeTackState ?? "—",
                distanceNM: navigationReadings.waypointData?.distanceOnOppositeTack ?? 0,
                duration: navigationReadings.waypointData?.tripDurationOnOppositeTack,
                metrics: m
            )
        }
    }

    private func tackLegColumn(title: String, distanceNM: Double, duration: Double?, metrics m: StripMetrics) -> some View {
        VStack(alignment: .leading, spacing: m.tackStateToDetailGap) {
            Text(title)
                .font(.system(size: m.tackState, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text("\(settingsManager.formatDistanceFromNM(distanceNM)) \(settingsManager.distanceAbbreviation) · \(formatTripDuration(duration))")
                .font(.system(size: m.tackDetail, weight: .semibold, design: .rounded))
                .foregroundStyle(Color("display_font"))
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Leading-aligned metric block (packed from the start of the row with `Spacer` after).
    private func stripMetricLeading(title: String, value: String, metrics m: StripMetrics) -> some View {
        VStack(alignment: .leading, spacing: m.metricTitleValueGap) {
            Text(title.uppercased())
                .font(.system(size: m.metricLabel, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(value)
                .font(.system(size: m.metricValue, weight: .bold, design: .rounded))
                .foregroundStyle(Color("display_font"))
                .lineLimit(1)
                .minimumScaleFactor(m.metricValueMinScale)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatTripDuration(_ hours: Double?) -> String {
        guard let h = hours, h.isFinite, h >= 0 else { return "—" }
        let total = Int(h * 3600)
        let days  = total / 86400
        let hh    = (total % 86400) / 3600
        let mm    = (total % 3600) / 60
        return days > 0
            ? String(format: "%dd %02d:%02d", days, hh, mm)
            : String(format: "%02d:%02d", hh, mm)
    }

    private func formatETA(_ eta: Date?) -> String {
        guard let eta else { return "—" }
        let hours = eta.timeIntervalSince(Date()) / 3600
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = hours <= 24 ? "HH:mm" : "d MMM HH:mm"
        return f.string(from: eta)
    }

    /// Compact one-line downwind path advisor: Direct hh:mm  vs  Gybe hh:mm  (±delta)
    /// Faster option is highlighted in `.cyan`; slower is `.secondary`.
    private func downwindAdvisorRow(
        directHours: Double,
        gybeHours: Double?,
        deltaHours: Double?,
        metrics m: StripMetrics
    ) -> some View {
        let directFaster = (deltaHours ?? 0) < 0  // negative delta → direct is faster
        let directColor: Color = (gybeHours != nil && directFaster) ? .cyan : .secondary
        let gybeColor:   Color = (gybeHours != nil && !directFaster) ? .cyan : .secondary

        return HStack(spacing: 4) {
            Text("Direct")
                .foregroundStyle(.secondary)
            Text(formatTripDuration(directHours))
                .foregroundStyle(directColor)
                .fontWeight(directFaster ? .bold : .regular)

            Text("vs")
                .foregroundStyle(.tertiary)

            if let g = gybeHours {
                Text("Gybe")
                    .foregroundStyle(.secondary)
                Text(formatTripDuration(g))
                    .foregroundStyle(gybeColor)
                    .fontWeight(!directFaster ? .bold : .regular)
            } else {
                Text("Gybe —")
                    .foregroundStyle(.tertiary)
            }

            if let delta = deltaHours {
                Text(formatAdvisorDelta(delta))
                    .foregroundStyle(directFaster ? Color.cyan.opacity(0.8) : Color.orange.opacity(0.8))
            }
        }
        .font(.system(size: m.tackDetail, weight: .regular, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// e.g. −45 min delta → "save 45m"; +1.3 h delta → "gybe saves 1h 18m"
    private func formatAdvisorDelta(_ deltaHours: Double) -> String {
        let absSecs = Int(abs(deltaHours) * 3600)
        let h = absSecs / 3600
        let m = (absSecs % 3600) / 60
        let timeStr = h > 0 ? "\(h)h \(m)m" : "\(m)m"
        return deltaHours < 0 ? "save \(timeStr)" : "+\(timeStr)"
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
    /// One row height for list / title / close — icons centered with the title cap height.
    let headerRowHeight: CGFloat
    let headerIcon: CGFloat
    let closeIcon: CGFloat
    let headerTitle: CGFloat
    let metricsColumnGap: CGFloat
    let metricTitleValueGap: CGFloat
    let metricLabel: CGFloat
    let metricValue: CGFloat
    /// `minimumScaleFactor` for DTM / Trip / ETA values — tight columns need more shrink for long ETAs.
    let metricValueMinScale: CGFloat
    /// Equal width for each DTM / Trip / ETA column (`innerW` minus gaps, ÷ 3).
    let metricColumnMaxWidth: CGFloat
    let tackColumnGap: CGFloat
    let tackStateToDetailGap: CGFloat
    let tackState: CGFloat
    let tackDetail: CGFloat
    let warningFont: CGFloat
    let warningVerticalPad: CGFloat

    init(size: CGSize) {
        let w = max(size.width, 120)
        let h = max(size.height, 80)

        let stripTight = h < 118
        edgePad = stripTight ? max(4, min(8, w * 0.028)) : max(6, min(14, w * 0.035))
        let innerW = w - edgePad * 2
        let innerH = h - edgePad * 2
        /// Keep vertical scaling modest so the metrics row does not jump to oversized type in tall strips.
        let vScale = min(1.08, max(1.0, innerH / 100))

        dividerPad = stripTight ? max(2, min(5, innerH * 0.028)) : max(3, min(10, innerH * 0.045))
        sectionGap = max(4, innerH * 0.03)
        headerSpacing = max(5, innerW * 0.018)
        // Title stays secondary to DTM / Trip / ETA — modest size, not strip‑dominant.
        headerTitle = max(12, min(15, innerW * 0.038))
        headerRowHeight = max(26, min(32, headerTitle * 1.85))
        headerIcon = max(12, min(16, headerTitle * 0.95))
        closeIcon = max(14, min(18, headerTitle * 1.12))

        metricsColumnGap = max(4, innerW * 0.02)
        let metricColCount: CGFloat = 3
        let metricsUsable = max(0, innerW - metricsColumnGap * (metricColCount - 1))
        metricColumnMaxWidth = max(28, metricsUsable / metricColCount)
        metricTitleValueGap = stripTight ? max(1, innerH * 0.014) : max(2, innerH * 0.018)
        // One line per value: cap pt size from **column** width so long ETAs shrink via `minimumScaleFactor`, not layout growth.
        let valueFromCol = metricColumnMaxWidth * (stripTight ? 0.34 : 0.36)
        metricValue = min(21, max(stripTight ? 12 : 13, valueFromCol)) * vScale
        metricLabel = max(7, min(12, metricValue * 0.44))
        let narrowCol = metricColumnMaxWidth < 56
        metricValueMinScale = narrowCol ? 0.38 : (stripTight ? 0.42 : 0.48)

        tackColumnGap = max(6, innerW * 0.025)
        let tackHalfW = max(50, (innerW - tackColumnGap) / 2)
        tackStateToDetailGap = stripTight ? max(2, innerH * 0.02) : max(3, innerH * 0.028)
        tackState = min(18, max(stripTight ? 10 : 11, tackHalfW * (stripTight ? 0.078 : 0.09)) * vScale)
        tackDetail = min(19, max(stripTight ? 9 : 10, tackHalfW * (stripTight ? 0.085 : 0.095)) * vScale)

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
