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
    @State private var displayedValue: Double = 0 // Tracks the animated value
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                Group {
                    labelView(width: width)
                    animatedValueView(width: width, height: height)
                        .minimumScaleFactor(0.4)
                    unitView(width: width)
                }
                .padding([.leading, .trailing, .top], 4)
            }
            .background(alarmBackground())
            .foregroundStyle(Color("display_font"))
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .onAppear {
            // Set the initial value when the view appears
            if let initialValue = navigationReadings.displayValue(a: valueID) {
                displayedValue = initialValue
            }
        }
        .onChange(of: navigationReadings.displayValue(a: valueID)) { _, newValue in
            // Animate to the new value when it changes
            guard let newValue = newValue else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                displayedValue = newValue
            }
        }
    }
    
    // MARK: - Subviews
    private func labelView(width: CGFloat) -> some View {
        Text(cell.name)
            .frame(width: width, height: width, alignment: .topLeading)
            .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2 * fontSizeMultiplier))
    }
    
    private func animatedValueView(width: CGFloat, height: CGFloat) -> some View {
        Text(String(format: cell.specifier, displayedValue))
            .frame(width: width, height: width, alignment: valueAlignment)
            .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.4 * fontSizeMultiplier))
            .offset(y: aspectRatio > 1 ? (height - width) / 4 : 0) // Adjust for non-square ratios
    }
    
    private func unitView(width: CGFloat) -> some View {
        let unit: String = settingsManager.metricWind && cell.valueHasMetric ? cell.metric : cell.units
        return Text(unit)
            .frame(width: width, height: width, alignment: .topTrailing)
            .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.18 * fontSizeMultiplier))
    }
    
    // MARK: - Helper Methods
    private func alarmBackground() -> some View {
        (cell.id == 0 && triggerAlarm()) ? alarmGradient : nonAlarmGradient
    }
    
    private func triggerAlarm() -> Bool {
        guard let value = navigationReadings.hydroData?.depth else { return false }
        return value < 3 // Alarm threshold for depth
    }
}

#Preview {
    DisplayCell(cell: displayCell[1], valueID: 1)
        .environment(NMEAParser())
}
