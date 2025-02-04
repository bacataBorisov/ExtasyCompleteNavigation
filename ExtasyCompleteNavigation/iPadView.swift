import SwiftUI

struct iPadView: View {
    @Environment(NMEAParser.self) private var navigationReadings
    @State private var isTargetSelected: Bool = false // State for target selection animation

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 16) {
                // Left Section: UltimateView and Performance Bars
                VStack(spacing: 0) {
                    NavigationStack {
                        UltimateView()
                            .frame(height: geometry.size.height * 0.65)
                            //.background(Color.red.opacity(0.2)) // Debugging background
                    }

                    PerformanceView()
                        .frame(height: geometry.size.height * 0.35)
                        //.background(Color.blue.opacity(0.2)) // Debugging background
                }
                .frame(maxHeight: geometry.size.height)
                // Right Section: MultiDisplay and VMGSimpleView
                VStack(spacing: 0) {
                    if isTargetSelected {
                        MultiDisplay()
                            .frame(height: geometry.size.height * 0.65)
                        NavigationStack {
                            VMGSimpleView(waypointName: navigationReadings.gpsData?.waypointName ?? "Mark Unknown")
                                .frame(height: geometry.size.height * 0.35)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        }

                    } else {
                        MultiDisplay()
                            .frame(height: geometry.size.height * 0.65)
                        NavigationStack {
                            InfoWaypointSection()
                                .frame(height: geometry.size.height * 0.35)
                        }

                    }
                }
                .frame(maxHeight: geometry.size.height)
            }
        }
        .onAppear {
            updateTargetState()
        }
        .onChange(of: navigationReadings.gpsData?.isTargetSelected) {
            updateTargetState()
        }
        .animation(.easeInOut(duration: 1), value: isTargetSelected) // Ensure smooth animations
    }

    // MARK: - Update Target State
    private func updateTargetState() {
        isTargetSelected = navigationReadings.gpsData?.isTargetSelected ?? false
    }
}

#Preview {
    iPadView()
        .environment(NMEAParser())
        .environment(SettingsManager())
        .modelContainer(for: [
            Waypoints.self,
        ])
}
