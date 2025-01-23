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
    //initial states for the display segments before any data has been saved
    @State var identifier: [Int] = [0, 1, 2, 3]
    @Query var data: [Matrix]
    @Environment(\.modelContext) var context
    
    //Additional properties
    let sortedTags = ["wind", "speed", "other"] //tags for the menu titles
    
    var body: some View {
        
        GeometryProvider { width, _, _ in
            ZStack{
                VStack {
                    // Big Display Cell
                    menuDisplayCell(index: 0, aspectRatio: 3/2)
                    
                    // Small Display Cells
                    HStack {
                        ForEach(1...3, id: \.self) { index in
                            menuDisplayCell(index: index, aspectRatio: 1)
                        }
                    }
                }
                
                //Grid has to be on top of the rest, otherwise it disappears
                MultiDisplayGrid(width: width)
                    .allowsHitTesting(false) // Prevent interference with touch events
                    .zIndex(1) // Ensure it's rendered above other views
                
            }//END OF ZSTACK
            .aspectRatio(1, contentMode: .fit)
            .onAppear { loadData() }
            .onChange(of: identifier, { oldValue, newValue in
                saveData(newValue: newValue)
            })
            .onChange(of: data) { _, _ in
                if let lastSavedModel = data.last {
                    identifier = lastSavedModel.identifier.prefix(displayCell.count).map { $0 }
                }
            }
        }//END OF GEOMETRY
    }//END OF BODY
    
    // MARK: - Helper Methods
    
    // MARK: - Populating the View with Display Cells
    func menuDisplayCell(index: Int, aspectRatio: CGFloat) -> some View {
        Menu {
            DisplayMenu(
                tags: sortedTags, // Adjust tags if necessary
                displayCell: displayCell,
                currentValue: $identifier[index],
                onUpdate: { newValue in
                    identifier[index] = checkSlotMenu(a: newValue, oldValue: identifier[index])
                }
            )
        } label: {
            DisplayCell(
                cell: displayCell[identifier[index]],
                valueID: identifier[index],
                aspectRatio: aspectRatio,
                fontSizeMultiplier: 1,
                valueAlignment: .center
            )
        }
    }
    
    private func checkSlotMenu(a: Int, oldValue: Int) -> Int {
        if let index = identifier.firstIndex(of: a) {
            identifier[index] = oldValue
        }
        return a
    }

    private func loadData() {
        if let lastSavedModel = data.last {
            identifier = lastSavedModel.identifier.prefix(displayCell.count).map { $0 }
            debugLog("Loaded identifier: \(identifier)")
        } else {
            let model = Matrix(identifier: identifier)
            context.insert(model)
            try? context.save()
            debugLog("Inserted new identifier: \(identifier)")
        }
    }

    private func saveData(newValue: [Int]) {
        if let existingData = data.last {
            existingData.identifier = newValue
        } else {
            let newModel = Matrix(identifier: newValue)
            context.insert(newModel)
        }
        try? context.save()
    }
}//END OF STRUCTURE

#Preview {
    
    MultiDisplay()
        .environment(NMEAParser())
        .environment(SettingsManager())
        .modelContainer(for: [Matrix.self])
    
}

