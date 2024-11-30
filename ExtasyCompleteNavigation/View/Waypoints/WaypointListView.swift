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
    
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var waypoints: [Waypoints]
    @State private var sheetIsPresented = false

    var body: some View {
        NavigationStack {
            Group {
                if waypoints.isEmpty {
                    EmptyStateView()
                } else {
                    WaypointsList()
                }
            }
            .navigationTitle("Waypoints")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        sheetIsPresented.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $sheetIsPresented) {
                NavigationStack {
                    WaypointFIllForm(waypoint: Waypoints())
                }
            }
        }
    }
    
    //NOTE: - @ViewBuilder is a SwiftUI attribute that lets you construct complex views by returning multiple subviews in a declarative manner. It enables the creation of conditional, modular, and composable views without explicitly wrapping them in containers like VStack, HStack, or Group.
    
    @ViewBuilder
    private func EmptyStateView() -> some View {
        VStack {
            Image(systemName: "map.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No waypoints added yet.")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func WaypointsList() -> some View {
        List {
            ForEach(waypoints) { waypoint in
                WaypointRow(waypoint: waypoint)
            }
        }
    }
    
    private func WaypointRow(waypoint: Waypoints) -> some View {
        NavigationLink {
            WaypointDetailedView(waypoint: waypoint)
        } label: {
            Text(waypoint.title)
        }
        .swipeActions {
            Button(role: .destructive) {
                modelContext.delete(waypoint)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
#Preview {
    WaypointListView()
        .modelContainer(for: Waypoints.self)
        .environment(NMEAParser())

}

////
////  WaypointView.swift
////  ExtasyCompleteNavigation
////
////  Created by Vasil Borisov on 15.01.24.
////
//
//import SwiftUI
//import SwiftData
//import CoreLocation
//
//struct WaypointListView: View {
//    
//    @Environment(NMEAParser.self) private var navigationReadings
//    @Environment(\.dismiss) var dismiss
//    @State private var sheetIsPresented = false
//    //SwiftData variables that are needed
//    @Environment(\.modelContext) private var modelContext
//    @Query private var waypoints: [Waypoints]
//    
//    
//    var body: some View {
//        
//        NavigationStack {
//            List(){
//                //display all waypoints entered in swiftdatabase
//                ForEach(waypoints) { waypoint in
//                    
//                    NavigationLink{
//                        WaypointDetailedView(waypoint: waypoint)
//                    } label: {
//                        Text(waypoint.title)
//                    }
//                    
//                    //delete the entry by swiping on the left
//                    .swipeActions(allowsFullSwipe: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/) {
//                        Button("Delete", systemImage: "trash", role: .destructive) {
//                            
//                            //waypoint.isTargetSelected = false // remove the target from the map
//                            //navigationReadings.isVMGSelected = false // stop VMG
//                            modelContext.delete(waypoint)
//                        }
//                    }
//                }
//            }//END OF LIST
//            .navigationTitle("Waypoints")
//            .navigationBarTitleDisplayMode(.inline) // displays normal title, not big
//            .toolbar {
//                
//                Button(action: {
//                    //this will present a sheet form for adding new item
//                    sheetIsPresented.toggle()
//                }, label: {
//                    Image(systemName: "plus")
//                })
//                .sheet(isPresented: $sheetIsPresented, content: {
//                    NavigationStack{
//                        WaypointFIllForm(waypoint: Waypoints())
//
//                    }
//                })
//            }
//        }//END OF NAVIGATION STACK
//    }//END OF BODY
//}//END OF STRUCT
//#Preview {
//    WaypointListView()
//        .modelContainer(for: Waypoints.self)
//        .environment(NMEAParser())
//    
//}
