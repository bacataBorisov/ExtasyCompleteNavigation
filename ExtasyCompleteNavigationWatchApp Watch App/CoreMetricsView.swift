//
//  WatchMetricsView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 4.06.25.
//


import SwiftUI

struct CoreMetricsView: View {
    
    @Environment(WatchSessionManager.self) private var sessionManager

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height

            VStack(spacing: 0) {
                // Top Row: Depth (25%)

                HStack(spacing: 6) {
                    MetricRow(title: "DPT", value: sessionManager.depth, unit: "m", valueColor: .cyan)

                    Divider()
                    MetricRow(title: "HDG", value: sessionManager.heading, unit: "°", valueColor: .green.opacity(0.9))
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
}

#Preview {
    CoreMetricsView()
        .environment(WatchSessionManager())
}
