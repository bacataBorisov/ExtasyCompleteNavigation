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
    @Query var lastSettings: [UserSettingsMenu]
    var cell: MultiDisplayCells
    
    var valueID: Int
    var aspectRatio: CGFloat = 1 //Default to square
    var fontSizeMultiplier: CGFloat = 1 //Adjust font dynamically - used for the big cell segment
    var valueAlignment: Alignment = .center //Default value for alignment
    
    // MARK: - State
    @State private var triggerAlarm: Bool = false
    @State private var goodResult = false
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = width / aspectRatio
            
            ZStack {
                Group {
                    labelView(width: width)
                    valueView(width: width, height: height)
                    unitView(width: width)
                }
                .padding(.top, 3)
            }
            .background(alarmBackground())
            .foregroundStyle(Color("display_font"))
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .onChange(of: navigationReadings.hydroData?.depth) { _, newValue in
            handleDepthAlarm(newValue: newValue)
        }
    }
    
    // MARK: - Subviews
    private func labelView(width: CGFloat) -> some View {
        Text(cell.name)
            .frame(width: width, height: width, alignment: .topLeading)
            .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2 * fontSizeMultiplier))
    }
    
    private func valueView(width: CGFloat, height: CGFloat) -> some View {
        if let unwrappedValue = navigationReadings.displayValue(a: valueID) {
            return AnyView(
                Text(String(format: cell.specifier, unwrappedValue))
                    .frame(width: width, height: width, alignment: valueAlignment)
                    .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.4 * fontSizeMultiplier))
                    .offset(y: aspectRatio > 1 ? (height - width) / 4 : 0) // Adjust for non-square ratios
                /*
                 MARK: - Aspect Ratio Notes

                 1. **Definition**:
                    - Aspect ratio (`width / height`) determines the layout's proportions:
                      - `aspectRatio = 1`: Square layout.
                      - `aspectRatio > 1`: Wider layout (e.g., 3:2).
                      - `aspectRatio < 1`: Taller layout (e.g., 2:3).

                 2. **Behavior**:
                    - For `aspectRatio > 1` (wider layout):
                      - Height is reduced, so elements may need vertical adjustment (e.g., centering text).
                      - Use `.offset(y:)` to account for the height reduction.
                    - For `aspectRatio <= 1`:
                      - No adjustment needed; elements are naturally centered.

                 3. **Future Use**:
                    - Refactor alignment logic into reusable helper functions for consistent layout handling.
                    - Example:
                      ```swift
                      if aspectRatio > 1 {
                          Text("Centered Text").offset(y: (height - width) / 4)
                      }
                      ```
                */

            )
        } else {
            return AnyView(EmptyView())
        }
    }

    private func unitView(width: CGFloat) -> some View {
        let unit: String = {
            guard let lastSetting = lastSettings.last else { return cell.units }
            return (lastSetting.metricToggle && cell.valueHasMetric) ? cell.metric : cell.units
        }()
        
        return Text(unit)
            .frame(width: width, height: width, alignment: .topTrailing)
            .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.18 * fontSizeMultiplier))
    }
    
    // MARK: - Helper Methods
    private func handleDepthAlarm(newValue: Double?) {
        guard let value = newValue else { return }
        // TODO: Make threshold customizable from settings.
        triggerAlarm = value < 3
    }
    
    private func alarmBackground() -> some View {
        (cell.id == 0 && triggerAlarm) ? alarmGradient : nonAlarmGradient
    }
}

#Preview {
    DisplayCell(cell: displayCell[1], valueID: 1)
        .environment(NMEAParser())
        .modelContainer(for: [Matrix.self, UserSettingsMenu.self])
}
