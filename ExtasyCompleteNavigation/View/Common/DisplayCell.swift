//
//  SpeedAndDepth.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 26.08.23.
//
//  This view is used for rendering both small and large display cells.
//  It adjusts its layout and styling based on the provided parameters
//  such as aspect ratio, font size, and alignment.

//  TODO: If alarm thresholds, unit conversion, or display logic become more complex   or reusable, consider moving these functions to a ViewModel or utility class.

import SwiftUI
import SwiftData

struct DisplayCell: View {
    
    // MARK: - Constants for Styling
    private let alarmGradient = EllipticalGradient(colors: [Color(UIColor.systemRed), Color(UIColor.systemPink), Color(UIColor.systemBackground)])
    private let nonAlarmGradient = EllipticalGradient(colors: [Color(UIColor.systemBackground), Color(UIColor.systemBackground)])
    
    // MARK: - Properties
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(SettingsManager.self) private var settingsManager
    
    var cell: MultiDisplayCells
    var valueID: Int
    var aspectRatio: CGFloat = 1 // Default to square
    var fontSizeMultiplier: CGFloat = 1 // Adjust font dynamically
    var valueAlignment: Alignment = .center // Default alignment
    
    // MARK: - State
    @State private var displayedValue: Double = 0
    @State private var hasReceivedValue: Bool = false
    
    private var isStale: Bool {
        navigationReadings.dataStatus.sensorStatus(forValueID: valueID) == .stale
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            
            VStack(spacing: 0) {
                // Top row: label left, unit right — small, in corners
                HStack(alignment: .firstTextBaseline) {
                    Text(cell.name)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.12 * fontSizeMultiplier))
                    Spacer()
                    Text(settingsManager.metricWind && cell.valueHasMetric ? cell.metric : cell.units)
                        .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.12 * fontSizeMultiplier))
                        .foregroundStyle(Color("display_font").opacity(0.5))
                }
                .padding(.horizontal, width * 0.04)
                .padding(.top, width * 0.04)

                // Value — dominant, centered
                Spacer()
                Text(hasReceivedValue && !isStale ? formattedValue() : "--")
                    .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.54 * fontSizeMultiplier))
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
            .opacity(isStale ? 0.35 : 1.0)
            .background(alarmBackground())
            .foregroundStyle(Color("display_font"))
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .onAppear {
            if let initialValue = navigationReadings.displayValue(a: valueID) {
                displayedValue = initialValue
                hasReceivedValue = true
            }
        }
        .onChange(of: navigationReadings.displayValue(a: valueID)) { _, newValue in
            if let newValue {
                hasReceivedValue = true
                displayedValue = newValue
            } else {
                hasReceivedValue = false
            }
        }
    }
    
    // MARK: - Value Formatting

    private func formattedValue() -> String {
        // Depth: no decimal when >= 20 m, one decimal below that
        if cell.id == 0 {
            return String(format: displayedValue >= 20 ? "%.0f" : "%.1f", displayedValue)
        }
        return String(format: cell.specifier, displayedValue)
    }

    // MARK: - Alarm
    private func alarmBackground() -> some View {
        (cell.id == 0 && triggerAlarm()) ? alarmGradient : nonAlarmGradient
    }
    
    private func triggerAlarm() -> Bool {
        guard settingsManager.depthAlarmEnabled,
              let value = navigationReadings.hydroData?.depth else { return false }
        return value < settingsManager.depthAlarmThreshold
    }
}

#Preview {
    DisplayCell(cell: displayCell[1], valueID: 1)
        .environment(NMEAParser())
}
