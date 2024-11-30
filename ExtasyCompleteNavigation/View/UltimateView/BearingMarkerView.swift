//
//  BearingMarkerView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 22.11.24.
//

import SwiftUI

struct BearingMarkerView: View {
    let relativeMarkBearing: Double
    let isVMGSelected: Bool
    let width: CGFloat

    // Computed properties for offsets and font size
    private var triangleOffset: CGFloat {
        -width / 2.39
    }
    private var scopeOffset: CGFloat {
        -width / 2.34
    }
    private var fontSize: CGFloat {
        width / 30
    }

    var body: some View {
        ZStack {
            if isVMGSelected {
                Triangle()
                    .rotation(.degrees(180))
                    .scaleEffect(x: 0.07, y: 0.07)
                    .offset(y: triangleOffset)
                    .foregroundStyle(Color.green)
                
                Image(systemName: "scope")
                    .font(Font.custom("AppleSDGothicNeo-Bold", size: fontSize))
                    .offset(y: scopeOffset)
                    .foregroundStyle(Color.black)
            }
        }
        .rotationEffect(.degrees(relativeMarkBearing))
        .animation(.easeInOut(duration: 1), value: relativeMarkBearing)
    }
}

// Preview
#Preview {
    GeometryProvider { width, _ in
        BearingMarkerView(relativeMarkBearing: 34, isVMGSelected: true, width: width)
    }
    .aspectRatio(contentMode: .fit)
}

