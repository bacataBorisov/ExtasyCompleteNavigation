//
//  WatchMetricsView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 4.06.25.
//


import SwiftUI

struct WatchMetricsView: View {
    
    @State private var sessionManager = WatchSessionManager()
    @State private var isZoomed = false

    // Example inputs - replace with your live data bindings
    var depth: Double = 36.5
    var speedLog: Double = 4.6
    var heading: Double = 254.0
    var trueWindSpeed: Double = 9.8
    var trueWindAngle: Double = 42.0
    var sog: Double = 8.3
    var cog: Double = 261.0

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height

            VStack(spacing: 0) {
                // Top Row: Depth (25%)

                HStack(spacing: 6) {
                    MetricRow(title: "DPT", value: sessionManager.depth, unit: "m", valueColor: .cyan)
                        .scaleEffect(isZoomed ? 1.4 : 1.0)
                        .onLongPressGesture {
                            withAnimation {
                                isZoomed.toggle()
                            }
                        }
                    Divider()
                    MetricRow(title: "HDG", value: headingString, unit: "°", valueColor: .green.opacity(0.9))
                }

                Divider()
                // Middle Row: SPD + SOG (50%)
                HStack(spacing: 6) {
                    MetricRow(title: "SPD", value: sessionManager.boatSpeedLog, unit: "kn", valueColor: .pink)
                    Divider()
                    MetricRow(title: "SOG", value: sessionManager.sog, unit: "kn", valueColor: .orange)
                }
            }
            .padding([.leading, .trailing], 8)
            .frame(width: geo.size.width, height: height, alignment: .top)
        }
    }

    // MARK: - Computed Formatters
    private var depthString: String { String(format: "%.1f", depth) }
    private var speedLogString: String { String(format: "%.1f", speedLog) }
    private var headingString: String { String(format: "%.0f", heading) }
    private var twsString: String { String(format: "%.1f", trueWindSpeed) }
    private var twaString: String { String(format: "%.0f", trueWindAngle) }
    private var sogString: String { String(format: "%.1f", sog) }
    private var cogString: String { String(format: "%.0f", cog) }
}

struct MetricRow: View {
    var title: String
    var value: String
    var unit: String
    var valueColor: Color

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.gray)
                Spacer()
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(value)
                .font(Font.custom("AppleSDGothicNeo-Bold", size: 36))
                .foregroundColor(valueColor)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


#Preview {
    WatchMetricsView()
}
