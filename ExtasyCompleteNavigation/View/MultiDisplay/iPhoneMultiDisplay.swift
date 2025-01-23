import SwiftUI
import SwiftData

struct iPhoneMultiDisplay: View {
    
    @Environment(NMEAParser.self) private var navigationReadings
    @State var identifier: [Int] = [0, 1, 2, 3]
    @Query var data: [Matrix]
    @Environment(\.modelContext) var context
    
    // Additional properties
    let sortedTags = ["wind", "speed", "other"] // Tags for the menu titles
    
    var body: some View {
        GeometryReader { geometry in
            let totalHeight = geometry.size.height
            let totalWidth = geometry.size.width
            let bigCellHeight = totalHeight * 2/3 // Big cell height is 2/3
            let smallCellHeight = totalHeight / 3 // Small cells height is 1/3
            
            VStack(spacing: 0) {
                // Big Display Cell
                menuDisplayCell(index: 0, height: bigCellHeight, fontMultiplier: 1)
                
                // Small Display Cells
                HStack(spacing: 0) {
                    ForEach(1...3, id: \.self) { index in
                        menuDisplayCell(index: index, height: smallCellHeight, fontMultiplier: 1.5)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

            }
            .frame(width: totalWidth, height: totalHeight) // Explicitly set frame
            .background(Color.clear) // Optional: Use for debugging layout
            .onAppear { loadData() }
            .onChange(of: identifier) { _, newValue in
                saveData(newValue: newValue)
            }
            
            // Grid overlay
            MultiDisplayGrid(width: totalWidth)
                .allowsHitTesting(false) // Prevent interference with touch events
                .zIndex(1) // Ensure it's rendered above other views
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Respect parent constraints
    }
    
    // MARK: - Menu Display Cell
    private func menuDisplayCell(index: Int, height: CGFloat, fontMultiplier: Double) -> some View {
        Menu {
            DisplayMenu(
                tags: sortedTags,
                displayCell: displayCell,
                currentValue: $identifier[index],
                onUpdate: { newValue in
                    identifier[index] = checkSlotMenu(a: newValue, oldValue: identifier[index])
                }
            )
        } label: {
            iPhoneDisplayCell(
                cell: displayCell[identifier[index]],
                valueID: identifier[index],
                fontMultiplier: fontMultiplier
            )
            .frame(height: height) // Constrain cell height
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    // MARK: - Helper Methods
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
}

#Preview {
    iPhoneMultiDisplay()
        .environment(NMEAParser())
        .environment(SettingsManager())
        .modelContainer(for: [Matrix.self])
}
