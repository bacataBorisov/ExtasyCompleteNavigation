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
        
        GeometryProvider { width, _ in
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
            .ignoresSafeArea()
            .onAppear { loadData() }
            .onChange(of: identifier, { oldValue, newValue in
                saveData(newValue: newValue)
            })
        }//END OF GEOMETRY
        .aspectRatio(contentMode: .fit)
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
            .buttonStyle(.plain)
        }
    }
    
    private func checkSlotMenu(a: Int, oldValue: Int) -> Int {
        if let index = identifier.firstIndex(of: a) {
            identifier[index] = oldValue
        }
        return a
    }

    private func loadData() {
        if data.isEmpty {
            let model = Matrix(identifier: identifier)
            context.insert(model)
        } else if let last = data.last {
            identifier = last.identifier.prefix(displayCell.count).map { $0 }
        }
    }

    private func saveData(newValue: [Int]) {
        let model = Matrix(identifier: newValue)
        context.insert(model)
    }
}//END OF STRUCTURE

#Preview {
    
    MultiDisplay()
        .environment(NMEAParser())
        .modelContainer(for: [Matrix.self, UserSettingsMenu.self])
    
}

