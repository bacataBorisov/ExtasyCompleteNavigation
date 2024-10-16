//
//  MapView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 14.10.23.
//

import SwiftUI
import MapKit
import CoreLocation
import SwiftData


struct MapView: View {
    
    
    
    @Environment(\.modelContext) private var modelContext
    @Environment(NMEAReader.self) private var navigationReadings
    
    @Query private var waypoints: [Waypoints]
    @Namespace var mapScope
    @State var boatAnchor = CGPoint(x: 0, y: 0)
    @State var markAnchor = CGPoint(x: 0, y: 0)
    
    @State var width = CGFloat()
    @State var height = CGFloat()
    @State var distance = CGFloat()
    @State var layline = CGFloat()
    @State var oppositeLayline = CGFloat()
    @State var tackPoint = CGPointZero
    @State var centerRadius: Double = 5000
    
    //it will be update every time user taps on the map screen
    
    var body: some View {
        
        MapReader { mapProxy in
            ZStack{
                Map(scope: mapScope){
                    
                    //MARK: - Create Marker if there is Active VMG Target
                    ForEach(waypoints){ waypoint in
                        if waypoint.isTargetSelected {
                            if let lat = waypoint.lat, let lon = waypoint.lon {
                                let marker = CLLocationCoordinate2D(latitude: lat, longitude: lon)

                                //it will create a marker for the dropped pin
                                Annotation(waypoint.title, coordinate: marker,
                                           content: {
                                    ZStack{
                                        Image(systemName: "pyramid.fill")
                                            .foregroundStyle(Color(UIColor.systemYellow))
                                    }
                                })
                            }
                        }
                    }
                    
                    if let unwrappedBoatLoacation = navigationReadings.boatLocation {

                        //the marker which will show boat's position
                        Annotation("", coordinate: unwrappedBoatLoacation,anchor: .center, content: {
                            //if there is heading - show it, if not show only position
                            //MARK: - TODO - Make better markers for the boat
                            if let unwrappedHeading = navigationReadings.magneticHeading{
                                Image(systemName: "location.north.line")
                                    .rotationEffect(Angle(degrees: unwrappedHeading))

                            } else {
                                Image(systemName: "location.fill")
                            }
                            
                        })
                        
                        //the blue circle around the boat. By changing the radius you can change the initial level of the zoom
                        MapCircle(center: unwrappedBoatLoacation, radius: centerRadius)
                            .foregroundStyle(Color(UIColor.systemOrange).opacity(0.3))
                        
                    }
                    
                }//END OF MAP
                
                //controls of the Map - need more info
                .mapControls {
                    
                    //MapPitchToggle(scope: mapScope)
                    MapCompass(scope: mapScope)
                        .mapControlVisibility(.visible)
                    //MapUserLocationButton()
                    //shows distances
                    MapScaleView()
                        .mapControlVisibility(.visible)
                }
                .mapStyle(.standard(elevation: .flat))
                
            }//END OF ZSTACK
        }//END OF MAP READER
    }//END OF BODY
}//END OF VIEW


extension CLLocationCoordinate2D {
    static let myLocation = CLLocationCoordinate2D(latitude: 43.191622, longitude: 27.927399)
}

#Preview {
    MapView()
        .environment(NMEAReader())
}
