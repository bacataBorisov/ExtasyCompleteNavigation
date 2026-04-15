import SwiftUI

struct iPadView: View {
    @Environment(NMEAParser.self) private var navigationReadings

    @State private var lowerInstrumentPanel: Int = 0

    private var isTargetSelected: Bool {
        navigationReadings.gpsData?.isTargetSelected ?? false
    }
    
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
                    
                    VStack(spacing: 8) {
                        Picker("Lower panel", selection: $lowerInstrumentPanel) {
                            Text("Performance").tag(0)
                            Text("Polar").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 12)

                        Group {
                            if lowerInstrumentPanel == 0 {
                                PerformanceView()
                            } else {
                                PolarInstrumentView()
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .frame(height: geometry.size.height * 0.35)
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
        .animation(.easeInOut(duration: 1), value: isTargetSelected) // Ensure smooth animations
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
