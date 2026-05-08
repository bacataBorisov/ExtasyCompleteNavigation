import SwiftUI
import CoreLocation

/// iPhone full-panel waypoint view.
///
/// Same visual language as ``VMGSimpleView`` (iPad compact strip) — system background,
/// adaptive colours, geometry-driven fonts — but expanded to show three tack-leg rows
/// (DIRECT / CURRENT / NEXT) that don't fit in the narrow iPad strip.
struct iPhoneVMGView: View {
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(SettingsManager.self) private var settingsManager
    var waypointName: String

    @State private var showWaypointList = false

    var body: some View {
        GeometryReader { geo in
            let m = PhoneVMGMetrics(size: geo.size)

            VStack(alignment: .leading, spacing: 0) {
                // ── Top: name ───────────────────────────────────────────────
                headerRow(metrics: m)

                Divider().padding(.vertical, m.dividerPad)

                // ── Middle: DTM / TRIP / ETA distributed across all available space
                directSection(metrics: m)

                // ── Bottom: tack legs pinned to the bottom ───────────────────
                if navigationReadings.waypointData?.isVMCNegative == true {
                    Text("Moving away from waypoint")
                        .font(.system(size: m.warningFont, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, m.warningPad)
                        .padding(.horizontal, 8)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.red.opacity(0.85)))
                } else {
                    // Downwind path advisor — only shown when mark is downwind and polar is available
                    if let directH = navigationReadings.waypointData?.directDownwindDuration {
                        Divider().padding(.vertical, m.dividerPad)
                        downwindAdvisorSection(
                            directHours: directH,
                            gybeHours: navigationReadings.waypointData?.gybePathDuration,
                            deltaHours: navigationReadings.waypointData?.downwindTimeDeltaHours,
                            twaToMark: navigationReadings.waypointData?.twaToMarkDirect,
                            optDnTWA: navigationReadings.vmgData?.optimalDnTWA,
                            metrics: m
                        )
                    }

                    Divider().padding(.vertical, m.dividerPad)

                    currentLegRow(metrics: m)

                    Divider().padding(.vertical, m.dividerPad)

                    nextLegRow(metrics: m)
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

    // MARK: - Header (list icon | name | close) — matches VMGSimpleView header layout

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

    // MARK: - Direct section: DTM / TRIP / ETA as 3 rows filling available space

    private func directSection(metrics m: PhoneVMGMetrics) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            metricRow(
                label: "DTM",
                value: "\(settingsManager.formatDistance(meters: navigationReadings.waypointData?.distanceToMark ?? 0)) \(settingsManager.distanceAbbreviation)",
                metrics: m
            )
            Spacer(minLength: 0)
            metricRow(
                label: "TRIP",
                value: formatDuration(navigationReadings.waypointData?.tripDurationToWaypoint),
                metrics: m
            )
            Spacer(minLength: 0)
            metricRow(
                label: "ETA",
                value: formatETA(navigationReadings.waypointData?.etaToWaypoint),
                metrics: m
            )
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Current leg (boat → tack point)

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

    // MARK: - Next leg (tack point → mark)

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

    // MARK: - Shared leg row layout
    //
    // Hero line: distance  |  duration  (big, prominent)
    // Hint line: CURRENT · STBD · UPWIND  (small, secondary — context at a glance)

    private func legRow(
        label: String,
        distance: String, duration: String,
        tackLabel: String, tackColor: Color,
        modeLabel: String, modeColor: Color,
        metrics m: PhoneVMGMetrics
    ) -> some View {
        VStack(alignment: .leading, spacing: m.hintGap) {
            // Hero: numbers first
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

            // Hint: leg label · tack · mode
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
        .padding(.vertical, m.rowVPad)
    }

    // MARK: - Metric row (full-width, used in directSection)

    private func metricRow(label: String, value: String, metrics m: PhoneVMGMetrics) -> some View {
        VStack(alignment: .leading, spacing: m.metricGap) {
            Text(label)
                .font(.system(size: m.metricLabel, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.system(size: m.metricValue, weight: .bold, design: .rounded))
                .foregroundStyle(Color("display_font"))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Downwind Path Advisor

    /// Two-row comparison: Direct vs Gybe, each with a hero duration and hint line.
    /// Faster option highlighted in cyan; shows delta on the hint of the faster row.
    private func downwindAdvisorSection(
        directHours: Double,
        gybeHours: Double?,
        deltaHours: Double?,
        twaToMark: Double?,
        optDnTWA: Double?,
        metrics m: PhoneVMGMetrics
    ) -> some View {
        let directFaster = (deltaHours ?? 0) < 0
        let directColor: Color = (gybeHours != nil && directFaster) ? .cyan : Color("display_font")
        let gybeColor:   Color = (gybeHours != nil && !directFaster) ? .cyan : Color("display_font")

        let directHint: String = {
            var parts = ["DIRECT"]
            if let twa = twaToMark { parts.append("TWA \(Int(twa))°") }
            if directFaster, let d = deltaHours { parts.append(formatAdvisorDelta(abs(d))) }
            return parts.joined(separator: " · ")
        }()
        let gybeHint: String = {
            var parts = ["GYBE"]
            if let twa = optDnTWA { parts.append("opt \(Int(twa))°") }
            if !directFaster, let d = deltaHours { parts.append(formatAdvisorDelta(abs(d))) }
            return parts.joined(separator: " · ")
        }()

        return VStack(alignment: .leading, spacing: 0) {
            // Row 1 — Direct
            advisorRow(
                duration: formatDuration(directHours),
                hint: directHint,
                durationColor: directColor,
                isFaster: directFaster && gybeHours != nil,
                metrics: m
            )
            // Row 2 — Gybe (only when gybe path is available)
            if let g = gybeHours {
                advisorRow(
                    duration: formatDuration(g),
                    hint: gybeHint,
                    durationColor: gybeColor,
                    isFaster: !directFaster,
                    metrics: m
                )
            }
        }
    }

    private func advisorRow(
        duration: String,
        hint: String,
        durationColor: Color,
        isFaster: Bool,
        metrics m: PhoneVMGMetrics
    ) -> some View {
        VStack(alignment: .leading, spacing: m.hintGap) {
            Text(duration)
                .font(.system(size: m.dataValue, weight: isFaster ? .bold : .regular, design: .rounded))
                .foregroundStyle(durationColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(hint)
                .font(.system(size: m.rowLabel, weight: .medium))
                .foregroundStyle(isFaster ? Color.cyan.opacity(0.85) : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, m.rowVPad * 0.6)
    }

    /// e.g. 0.75 h → "45m"; 1.3 h → "1h 18m"
    private func formatAdvisorDelta(_ absHours: Double) -> String {
        let secs = Int(absHours * 3600)
        let h = secs / 3600
        let m = (secs % 3600) / 60
        return h > 0 ? "saves \(h)h \(m)m" : "saves \(m)m"
    }

    // MARK: - Helpers

    private func formatDuration(_ hours: Double?) -> String {
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
}

// MARK: - Geometry-derived sizes

private struct PhoneVMGMetrics {
    let edgePad: CGFloat
    let dividerPad: CGFloat
    let headerSpacing: CGFloat
    let headerRowH: CGFloat
    let headerIcon: CGFloat
    let headerTitle: CGFloat
    let closeIcon: CGFloat
    let columnGap: CGFloat
    let rowLabel: CGFloat
    let rowVPad: CGFloat
    let hintGap: CGFloat
    let dataValue: CGFloat
    let metricGap: CGFloat
    let metricLabel: CGFloat
    let metricValue: CGFloat
    let warningFont: CGFloat
    let warningPad: CGFloat

    init(size: CGSize) {
        let w = max(size.width, 200)
        let h = max(size.height, 160)

        edgePad        = max(8, min(16, w * 0.035))
        let inner      = w - edgePad * 2

        dividerPad     = max(4, min(10, h * 0.025))
        headerSpacing  = max(6, inner * 0.02)
        headerTitle    = max(15, min(20, inner * 0.055))
        headerRowH     = max(30, headerTitle * 1.8)
        headerIcon     = max(14, min(18, headerTitle * 0.9))
        closeIcon      = max(16, min(20, headerTitle * 1.1))

        columnGap      = max(6, inner * 0.025)
        rowLabel       = max(11, min(14, inner * 0.038))
        rowVPad        = max(8, min(14, h * 0.035))
        hintGap        = max(3, h * 0.012)
        dataValue      = max(16, min(24, inner * 0.065))

        metricGap      = max(4, h * 0.018)
        metricLabel    = max(11, min(14, inner * 0.038))
        metricValue    = max(22, min(38, inner * 0.096))

        warningFont    = max(13, min(17, inner * 0.045))
        warningPad     = max(8, h * 0.04)
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
