import SwiftUI
import CoreLocation

/// iPhone full-panel waypoint view.
///
/// Mirrors the iPad ``VMGSimpleView`` layout:
///   header → DTM/TRIP/ETA (3-column row) → tack pair | divider | downwind advisor
struct iPhoneVMGView: View {
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(SettingsManager.self) private var settingsManager
    var waypointName: String

    @State private var showWaypointList = false

    var body: some View {
        GeometryReader { geo in
            let m = PhoneVMGMetrics(size: geo.size)

            VStack(alignment: .leading, spacing: 0) {
                headerRow(metrics: m)

                Divider().padding(.vertical, m.dividerPad)

                metricsRow(metrics: m)

                Spacer(minLength: m.sectionGap)

                Divider().padding(.vertical, m.dividerPad)

                if navigationReadings.waypointData?.isVMCNegative == true {
                    Text("Moving away from waypoint")
                        .font(.system(size: m.warningFont, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, m.warningPad)
                        .padding(.horizontal, 8)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.red.opacity(0.85)))
                } else {
                    tackAndAdvisorSection(metrics: m)
                }
            }
            .padding(.horizontal, m.edgePad)
            .padding(.vertical, m.edgePad)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(Color(UIColor.systemBackground))
        .sheet(isPresented: $showWaypointList) {
            NavigationStack {
                WaypointListView()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private func headerRow(metrics m: PhoneVMGMetrics) -> some View {
        HStack(alignment: .center, spacing: m.headerSpacing) {
            Button(action: { showWaypointList = true }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: m.headerIcon, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: m.headerRowH, height: m.headerRowH)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(waypointName)
                .font(.system(size: m.headerTitle, weight: .semibold))
                .foregroundStyle(Color("display_font"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, maxHeight: m.headerRowH, alignment: .leading)

            Button(action: { navigationReadings.deselectWaypoint() }) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: m.closeIcon))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .frame(width: m.headerRowH, height: m.headerRowH)
        }
        .frame(height: m.headerRowH)
    }

    // MARK: - Metrics row (DTM / TRIP / ETA — 3 equal columns, mirrors iPad)

    private func metricsRow(metrics m: PhoneVMGMetrics) -> some View {
        HStack(alignment: .top, spacing: m.metricColGap) {
            metricCol(
                title: "DTM",
                value: "\(settingsManager.formatDistance(meters: navigationReadings.waypointData?.distanceToMark ?? 0)) \(settingsManager.distanceAbbreviation)",
                metrics: m
            )
            metricCol(
                title: "TRIP",
                value: formatDuration(navigationReadings.waypointData?.tripDurationToWaypoint),
                metrics: m
            )
            metricCol(
                title: "ETA",
                value: formatETA(navigationReadings.waypointData?.etaToWaypoint),
                metrics: m
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func metricCol(title: String, value: String, metrics m: PhoneVMGMetrics) -> some View {
        VStack(alignment: .leading, spacing: m.metricGap) {
            Text(title)
                .font(.system(size: m.metricLabel, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.system(size: m.metricValue, weight: .bold, design: .rounded))
                .foregroundStyle(Color("display_font"))
                .lineLimit(1)
                .minimumScaleFactor(0.45)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Tack pair | divider | advisor (mirrors iPad tackAndAdvisorSection)

    private func tackAndAdvisorSection(metrics m: PhoneVMGMetrics) -> some View {
        let wp = navigationReadings.waypointData
        let showAdvisor = wp?.waypointApproachState == "Downwind"
        return HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: m.tackRowGap) {
                currentLegRow(metrics: m)
                nextLegRow(metrics: m)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showAdvisor {
                Divider()
                    .padding(.horizontal, m.advisorGap)

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
        .frame(maxWidth: .infinity)
    }

    // MARK: - Advisor column (right half — mirrors iPad advisorColumn)

    private func advisorColumn(
        directHours: Double?,
        gybeHours: Double?,
        deltaHours: Double?,
        bearingToMark: Double?,
        metrics m: PhoneVMGMetrics
    ) -> some View {
        let gybeFaster  = (deltaHours ?? 0) < 0
        let directColor: Color = (gybeHours != nil && directHours != nil && !gybeFaster) ? .cyan : Color("display_font")
        let gybeColor:   Color = (gybeHours != nil && directHours != nil && gybeFaster)  ? .cyan : Color("display_font")
        let wp = navigationReadings.waypointData
        let directTWALabel = wp?.twaToMarkDirect.map { "TWA \(Int($0.rounded()))°" }
        let gybeOptLabel   = wp?.optimalGybeTWA.map  { "opt \(Int($0.rounded()))°" }

        let statusLabel: String?
        let statusColor: Color
        if let twaMark = wp?.twaToMarkDirect, let twaOpt = wp?.optimalGybeTWA {
            let diff = twaMark - twaOpt
            if diff < -8 {
                statusLabel = "OVERSTOOD ↑"; statusColor = .secondary
            } else if diff > 8 {
                statusLabel = "MARK DEEP ↓"; statusColor = .orange.opacity(0.85)
            } else {
                statusLabel = "ON LAYLINE ≈"; statusColor = .cyan.opacity(0.85)
            }
        } else {
            statusLabel = nil; statusColor = .secondary
        }

        return VStack(alignment: .leading, spacing: m.tackRowGap) {
            if let status = statusLabel {
                Text(status)
                    .font(.system(size: m.rowLabel, weight: .semibold))
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            advisorCell(label: "DIRECT",
                        time: formatAdvisorDuration(directHours),
                        sublabel: directTWALabel,
                        timeColor: directHours != nil ? directColor : Color.secondary,
                        bold: !gybeFaster && gybeHours != nil,
                        metrics: m)

            advisorCell(label: "GYBE",
                        time: formatAdvisorDuration(gybeHours),
                        sublabel: gybeOptLabel,
                        timeColor: gybeHours != nil ? gybeColor : Color.secondary,
                        bold: gybeFaster && gybeHours != nil,
                        metrics: m)

            if let delta = deltaHours {
                Text(formatAdvisorDelta(delta))
                    .font(.system(size: m.rowLabel, weight: .semibold, design: .rounded))
                    .foregroundStyle(gybeFaster ? Color.cyan.opacity(0.85) : Color.orange.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
    }

    private func advisorCell(
        label: String, time: String,
        sublabel: String? = nil,
        timeColor: Color, bold: Bool,
        metrics m: PhoneVMGMetrics
    ) -> some View {
        VStack(alignment: .leading, spacing: m.hintGap) {
            // Label + optional inline bearing ("DIRECT  → 310°") — one row, no extra height.
            HStack(spacing: 4) {
                Text(label)
                    .foregroundStyle(.secondary)
                if let sub = sublabel {
                    Text(sub)
                        .foregroundStyle(.secondary)
                }
            }
            .font(.system(size: m.rowLabel, weight: .medium))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            Text(time)
                .font(.system(size: m.dataValue, weight: bold ? .bold : .regular, design: .rounded))
                .foregroundStyle(timeColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    // MARK: - Current / Next leg rows (format unchanged — hint line + hero numbers)

    private func currentLegRow(metrics m: PhoneVMGMetrics) -> some View {
        let rawTWA = (navigationReadings.windData?.trueWindAngle ?? 0)
        let normalised = (rawTWA + 360).truncatingRemainder(dividingBy: 360)
        let isPort = normalised > 180
        let tackLabel = isPort ? "PORT" : "STBD"
        let tackColor = TacticalPalette.tackLabelColor(for: tackLabel)
        let modeLabel = (navigationReadings.vmgData?.sailingState
            ?? navigationReadings.waypointData?.waypointApproachState
            ?? "—").uppercased()
        let modeColor: Color = modeLabel == "UPWIND" ? .cyan : modeLabel == "DOWNWIND" ? .orange : .secondary

        return legRow(
            label: "CURRENT",
            distance: "\(settingsManager.formatDistanceFromNM(navigationReadings.waypointData?.tackDistance ?? 0)) \(settingsManager.distanceAbbreviation)",
            duration: formatDuration(navigationReadings.waypointData?.tackDuration),
            tackLabel: tackLabel, tackColor: tackColor,
            modeLabel: modeLabel, modeColor: modeColor,
            metrics: m
        )
    }

    private func nextLegRow(metrics m: PhoneVMGMetrics) -> some View {
        let raw = navigationReadings.waypointData?.nextLegTack ?? "—"
        let nextLabel = raw == "Port" ? "PORT" : raw == "Starboard" ? "STBD" : "—"
        let nextColor: Color = nextLabel == "—" ? .secondary : TacticalPalette.tackLabelColor(for: nextLabel)
        let state = (navigationReadings.waypointData?.nextLegSailingState
            ?? navigationReadings.waypointData?.waypointApproachState
            ?? "—").uppercased()
        let stateColor: Color = state == "UPWIND" ? .cyan : .orange

        return legRow(
            label: "NEXT",
            distance: "\(settingsManager.formatDistanceFromNM(navigationReadings.waypointData?.distanceOnOppositeTack ?? 0)) \(settingsManager.distanceAbbreviation)",
            duration: formatDuration(navigationReadings.waypointData?.tripDurationOnOppositeTack),
            tackLabel: nextLabel, tackColor: nextColor,
            modeLabel: state, modeColor: stateColor,
            metrics: m
        )
    }

    private func legRow(
        label: String,
        distance: String, duration: String,
        tackLabel: String, tackColor: Color,
        modeLabel: String, modeColor: Color,
        metrics m: PhoneVMGMetrics
    ) -> some View {
        VStack(alignment: .leading, spacing: m.hintGap) {
            HStack(spacing: m.columnGap) {
                Text(distance)
                    .font(.system(size: m.dataValue, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("display_font"))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(duration)
                    .font(.system(size: m.dataValue, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("display_font"))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 5) {
                Text(label)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(tackLabel)
                    .foregroundStyle(tackColor)
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(modeLabel)
                    .foregroundStyle(modeColor)
            }
            .font(.system(size: m.rowLabel, weight: .medium))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
    }

    // MARK: - Formatters

    private func formatDuration(_ hours: Double?) -> String {
        guard let h = hours, h.isFinite, h > 0, h < 87_600 else { return "—" }
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

    /// Racing-precision duration for advisor cells: always hh:mm:ss.
    private func formatAdvisorDuration(_ hours: Double?) -> String {
        guard let h = hours, h.isFinite, h > 0, h < 87_600 else { return "—" }
        let total = Int(h * 3600)
        let hh = total / 3600
        let mm = (total % 3600) / 60
        let ss = total % 60
        return String(format: "%02d:%02d:%02d", hh, mm, ss)
    }

    /// Signed delta with seconds precision when under 1 hour.
    private func formatAdvisorDelta(_ deltaHours: Double) -> String {
        let absSecs = Int(abs(deltaHours) * 3600)
        let h = absSecs / 3600
        let m = (absSecs % 3600) / 60
        let s = absSecs % 60
        let timeStr: String
        if h > 0 {
            timeStr = "\(h)h \(m)m \(s)s"
        } else if m > 0 {
            timeStr = "\(m)m \(s)s"
        } else {
            timeStr = "\(s)s"
        }
        return deltaHours < 0 ? "save \(timeStr)" : "+\(timeStr)"
    }
}

// MARK: - Geometry-driven sizes

private struct PhoneVMGMetrics {
    let edgePad: CGFloat
    let dividerPad: CGFloat
    let sectionGap: CGFloat
    let headerSpacing: CGFloat
    let headerRowH: CGFloat
    let headerIcon: CGFloat
    let headerTitle: CGFloat
    let closeIcon: CGFloat
    /// Gap between the 3 metric columns (DTM / TRIP / ETA).
    let metricColGap: CGFloat
    let metricGap: CGFloat
    let metricLabel: CGFloat
    let metricValue: CGFloat
    /// Gap between CURRENT and NEXT tack rows.
    let tackRowGap: CGFloat
    /// Gap between the hint line and hero numbers within a tack row.
    let hintGap: CGFloat
    /// Hero distance / duration font.
    let dataValue: CGFloat
    /// Hint line font (CURRENT · PORT · DOWNWIND).
    let rowLabel: CGFloat
    /// Half-width column gap (padding each side of the vertical Divider).
    let advisorGap: CGFloat
    let columnGap: CGFloat
    let warningFont: CGFloat
    let warningPad: CGFloat

    init(size: CGSize) {
        let w = max(size.width, 200)
        let h = max(size.height, 160)

        edgePad       = max(8, min(16, w * 0.035))
        let inner     = w - edgePad * 2

        dividerPad    = max(4, min(8, h * 0.022))
        sectionGap    = max(8, h * 0.04)
        headerSpacing = max(6, inner * 0.02)
        headerTitle   = max(15, min(20, inner * 0.055))
        headerRowH    = max(30, headerTitle * 1.8)
        headerIcon    = max(14, min(18, headerTitle * 0.9))
        closeIcon     = max(16, min(20, headerTitle * 1.1))

        metricColGap  = max(8, inner * 0.025)
        metricGap     = max(3, h * 0.014)
        metricLabel   = max(11, min(14, inner * 0.038))
        metricValue   = max(20, min(34, inner * 0.088))

        tackRowGap    = max(12, h * 0.04)
        hintGap       = max(3, h * 0.012)
        dataValue     = max(16, min(24, inner * 0.065))
        rowLabel      = max(11, min(14, inner * 0.038))
        advisorGap    = max(6, inner * 0.025)
        columnGap     = max(6, inner * 0.025)

        warningFont   = max(13, min(17, inner * 0.045))
        warningPad    = max(8, h * 0.04)
    }
}

// MARK: - Previews

extension NMEAParser {
    static func mockVMCNegative() -> NMEAParser {
        let parser = NMEAParser()
        parser.waypointData = WaypointData(isVMCNegative: true)
        return parser
    }
}

#Preview("VMC Negative") {
    GeometryProvider { _, _, height in
        VStack {
            Spacer()
            iPhoneVMGView(waypointName: "Balchik")
                .environment(NMEAParser.mockVMCNegative())
                .environment(SettingsManager())
                .frame(height: height / 2)
        }
    }
}

#Preview("VMC Normal") {
    GeometryProvider { _, _, height in
        VStack {
            Spacer()
            NavigationStack {
                iPhoneVMGView(waypointName: "Balchik")
                    .environment(NMEAParser())
                    .environment(SettingsManager())
            }
            .frame(height: height / 2)
        }
    }
}
