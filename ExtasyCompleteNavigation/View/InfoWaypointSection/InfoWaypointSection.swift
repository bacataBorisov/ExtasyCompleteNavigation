//
//  InfoWaypointSection.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 1.01.25.
//

import SwiftUI
import CoreLocation

struct InfoWaypointSection: View {
    
    @Environment(NMEAParser.self) private var navigationReadings
    
    var body: some View {
        GeometryReader { geometry in
            //let totalWidth = geometry.size.width
            let sectionPadding: CGFloat = 8
            
            //                let titleFont = Font.system(size: totalWidth * 0.05, weight: .bold)
            //                let dataFont = Font.system(size: totalWidth * 0.04, weight: .regular)
            
            VStack(spacing: sectionPadding){
                
                WaypointCard(title: "", subtitle: "", destination: WaypointListView())
                
                InformationCard()
            }
            .padding(.bottom, sectionPadding)
            
        }
    }
}

#Preview {
    InfoWaypointSection()
        .environment(NMEAParser())
}
