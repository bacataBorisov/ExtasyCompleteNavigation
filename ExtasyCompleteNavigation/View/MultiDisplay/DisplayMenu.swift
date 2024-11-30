
import SwiftUI

struct DisplayMenu: View {
    let tags: [String] // Tags like "wind", "speed", "other"
    let displayCell: [MultiDisplayCells]
    @Binding var currentValue: Int
    let onUpdate: (Int) -> Void // Closure to handle updates
    
    var body: some View {
        ForEach(tags, id: \.self) { tag in
            Menu(tag.capitalized) {
                ForEach(displayCell.filter { $0.tag == tag }) { cell in
                    Button(action: {
                        onUpdate(cell.id)
                    }) {
                        Text(cell.name)
                    }
                }
            }
        }
    }
}
