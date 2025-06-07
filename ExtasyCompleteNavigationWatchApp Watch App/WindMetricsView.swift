//
//  WatchMetricsView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 4.06.25.
//


import SwiftUI

struct WindMetricsView: View {
    
    @Environment(WatchSessionManager.self) private var sessionManager

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height

            VStack(spacing: 0) {
                // Top Row: TWS & AWS

                HStack(spacing: 6) {
                    MetricRow(title: "TWS", value: sessionManager.tws, unit: "kn", valueColor: .blue)

                    Divider()
                    MetricRow(title: "AWS", value: sessionManager.aws, unit: "kn", valueColor: .yellow)
                }

                Divider()
                // Middle Row: TWA & AWA
                HStack(spacing: 6) {
                    MetricRow(title: "TWA", value: sessionManager.twa, unit: "°", valueColor: .blue)
                    Divider()
                    MetricRow(title: "AWA", value: sessionManager.awa, unit: "°", valueColor: .yellow)
                }
                Divider()
                
                // Bottom Row: TWD & AWD
                HStack(spacing: 6) {
                    MetricRow(title: "TWD", value: sessionManager.twd, unit: "°", valueColor: .blue)
                    Divider()
                    MetricRow(title: "AWA", value: sessionManager.awd, unit: "°", valueColor: .yellow)
                }
            }
            .padding([.leading, .trailing], 8)
            .frame(width: geo.size.width, height: height, alignment: .top)
        }
    }
}

#Preview {
    WindMetricsView()
        .environment(WatchSessionManager())
}
