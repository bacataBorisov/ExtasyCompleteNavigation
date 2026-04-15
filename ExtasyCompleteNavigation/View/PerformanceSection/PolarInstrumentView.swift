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

    /// Tighter insets and no diagram “plate” (e.g. iPad lower strip).
    var compactChrome: Bool = false
    /// When `false`, the TWS caption is hidden and the diagram fills the height (e.g. iPad top cell + centered overlay).
    var showTWSCaption: Bool = true
    /// iPad top stack cell only: match `UltimateView`’s iPad padding (4) and center the plot so the Ultimate/Polar toggle lines up.
    var iPadStackCell: Bool = false

    private var horizontalInset: CGFloat {
        if iPadStackCell { return 4 }
        return compactChrome ? 6 : 10
    }
    private var verticalInset: CGFloat {
        if iPadStackCell { return 0 }
        if compactChrome { return showTWSCaption ? 4 : 0 }
        return 6
    }
    /// Extra padding around `PolarDiagramCanvasView` inside the square frame (skipped in iPad stack cell for symmetric layout).
    private var diagramCanvasPadding: CGFloat {
        if iPadStackCell { return 0 }
        return compactChrome ? 2 : 4
    }
    private var contentFrameAlignment: Alignment {
        iPadStackCell ? .center : .top
    }

    var body: some View {
        GeometryReader { geo in
            let tws = navigationReadings.windData?.trueWindForce ?? 0
            let samples = tws > 0.4
                ? navigationReadings.polarBoatSpeedCurve(forTrueWindSpeedKnots: tws)
                : []

            let innerWidth = max(0, geo.size.width - horizontalInset * 2)

            VStack(alignment: .leading, spacing: 0) {
                if tws > 0.4 {
                    if showTWSCaption {
                        Text("TWS \(String(format: "%.1f", tws)) kn — boat speed vs TWA")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .padding(.bottom, 8)
                    }

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
                            .padding(diagramCanvasPadding)
                            .background {
                                if !compactChrome {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.primary.opacity(0.06))
                                }
                            }
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
            .padding(.vertical, verticalInset)
            .frame(width: geo.size.width, height: geo.size.height, alignment: contentFrameAlignment)
        }
    }
}

#Preview {
    PolarInstrumentView()
        .environment(NMEAParser())
        .frame(height: 340)
}
