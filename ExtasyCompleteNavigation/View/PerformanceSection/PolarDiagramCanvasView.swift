//
//  PolarDiagramCanvasView.swift
//  ExtasyCompleteNavigation
//
//  Radial polar: angle = true wind angle (0° = head to wind at top), radius = boat speed.
//

import SwiftUI

struct PolarDiagramCanvasView: View {
    /// Diagram TWA (degrees) and boat speed (knots).
    let samples: [(twa: Double, speed: Double)]
    let curveWindSpeedKnots: Double
    let liveTrueWindAngle: Double?
    let liveBoatSpeedKnots: Double?
    let optimalUpTWA: Double?
    let optimalDnTWA: Double?
    /// When `false`, hide the caption (e.g. when the parent screen already shows a navigation title).
    var showCaption: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showCaption {
                Text("Polar (TWS \(String(format: "%.1f", curveWindSpeedKnots)) kn)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if samples.isEmpty {
                ContentUnavailableView(
                    "No polar curve",
                    systemImage: "chart.line.downtrend.xyaxis",
                    description: Text("The VMG polar diagram is not available. Check that diagram data loaded in Settings or reconnect NMEA.")
                )
                .frame(minHeight: 160)
            } else {
                Canvas { context, size in
                    drawPolar(context: context, size: size)
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Polar diagram for current wind speed")
            }
        }
    }

    private func drawPolar(context: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 * 0.88

        guard !samples.isEmpty else { return }

        let sorted = samples.sorted { $0.twa < $1.twa }
        let maxSpeed = max(sorted.map(\.speed).max() ?? 1, liveBoatSpeedKnots ?? 0, 1)

        func point(twa: Double, speed: Double) -> CGPoint {
            let rNorm = min(max(speed / maxSpeed, 0), 1.15)
            let r = radius * CGFloat(rNorm)
            let phi = twa * .pi / 180
            return CGPoint(
                x: center.x + CGFloat(sin(phi)) * r,
                y: center.y - CGFloat(cos(phi)) * r
            )
        }

        func nearestSpeed(to twa: Double) -> Double {
            sorted.min(by: { abs($0.twa - twa) < abs($1.twa - twa) })?.speed ?? 0
        }

        for i in 1...4 {
            let r = radius * CGFloat(i) / 4
            var ring = Path()
            ring.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r))
            context.stroke(ring, with: .color(.secondary.opacity(0.15)), lineWidth: 0.5)
        }

        var axis = Path()
        axis.move(to: CGPoint(x: center.x, y: center.y + radius * 0.06))
        axis.addLine(to: CGPoint(x: center.x, y: center.y - radius))
        context.stroke(axis, with: .color(.secondary.opacity(0.35)), lineWidth: 1)

        var starboard = Path()
        if let first = sorted.first {
            starboard.move(to: point(twa: first.twa, speed: first.speed))
            for s in sorted.dropFirst() {
                starboard.addLine(to: point(twa: s.twa, speed: s.speed))
            }
        }
        context.stroke(starboard, with: .color(.cyan.opacity(0.85)), lineWidth: 2)

        var port = Path()
        if let first = sorted.first {
            port.move(to: point(twa: -first.twa, speed: first.speed))
            for s in sorted.dropFirst() {
                port.addLine(to: point(twa: -s.twa, speed: s.speed))
            }
        }
        context.stroke(port, with: .color(.purple.opacity(0.75)), lineWidth: 2)

        if let up = optimalUpTWA, up > 1 {
            let sp = nearestSpeed(to: up)
            let p = point(twa: up, speed: sp)
            var tick = Path()
            tick.addEllipse(in: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8))
            context.fill(tick, with: .color(.green.opacity(0.9)))
        }
        if let dn = optimalDnTWA, dn > 1 {
            let sp = nearestSpeed(to: dn)
            let p = point(twa: dn, speed: sp)
            var tick = Path()
            tick.addEllipse(in: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8))
            context.fill(tick, with: .color(.orange.opacity(0.9)))
        }

        if let twa = liveTrueWindAngle, let bsp = liveBoatSpeedKnots, bsp > 0 {
            let signed = normalizeAngleTo180(twa)
            let absT = abs(signed)
            let xSign: CGFloat = signed >= 0 ? 1 : -1
            let rNorm = min(max(bsp / maxSpeed, 0), 1.15)
            let r = radius * CGFloat(rNorm)
            let phi = absT * .pi / 180
            let x = center.x + CGFloat(sin(phi)) * r * xSign
            let y = center.y - CGFloat(cos(phi)) * r
            var dot = Path()
            dot.addEllipse(in: CGRect(x: x - 5, y: y - 5, width: 10, height: 10))
            context.fill(dot, with: .color(.yellow))
            context.stroke(dot, with: .color(.black.opacity(0.35)), lineWidth: 1)
        }
    }
}

#Preview {
    PolarDiagramCanvasView(
        samples: Array(stride(from: 22, through: 150, by: 11)).map { (twa: Double($0), speed: 4 + Double($0) / 80) },
        curveWindSpeedKnots: 12,
        liveTrueWindAngle: 52,
        liveBoatSpeedKnots: 6.2,
        optimalUpTWA: 42,
        optimalDnTWA: 140
    )
    .padding()
    .background(Color.black.opacity(0.9))
}
