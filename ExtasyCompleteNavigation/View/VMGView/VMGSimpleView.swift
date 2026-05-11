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

                tackAndAdvisorSection(metrics: m)

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

    /// Two tack legs stacked vertically — each gets full strip width for larger hero numbers.
    private func tackPairRowCompact(metrics m: StripMetrics) -> some View {
        let wp = navigationReadings.waypointData
        let curTackRaw = wp?.currentTackState      // "Port" / "Starboard"
        let curState   = navigationReadings.vmgData?.sailingState ?? "—"
        let nxtTackRaw = wp?.nextLegTack
        let nxtState   = wp?.nextLegSailingState ?? wp?.waypointApproachState ?? "—"

        return VStack(alignment: .leading, spacing: m.tackRowGap) {
            tackLegRow(
                tackRaw: curTackRaw,
                state: curState,
                distanceNM: wp?.tackDistance ?? 0,
                duration: wp?.tackDuration,
                metrics: m
            )
            tackLegRow(
                tackRaw: nxtTackRaw,
                state: nxtState,
                distanceNM: wp?.distanceOnOppositeTack ?? 0,
                duration: wp?.tripDurationOnOppositeTack,
                metrics: m
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Single full-width tack leg: coloured tack label + state on hint line; hero numbers below.
    private func tackLegRow(
        tackRaw: String?,
        state: String,
        distanceNM: Double,
        duration: Double?,
        metrics m: StripMetrics
    ) -> some View {
        let tackLabel = tackRaw == "Port" ? "PORT" : tackRaw == "Starboard" ? "STBD" : nil
        let tackColor: Color = tackLabel.map { TacticalPalette.tackLabelColor(for: $0) } ?? .secondary

        return VStack(alignment: .leading, spacing: m.tackStateToDetailGap) {
            // Hint line: "STBD · DOWNWIND" — tack in its tactical colour, state secondary
            HStack(spacing: 4) {
                if let tl = tackLabel {
                    Text(tl)
                        .foregroundStyle(tackColor)
                        .fontWeight(.semibold)
                    Text("·")
                        .foregroundStyle(.tertiary)
                }
                Text(state.uppercased())
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: m.tackState, weight: .medium))
            .lineLimit(1)
            .minimumScaleFactor(0.75)

            // Hero line: "1.4 NM  ·  00:19"
            Text("\(settingsManager.formatDistanceFromNM(distanceNM)) \(settingsManager.distanceAbbreviation)  ·  \(formatTripDuration(duration))")
                .font(.system(size: m.tackDetail, weight: .bold, design: .rounded))
                .foregroundStyle(Color("display_font"))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
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

    /// Tack pair (left half) | vertical divider | advisor (right half).
    /// Advisor column is shown whenever the approach state is Downwind, even if some
    /// individual values are nil (e.g. gybe legs not yet computed or polar out of range).
    private func tackAndAdvisorSection(metrics m: StripMetrics) -> some View {
        let wp = navigationReadings.waypointData
        let showAdvisor = wp?.waypointApproachState == "Downwind"
        return HStack(alignment: .top, spacing: 0) {
            tackPairRowCompact(metrics: m)
                .frame(maxWidth: .infinity, alignment: .leading)

            if showAdvisor {
                Divider()
                    .padding(.horizontal, m.advisorColumnGap)

                advisorColumn(
                    directHours: wp?.directDownwindDuration,
                    gybeHours: wp?.gybePathDuration,
                    deltaHours: wp?.downwindTimeDeltaHours,
                    bearingToMark: wp?.trueMarkBearing,
                    metrics: m
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// Right-column advisor: Direct / Gybe times stacked vertically; faster in cyan.
    private func advisorColumn(
        directHours: Double?,
        gybeHours: Double?,
        deltaHours: Double?,
        bearingToMark: Double?,
        metrics m: StripMetrics
    ) -> some View {
        let directFaster = (deltaHours ?? 0) < 0
        let directColor: Color = (gybeHours != nil && directHours != nil && directFaster) ? .cyan : Color("display_font")
        let gybeColor:   Color = (gybeHours != nil && directHours != nil && !directFaster) ? .cyan : Color("display_font")
        let bearingLabel = bearingToMark.map { "→ \(Int($0.rounded()))°" }

        return VStack(alignment: .leading, spacing: m.tackRowGap) {
            advisorLegCell(label: "DIRECT",
                           time: directHours.map { formatTripDuration($0) } ?? "—",
                           sublabel: bearingLabel,
                           timeColor: directHours != nil ? directColor : Color.secondary,
                           bold: directFaster && gybeHours != nil,
                           metrics: m)

            advisorLegCell(label: "GYBE",
                           time: gybeHours.map { formatTripDuration($0) } ?? "—",
                           sublabel: nil,
                           timeColor: gybeHours != nil ? gybeColor : Color.secondary,
                           bold: !directFaster && gybeHours != nil,
                           metrics: m)

            if let delta = deltaHours {
                Text(formatAdvisorDelta(delta))
                    .font(.system(size: m.tackState, weight: .semibold, design: .rounded))
                    .foregroundStyle(directFaster ? Color.cyan.opacity(0.85) : Color.orange.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
    }

    private func advisorLegCell(
        label: String, time: String,
        sublabel: String? = nil,
        timeColor: Color, bold: Bool,
        metrics m: StripMetrics
    ) -> some View {
        VStack(alignment: .leading, spacing: m.tackStateToDetailGap) {
            // Label + optional inline bearing ("DIRECT  → 310°") — one row, no extra height.
            HStack(spacing: 4) {
                Text(label)
                    .foregroundStyle(.secondary)
                if let sub = sublabel {
                    Text(sub)
                        .foregroundStyle(.secondary)
                }
            }
            .font(.system(size: m.tackState, weight: .medium))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            Text(time)
                .font(.system(size: m.tackDetail, weight: bold ? .bold : .regular, design: .rounded))
                .foregroundStyle(timeColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    /// Racing-precision delta: seconds shown when under 1 hour.
    /// e.g. −75 s → "save 1m 15s"; +2 min → "+2m"; +1.3 h → "+1h 18m"
    private func formatAdvisorDelta(_ deltaHours: Double) -> String {
        let absSecs = Int(abs(deltaHours) * 3600)
        let h = absSecs / 3600
        let m = (absSecs % 3600) / 60
        let s = absSecs % 60
        let timeStr: String
        if h > 0 {
            timeStr = "\(h)h \(m)m"          // hour-level: no seconds needed
        } else if m > 0 {
            timeStr = s > 0 ? "\(m)m \(s)s" : "\(m)m"
        } else {
            timeStr = "\(s)s"
        }
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
    /// Vertical gap between the two tack-leg rows (LEG 1 / LEG 2).
    let tackRowGap: CGFloat
    let tackStateToDetailGap: CGFloat
    let tackState: CGFloat
    let tackDetail: CGFloat
    /// Horizontal gap between tack-legs column and advisor column.
    let advisorColumnGap: CGFloat
    /// Fixed width of the right-side advisor column (Direct / Gybe / delta).
    let advisorColumnWidth: CGFloat
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

        dividerPad = stripTight ? max(1, min(3, innerH * 0.018)) : max(2, min(4, innerH * 0.022))
        sectionGap = max(3, innerH * 0.025)
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

        // Equal halves: tack pair (left) | divider | advisor (right).
        // Gap is the horizontal padding each side of the vertical Divider.
        advisorColumnGap = max(4, innerW * 0.018)
        // Both halves get ~48 % of inner width; the divider + its gaps take the rest.
        let tackAvailW = max(60, innerW * 0.48)
        advisorColumnWidth = tackAvailW   // kept for reference; layout uses maxWidth: .infinity
        tackRowGap = stripTight ? max(2, innerH * 0.025) : max(3, innerH * 0.032)
        tackStateToDetailGap = max(1, innerH * 0.01)
        // Coefficients scaled up relative to old 65 %-wide column so hero pt-size stays the same.
        tackState = min(13, max(stripTight ? 9 : 10, tackAvailW * (stripTight ? 0.092 : 0.103)) * vScale)
        tackDetail = min(22, max(stripTight ? 13 : 15, tackAvailW * (stripTight ? 0.148 : 0.162)) * vScale)

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
