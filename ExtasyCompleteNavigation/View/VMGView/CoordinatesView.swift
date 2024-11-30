import SwiftUI
import SwiftData
import CoreLocation

struct CoordinatesView: View {
    
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(\.modelContext) private var context
    @Bindable var lastUsedUnit: SwitchCoordinatesView
    
    let width: CGFloat
    
    var body: some View {
        ZStack {
            Text(positionLabel) // Dynamic position label
                .frame(width: width, height: width, alignment: .topLeading)
                .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
            
            if let coordinates = currentCoordinates {
                VStack {
                    Text(String(format: "%.4f", coordinates.latitude))
                    Text(String(format: "%.4f", coordinates.longitude))
                }
                .frame(width: width, height: width, alignment: .center)
                .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.20))
            } else {
                Text("No Data")
                    .frame(width: width, height: width, alignment: .center)
                    .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.20))
            }
        }
        .minimumScaleFactor(0.2)
        .onTapGesture {
            togglePosition()
        }
        .foregroundStyle(Color("display_font"))
    }
    
    // MARK: - Computed Properties
    
    /// Dynamic position label based on the current unit
    private var positionLabel: String {
        switch lastUsedUnit.position {
        case .boatCoordinates:
            return "BPOS"
        case .waypointCoordinates:
            return "WPPOS"
        }
    }
    
    /// Current coordinates to display
    private var currentCoordinates: CLLocationCoordinate2D? {
        switch lastUsedUnit.position {
        case .boatCoordinates:
            return navigationReadings.gpsData?.boatLocation
        case .waypointCoordinates:
            return navigationReadings.vmgData.markerCoordinate
        }
    }
    
    // MARK: - Methods
    
    /// Toggles between boat and waypoint coordinates
    private func togglePosition() {
        switch lastUsedUnit.position {
        case .boatCoordinates:
            lastUsedUnit.position = .waypointCoordinates
        case .waypointCoordinates:
            lastUsedUnit.position = .boatCoordinates
        }
        context.insert(lastUsedUnit) // Save the change
    }
}

#Preview {
    GeometryProvider { width, _ in
        // Mock SwitchCoordinatesView instance
        let mockSwitchCoordinates = SwitchCoordinatesView(position: .boatCoordinates)
        
        // Create a mock NMEAParser
        let mockParser = NMEAParser()
        
        // Manually set sample GPS data
        var mockGPSData = GPSData()
        mockGPSData.latitude = 42.1234
        mockGPSData.longitude = -71.5678
        mockParser.gpsData = mockGPSData
        
        // Manually set sample VMG data
        var mockVMGData = VMGData()
        mockVMGData.markerCoordinate = CLLocationCoordinate2D(latitude: 41.9876, longitude: -70.4321)
        mockParser.vmgProcessor.vmgData = mockVMGData
        
        return CoordinatesView(lastUsedUnit: mockSwitchCoordinates, width: width)
            .environment(mockParser)
            .modelContainer(for: SwitchCoordinatesView.self)
    }
    .aspectRatio(contentMode: .fit)
}
