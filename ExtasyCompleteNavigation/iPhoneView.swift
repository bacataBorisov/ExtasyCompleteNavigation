import SwiftUI

struct IdentifiedView: Identifiable {
    let id = UUID()
    let view: AnyView
    let label: String
}

struct iPhoneView: View {
    @Environment(NMEAParser.self) private var navigationReadings
    
    @State private var selectedTab = 0 // Default to first view
    
    private var allViews: [IdentifiedView] {
        [
            IdentifiedView(view: AnyView(UltimateView()), label: "Ultimate"),
            IdentifiedView(view: AnyView(MultiDisplay()), label: "MultiDisplay"),
            IdentifiedView(view: AnyView(PerformanceView()), label: "Performance"),
            IdentifiedView(
                view: navigationReadings.gpsData?.isTargetSelected == true
                ? AnyView(iPhoneVMGView(waypointName: navigationReadings.gpsData?.waypointName ?? ""))
                : AnyView(WaypointListView()),
                label: navigationReadings.gpsData?.isTargetSelected == true ? "VMGView" : "WaypointList"
            )
        ]
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                MapView()
                    .frame(height: geometry.size.height * 0.5)
                    .background(Color.gray.opacity(0.1))
                
                Divider()
                
                NavigationStack {
                    TabView(selection: $selectedTab) {
                        ForEach(allViews.indices, id: \.self) { index in
                            allViews[index].view
                                .background(Color.gray.opacity(0.05))
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: geometry.size.height * 0.5)
                }
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            if let ultimateViewIndex = allViews.firstIndex(where: { $0.label == "Ultimate" }) {
                selectedTab = ultimateViewIndex
            }
        }
    }
}

// MARK: - Preview
#Preview {
    iPhoneView()
        .environment(NMEAParser())
        .environment(SettingsManager())
}
