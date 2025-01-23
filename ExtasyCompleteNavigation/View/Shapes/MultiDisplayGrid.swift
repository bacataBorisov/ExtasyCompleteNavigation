//
//  MultiDisplayGrid.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 26.10.24.
//

import SwiftUI

struct MultiDisplayGrid: View {
    
    let width: CGFloat
    
    var body: some View {
        
        ZStack(){
            HorizontalLine()
                .fill(LinearGradient(gradient: Gradient(colors: [Color("line_start"), Color("line_mid"), Color("line_end")]), startPoint: .leading, endPoint: .trailing))
            
            VerticalLine()
                .fill(LinearGradient(gradient: Gradient(colors: [Color("line_start"), Color("line_mid"), Color("line_end")]), startPoint: .center, endPoint: .bottom))
        }
    }
}

#Preview {
    GeometryProvider { width, _, _ in
        MultiDisplayGrid(width: width)
    }
    .aspectRatio(contentMode: .fit)
    .background(Color.black)
}
