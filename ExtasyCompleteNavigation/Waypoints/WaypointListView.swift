//
//  WaypointView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 15.01.24.
//

import SwiftUI
import SwiftData
import CoreLocation

struct WaypointListView: View {
    
    @Environment(NMEAReader.self) private var navigationReadings
    @Environment(\.dismiss) var dismiss
    @State private var sheetIsPresented = false
    //SwiftData variables that are needed
    @Environment(\.modelContext) private var modelContext
    @Query private var waypoints: [Waypoints]
    
    
    var body: some View {
        
        NavigationStack {
            List(){
                //display all waypoints entered in swiftdatabase
                ForEach(waypoints) { waypoint in
                    
                    NavigationLink{
                        WaypointDetailedView(waypoint: waypoint)
                    } label: {
                        Text(waypoint.title)
                    }
                    
                    //delete the entry by swiping on the left
                    .swipeActions(allowsFullSwipe: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/) {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            
                            waypoint.isTargetSelected = false // remove the target from the map
                            navigationReadings.isVMGSelected = false // stop VMG
                            modelContext.delete(waypoint)
                            
                        }
                    }
                }
            }//END OF LIST
            .navigationTitle("Waypoints")
            .navigationBarTitleDisplayMode(.inline) // displays normal title, not big
            .toolbar {
                
                Button(action: {
                    //this will present a sheet form for adding new item
                    sheetIsPresented.toggle()
                }, label: {
                    Image(systemName: "plus")
                })
                .sheet(isPresented: $sheetIsPresented, content: {
                    NavigationStack{
                        WaypointFIllForm(waypoint: Waypoints())

                    }
                })
            }
        }//END OF NAVIGATION STACK
    }//END OF BODY
}//END OF STRUCT
#Preview {
    WaypointListView()
        .modelContainer(for: Waypoints.self)
        .environment(NMEAReader())
    
}
