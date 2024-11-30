//
//  ReusableETACell.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 3.02.24.
//

import SwiftUI
import SwiftData

struct ReusableETACell: View {
    
    @ObservedObject var viewModel: VMGViewModel
    let label: String            // Label to display, e.g., "ETA", "Distance", etc.
    let value: String            // Value to display, formatted externally.
    let width: CGFloat           // Width of the cell.

    var body: some View {
        
        ZStack {
            Group {
                // Label at the top-left
                Text(label)
                    .frame(width: width, height: width, alignment: .topLeading)
                    .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
                
                // Dynamic value at the center
                Text(value)
                    .frame(width: width, height: width, alignment: .center)
                    .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.2))
            }
            .padding(.top, 5)
            .minimumScaleFactor(0.2)
        }
        .foregroundStyle(Color("display_font"))
    }
}

#Preview {
    GeometryProvider { width, _ in
        // Mock VMGProcessor and ViewModel for testing
        let mockProcessor = VMGProcessor()
        let mockViewModel = VMGViewModel(vmgProcessor: mockProcessor)
        
        // Set some mock data in the processor
        mockProcessor.vmgData.estTimeOfArrival = 3600 // Example: 1 hour in seconds
        
        // Example usage with a formatted ETA
        return ReusableETACell(
            viewModel: mockViewModel,
            label: "ETA",
            value: "01:00:00", // Simulate a formatted value for preview
            width: width
        )
    }
    .aspectRatio(contentMode: .fit)
}
