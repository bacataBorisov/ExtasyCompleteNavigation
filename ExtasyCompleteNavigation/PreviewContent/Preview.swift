//
//  Preview.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 18.11.24.
//

import Foundation
import SwiftData

struct Preview {
    
    let modelContainer: ModelContainer
    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            modelContainer = try ModelContainer(for: UserSettingsMenu.self, configurations: config)
        } catch {
            fatalError("Could not initialize ModelContainer")
        }
    }
    
    //Function to insert our samples in the model container
    func addExamples(_ examples: [UserSettingsMenu]) {
        
        Task { @MainActor in
            examples.forEach { example in
                modelContainer.mainContext.insert(example)
            }
        }
        
    }
    
}
