//
//  MetricRow.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 6.06.25.
//
import SwiftUI

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
