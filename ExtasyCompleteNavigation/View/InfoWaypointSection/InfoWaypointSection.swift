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
        let sectionPadding: CGFloat = 8

        VStack(spacing: sectionPadding) {
            WaypointCard(title: "", subtitle: "", destination: WaypointListView())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(sectionPadding)
    }
}

#Preview {
    InfoWaypointSection()
        .environment(NMEAParser())
}
