import SwiftUI

struct IdentifiedView: Identifiable, Equatable {
    let id: UUID = UUID()
    let view: AnyView
    let label: String

    static func == (lhs: IdentifiedView, rhs: IdentifiedView) -> Bool {
        lhs.id == rhs.id
    }
}

struct iPhoneView: View {
    @Environment(NMEAParser.self) private var navigationReadings

    // Fixed views for bottom section
    @State private var allViews: [IdentifiedView] = [
        IdentifiedView(view: AnyView(UltimateView()), label: "Ultimate"),
        IdentifiedView(view: AnyView(MultiDisplay()), label: "MultiDisplay"),
        IdentifiedView(view: AnyView(PerformanceView()), label: "Performance"),
        IdentifiedView(view: AnyView(WaypointListView()), label: "WaypointList")
    ]

    @State private var selectedTab: Int = 0 // Track selected tab

    init() {
        if let ultimateViewIndex = allViews.firstIndex(where: { $0.label == "Ultimate" }) {
            _selectedTab = State(initialValue: ultimateViewIndex)
        } else {
            _selectedTab = State(initialValue: 0)  // Default to first index if not found
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Fixed Map View at the top
                MapView()
                    .frame(height: geometry.size.height * 0.5)
                    .background(Color.gray.opacity(0.1))

                Divider() // Separator line

                NavigationStack {
                    // Swipeable views in the bottom section with page indicators
                    TabView(selection: $selectedTab) {
                        ForEach(availableBottomViews.indices, id: \.self) { index in
                            availableBottomViews[index].view
                                .background(Color.gray.opacity(0.05))
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Enable page dots
                    .frame(height: geometry.size.height * 0.5)
                }
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            updateBottomViews()
        }
        .onChange(of: navigationReadings.gpsData?.isTargetSelected ?? false) { _, _ in
            updateBottomViews()
        }
    }

    // Dynamically manage bottom views based on waypoint selection
    private var availableBottomViews: [IdentifiedView] {
        if navigationReadings.gpsData?.isTargetSelected == true,
           let waypointName = navigationReadings.gpsData?.waypointName, !waypointName.isEmpty {
            return allViews.map { view in
                view.label == "WaypointList"
                    ? IdentifiedView(view: AnyView(iPhoneVMGView(waypointName: waypointName)), label: "VMGView")
                    : view
            }
        } else {
            return allViews
        }
    }

    private func updateBottomViews() {
        if navigationReadings.gpsData?.isTargetSelected == true,
           let waypointName = navigationReadings.gpsData?.waypointName, !waypointName.isEmpty {
            allViews[3] = IdentifiedView(view: AnyView(iPhoneVMGView(waypointName: waypointName)), label: "VMGView")
        } else {
            allViews[3] = IdentifiedView(view: AnyView(WaypointListView()), label: "WaypointList")
        }
    }
}

// MARK: - Preview
#Preview {
    iPhoneView()
        .environment(NMEAParser()) // Inject required environment objects
        .environment(SettingsManager())
}
