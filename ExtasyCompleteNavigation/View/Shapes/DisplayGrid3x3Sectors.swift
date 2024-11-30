
//
//  DisplayGrid3x3Sectors.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 26.10.24.
//

import SwiftUI

struct DisplayGrid3x3Sectors: View {
    var body: some View {
        //TODO: - This can be separated in a different view and further improved
        ZStack{
            HorizontalLine()
                .fill(LinearGradient(gradient: Gradient(colors: [Color("line_start"), Color("line_mid"), Color("line_end")]), startPoint: .leading, endPoint: .trailing))
            HorizontalLine()
                .fill(LinearGradient(gradient: Gradient(colors: [Color("line_start"), Color("line_mid"), Color("line_end")]), startPoint: .leading, endPoint: .trailing))
                .rotationEffect(Angle(degrees: 180))
            HorizontalLine()
                .fill(LinearGradient(gradient: Gradient(colors: [Color("line_start"), Color("line_mid"), Color("line_end")]), startPoint: .leading, endPoint: .trailing))
                .rotationEffect(Angle(degrees: 90))
            HorizontalLine()
                .fill(LinearGradient(gradient: Gradient(colors: [Color("line_start"), Color("line_mid"), Color("line_end")]), startPoint: .leading, endPoint: .trailing))
                .rotationEffect(Angle(degrees: 270))
        }
        .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    DisplayGrid3x3Sectors()
}
