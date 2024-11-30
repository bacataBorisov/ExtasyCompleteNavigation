//
//  SettingsMenuView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 18.11.24.
//

import SwiftUI
import SwiftData

struct SettingsMenuView: View {
    @StateObject private var viewModel: SettingsMenuViewModel
    
    init(navigationReadings: NMEAParser, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: SettingsMenuViewModel(
            navigationReadings: navigationReadings,
            modelContext: modelContext
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                Toggle("Metric Wind", isOn: $viewModel.changeUnits)
                    .onChange(of: viewModel.changeUnits, { _, _ in
                        viewModel.updateSettings()
                    })
                
                NavigationLink("Raw Navigation Data", destination: RawNavigationDataView())
                Text("Glossary")
                Text("Set Alarms")
                
                    .navigationTitle("Settings")
            }
        }
    }
    
    #Preview {
        // Step 1: Create mock data for the preview
        let preview = Preview()
        let mockReadings = NMEAParser()
        
        
        // Step 2: Pass required arguments to SettingsMenuView
        SettingsMenuView(
            navigationReadings: mockReadings, // Mock instance of NMEAReader
            modelContext: preview.modelContainer.mainContext
        )
        .environment(mockReadings) // Inject into environment
        .modelContainer(preview.modelContainer) // Attach the model container
    }
}
