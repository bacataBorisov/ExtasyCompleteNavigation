//
//  UltimateView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 2.10.23.
//

import SwiftUI

struct UltimateView: View {
    
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(SettingsManager.self) private var settingsManager

    // Individual AppStorage for each corner's display value
    @AppStorage("speedCorner0") private var speedCorner0: Int = 3
    @AppStorage("speedCorner1") private var speedCorner1: Int = 11
    @AppStorage("angleCorner0") private var angleCorner0: Int = 4
    @AppStorage("angleCorner1") private var angleCorner1: Int = 7

    // Trigger for UI refresh
    // Animated values for smooth UI refresh
    @State private var animatedValues: [Int] = []
    
    var body: some View {
        GeometryProvider { width, geometry, _ in
            ZStack {
                // MARK: - Settings, Map, Waypoints Section
                UltimateNavigationView()

                // MARK: - Corners Display
                // Top row: Speed (left) and Angle (right)
                HStack {
                    menuCornerView(
                        aspectRatio: 1,
                        currentValue: $speedCorner0,
                        allowedTag: "speed",
                        nameAlignment: .bottomLeading,
                        valueAlignment: .topTrailing,
                        stringSpecifier: "%.1f"
                    )
                    Spacer(minLength: width / 1.45)
                    menuCornerView(
                        aspectRatio: 1,
                        currentValue: $angleCorner0,
                        allowedTag: "wind",
                        nameAlignment: .bottomTrailing,
                        valueAlignment: .topLeading,
                        stringSpecifier: "%.f"
                    )
                }
                .frame(width: width, height: width, alignment: .top)

                // Bottom row: Angle (left) and Speed (right)
                HStack {
                    menuCornerView(
                        aspectRatio: 1,
                        currentValue: $angleCorner1,
                        allowedTag: "wind",
                        nameAlignment: .topLeading,
                        valueAlignment: .bottomTrailing,
                        stringSpecifier: "%.f"
                    )
                    Spacer(minLength: width / 1.45)
                    menuCornerView(
                        aspectRatio: 1,
                        currentValue: $speedCorner1,
                        allowedTag: "speed",
                        nameAlignment: .topTrailing,
                        valueAlignment: .bottomLeading,
                        stringSpecifier: "%.1f"
                    )
                }
                .frame(width: width, height: width, alignment: .bottom)

                // MARK: - Anemometer Section
                AnemometerView(
                    trueWindAngle: navigationReadings.windData?.trueWindAngle ?? 0,
                    apparentWindAngle: navigationReadings.windData?.apparentWindAngle ?? 0,
                    width: width
                )

                // MARK: - Compass Section
                CompassView(width: width, geometry: geometry)

                // MARK: - Bearing to Mark Marker
                if navigationReadings.gpsData?.isTargetSelected == true {
                    BearingMarkerView(width: width)
                }
            } // END ZSTACK
            .animation(.easeInOut(duration: 0.3), value: animatedValues) // Smooth animations for updates
        } // END GEOMETRY
        .aspectRatio(1, contentMode: .fit)
        .padding()
    }

    // MARK: - Menu Corner View
    /// Creates a menu-based corner display view
    private func menuCornerView(
        aspectRatio: CGFloat,
        currentValue: Binding<Int>,
        allowedTag: String,
        nameAlignment: Alignment,
        valueAlignment: Alignment,
        stringSpecifier: String
    ) -> some View {
        Menu {
            ForEach(0..<displayCell.count, id: \.self) { newIndex in
                if displayCell[newIndex].tag == allowedTag {
                    Button(action: {
                        debugLog("Before button press: \(currentValue.wrappedValue) (\(displayCell[currentValue.wrappedValue].name))")
                        debugLog("Button pressed for value: \(newIndex) (\(displayCell[newIndex].name))")
                        handleSelection(newValue: newIndex, currentValue: currentValue, tag: allowedTag)
                    }) {
                        Text(displayCell[newIndex].name)
                    }
                }
            }
        } label: {
            SmallCornerView(
                cell: displayCell[currentValue.wrappedValue],
                valueID: currentValue.wrappedValue,
                nameAlignment: nameAlignment,
                valueAlignment: valueAlignment,
                stringSpecifier: stringSpecifier
            )
        }
    }

    // MARK: - Handle Selection
    /// Handles the selection of a new value, checks for duplicates, and swaps values if necessary
    private func handleSelection(newValue: Int, currentValue: Binding<Int>, tag: String) {
        if let duplicateIndex = findDuplicate(newValue: newValue, currentValue: currentValue.wrappedValue, tag: tag) {
            debugLog("Duplicate detected: \(newValue) already exists in cell\(duplicateIndex)")
            swapValues(newValue: newValue, duplicateIndex: duplicateIndex, currentValue: currentValue)
        } else {
            debugLog("Value \(newValue) selected for \(currentValue.wrappedValue)")
            currentValue.wrappedValue = newValue
            refreshAnimatedValues()
        }
    }

    // MARK: - Find Duplicate
    /// Finds duplicate values in the corresponding category (speed or wind)
    private func findDuplicate(newValue: Int, currentValue: Int, tag: String) -> Int? {
        let allValues = tag == "speed" ? [speedCorner0, speedCorner1] : [angleCorner0, angleCorner1]
        if let duplicateIndex = allValues.firstIndex(of: newValue), newValue != currentValue {
            debugLog("Duplicate found at index: \(duplicateIndex) for value: \(newValue)")
            return duplicateIndex
        }
        debugLog("No duplicate found for value: \(newValue)")
        return nil
    }

    // MARK: - Swap Values
    /// Swaps values between the current cell and the duplicate cell
    private func swapValues(newValue: Int, duplicateIndex: Int, currentValue: Binding<Int>) {
        let originalValue = currentValue.wrappedValue

        debugLog("Original values: [\(speedCorner0), \(speedCorner1), \(angleCorner0), \(angleCorner1)]")

        // Swap values based on the tag (speed or wind)
        if [speedCorner0, speedCorner1].contains(originalValue) {
            // Speed category
            if duplicateIndex == 0 {
                speedCorner0 = originalValue
            } else if duplicateIndex == 1 {
                speedCorner1 = originalValue
            }
        } else {
            // Wind category
            if duplicateIndex == 0 {
                angleCorner0 = originalValue
            } else if duplicateIndex == 1 {
                angleCorner1 = originalValue
            }
        }

        // Update the current cell with the new value
        currentValue.wrappedValue = newValue

        // Log the final state
        debugLog("Swapped \(newValue) with \(originalValue): Final values: [\(speedCorner0), \(speedCorner1), \(angleCorner0), \(angleCorner1)]")

        // Trigger UI refresh
        refreshAnimatedValues()
    }

    // MARK: - Smooth UI Animation Refresh
    /// Updates the animatedValues array to trigger a smooth refresh animation
    private func refreshAnimatedValues() {
        animatedValues = [speedCorner0, speedCorner1, angleCorner0, angleCorner1]
    }
}

#Preview {
    UltimateView()
        .environment(NMEAParser())
        .environment(SettingsManager())
        .modelContainer(for: [Waypoints.self])
}
