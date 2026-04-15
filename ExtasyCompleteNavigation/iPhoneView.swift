import SwiftUI

struct iPhoneView: View {
    @Environment(NMEAParser.self) private var navigationReadings
    
    @AppStorage("lastSelectedTab") private var selectedTab: Int = 0
    
    private var isTargetSelected: Bool {
        navigationReadings.gpsData?.isTargetSelected == true
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                MapView()
                    .frame(height: geometry.size.height / 2)

                Divider()

                NavigationStack {
                    TabView(selection: $selectedTab) {
                        UltimateView()
                            .background(Color.gray.opacity(0.05))
                            .tag(0)
                        
                        MultiDisplay()
                            .background(Color.gray.opacity(0.05))
                            .tag(1)
                        
                        PerformanceView()
                            .background(Color.gray.opacity(0.05))
                            .tag(2)
                        
                        Group {
                            if isTargetSelected {
                                iPhoneVMGView(waypointName: navigationReadings.gpsData?.waypointName ?? "")
                            } else {
                                WaypointListView()
                            }
                        }
                        .background(Color.gray.opacity(0.05))
                        .tag(3)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
                .frame(height: geometry.size.height / 2)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview
#Preview {
    iPhoneView()
        .environment(NMEAParser())
        .environment(SettingsManager())
}
