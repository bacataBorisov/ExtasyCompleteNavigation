//
//  WatchMainView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 6.06.25.
//

import SwiftUI
import SwiftData

// MARK: - Main View
struct WatchMainView: View {
    
    @State var currentPage: Int = 0
    
    var body: some View {
        
        TabView (selection: $currentPage) {
            
            WindMetricsView()
                .tag(-1)
            CoreMetricsView()
                .tag(0)

        }
    }
}

#Preview {
    WatchMainView()
        .environment(WatchSessionManager())
}
