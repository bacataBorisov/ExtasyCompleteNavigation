//
//  ExtasyCompleteNavigationWatchAppApp.swift
//  ExtasyCompleteNavigationWatchApp Watch App
//
//  Created by Vasil Borisov on 16.05.25.
//

import SwiftUI

@main
struct ExtasyCompleteNavigationWatchApp_Watch_AppApp: App {
    
    @State private var sessionManager = WatchSessionManager()
    
    var body: some Scene {
        WindowGroup {
            
            WatchMainView()
                .environment(sessionManager)

        }
    }
}
