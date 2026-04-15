//
//  PolarInstrumentView.swift
//  ExtasyCompleteNavigation
//
//  Fits in the lower panel without vertical ScrollView so TabView paging stays reliable.
//  TWS caption only; polar uses all remaining space (no nav title, no legend).
//

import SwiftUI

struct PolarInstrumentView: View {
    @Environment(NMEAParser.self) private var navigationReadings

    private let horizontalInset: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            let tws = navigationReadings.windData?.trueWindForce ?? 0
            let samples = tws > 0.4
                ? navigationReadings.polarBoatSpeedCurve(forTrueWindSpeedKnots: tws)
                : []

            let innerWidth = max(0, geo.size.width - horizontalInset * 2)

            VStack(alignment: .leading, spacing: 0) {
                if tws > 0.4 {
                    Text("TWS \(String(format: "%.1f", tws)) kn — boat speed vs TWA")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .padding(.bottom, 8)

                    GeometryReader { plotGeo in
                        let side = min(innerWidth, min(plotGeo.size.width, plotGeo.size.height))
                        HStack {
                            Spacer(minLength: 0)
                            PolarDiagramCanvasView(
                                samples: samples,
                                curveWindSpeedKnots: tws,
                                liveTrueWindAngle: navigationReadings.windData?.trueWindAngle,
                                liveBoatSpeedKnots: navigationReadings.hydroData?.boatSpeedLag,
                                optimalUpTWA: navigationReadings.vmgData?.optimalUpTWA,
                                optimalDnTWA: navigationReadings.vmgData?.optimalDnTWA,
                                showCaption: false
                            )
                            .frame(width: side, height: side)
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.primary.opacity(0.06))
                            )
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ContentUnavailableView(
                        "Wind required",
                        systemImage: "wind",
                        description: Text("TWS needed for the polar.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal, horizontalInset)
            .padding(.vertical, 6)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }
}

#Preview {
    PolarInstrumentView()
        .environment(NMEAParser())
        .frame(height: 340)
}
