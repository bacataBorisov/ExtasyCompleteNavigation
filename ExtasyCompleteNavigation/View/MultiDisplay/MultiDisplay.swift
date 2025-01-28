//
//  MultiDisplay.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 3.10.23.
//

import SwiftUI
import SwiftData

struct MultiDisplay: View {
    @Environment(NMEAParser.self) private var navigationReadings

    // AppStorage for saving display cell indices
    @AppStorage("multiDisplayCell0") private var cell0: Int = 0
    @AppStorage("multiDisplayCell1") private var cell1: Int = 1
    @AppStorage("multiDisplayCell2") private var cell2: Int = 2
    @AppStorage("multiDisplayCell3") private var cell3: Int = 3

    // Categories for menu tags
    let sortedTags = ["wind", "speed", "other"]

    @State private var animatedValues: [Int] = [] // For subtle UI refresh animations

    var body: some View {
        GeometryProvider { width, _, _ in
            ZStack {
                VStack {
                    // Top large display cell
                    menuDisplayCell(aspectRatio: 3 / 2, currentValue: $cell0)

                    // Bottom smaller display cells
                    HStack {
                        menuDisplayCell(aspectRatio: 1, currentValue: $cell1)
                        menuDisplayCell(aspectRatio: 1, currentValue: $cell2)
                        menuDisplayCell(aspectRatio: 1, currentValue: $cell3)
                    }
                }

                // Grid overlay
                MultiDisplayGrid(width: width)
                    .allowsHitTesting(false) // Prevent interaction with the grid
                    .zIndex(1) // Ensure grid is rendered above other views
                    .animation(.easeInOut(duration: 0.3), value: animatedValues) // Smooth animations
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }

    // MARK: - Menu Display Cell
    /// Creates a menu-based display cell with the ability to swap and select values
    func menuDisplayCell(aspectRatio: CGFloat, currentValue: Binding<Int>) -> some View {
        Menu {
            ForEach(sortedTags, id: \.self) { category in
                Menu(category.capitalized) {
                    // Submenu with items based on category
                    ForEach(0..<displayCell.count, id: \.self) { newIndex in
                        if displayCell[newIndex].tag == category {
                            Button(action: {
                                debugLog("Current value before button press: \(currentValue.wrappedValue) (\(displayCell[currentValue.wrappedValue].name))")
                                debugLog("Button pressed for value: \(newIndex) (\(displayCell[newIndex].name))")
                                handleSelection(newValue: newIndex, currentValue: currentValue)
                            }) {
                                Text(displayCell[newIndex].name)
                            }
                        }
                    }
                }
            }
        } label: {
            DisplayCell(
                cell: displayCell[currentValue.wrappedValue],
                valueID: currentValue.wrappedValue,
                aspectRatio: aspectRatio,
                fontSizeMultiplier: 1,
                valueAlignment: .center
            )
        }
    }

    // MARK: - Handle Selection
    /// Handles the selection of a new value in the menu
    private func handleSelection(newValue: Int, currentValue: Binding<Int>) {
        if let duplicateIndex = findDuplicate(newValue: newValue, currentValue: currentValue.wrappedValue) {
            debugLog("Duplicate detected: \(newValue) already exists in cell\(duplicateIndex)")
            swapValues(newValue: newValue, duplicateIndex: duplicateIndex, currentValue: currentValue)
        } else {
            debugLog("Value \(newValue) selected for \(currentValue.wrappedValue)")
            currentValue.wrappedValue = newValue
            refreshAnimatedValues() // Trigger a smooth animation after selection
        }
    }

    // MARK: - Find Duplicate
    /// Finds duplicate values among all cells
    private func findDuplicate(newValue: Int, currentValue: Int) -> Int? {
        let allValues = [cell0, cell1, cell2, cell3]
        if let duplicateIndex = allValues.firstIndex(of: newValue), newValue != currentValue {
            debugLog("Duplicate found at index: \(duplicateIndex) for value: \(newValue)")
            return duplicateIndex
        }
        debugLog("No duplicate found for value: \(newValue)")
        return nil
    }

    // MARK: - Swap Values
    /// Swaps the values of the current cell and the duplicate cell
    private func swapValues(newValue: Int, duplicateIndex: Int, currentValue: Binding<Int>) {
        // Get the original value of the current cell
        let originalValue = currentValue.wrappedValue

        debugLog("Original values: [\(cell0), \(cell1), \(cell2), \(cell3)]")

        // Swap values between the cells
        switch duplicateIndex {
        case 0: cell0 = originalValue
        case 1: cell1 = originalValue
        case 2: cell2 = originalValue
        case 3: cell3 = originalValue
        default: break
        }

        // Update the current cell with the new value
        currentValue.wrappedValue = newValue

        refreshAnimatedValues() // Trigger smooth animation after swapping

        debugLog("Swapped \(newValue) with \(originalValue): Final values: [\(cell0), \(cell1), \(cell2), \(cell3)]")
    }

    // MARK: - Smooth UI Animation Refresh
    /// Updates the animatedValues array to trigger a smooth refresh animation
    private func refreshAnimatedValues() {
        animatedValues = [cell0, cell1, cell2, cell3]
    }
}

#Preview {
    MultiDisplay()
        .environment(NMEAParser())
        .environment(SettingsManager())
}
