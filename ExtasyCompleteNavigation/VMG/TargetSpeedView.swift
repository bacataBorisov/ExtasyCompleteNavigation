//
//  VMGView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 19.09.23.
//

import SwiftUI

struct TargetSpeedView: View {
    
    
    var aspectRatio = CGFloat()
    
    var current = Double()
    var target = Double()
    var dimension = String()
    
    
    var body: some View {
        GeometryReader{ geometry in
            
            let width: CGFloat = min(geometry.size.width, geometry.size.height)
            
            ZStack{
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color("dial_gauge_start"), Color("dial_gauge_end")]),  startPoint: .bottom, endPoint: .top))
                
                
            }
            
        }//END OF GEOMETRY
        .aspectRatio(aspectRatio, contentMode: .fit)
    }
}

#Preview {
    TargetSpeedView(aspectRatio: 1)
}

