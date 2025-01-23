import SwiftUI

struct SettingsMenuView: View {
    @Environment(SettingsManager.self) private var settingsManager
    @Environment(NMEAParser.self) private var navigationReadings
    @State private var showRawNMEA = false
    
    var body: some View {
        List {
            // General Settings
            CompactRow(title: "General", icon: "gearshape.fill", destination: GeneralSettingsView())
            
            // Calibration
            CompactRow(title: "Calibration", icon: "speedometer", destination: CalibrationView())
            
            // Alarms
            CompactRow(title: "Set Alarms", icon: "exclamationmark.triangle.fill", destination: AlarmsView())
            
            // Glossary
            CompactRow(title: "View Glossary", icon: "book.fill", destination: GlossaryView())
            
            // Advanced Settings (Full-screen Navigation)
            Button(action: { showRawNMEA.toggle() }) {
                CompactRow(title: "Advanced", icon: "gearshape.2.fill", destination: EmptyView())
            }
            .buttonStyle(.plain)
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(8)
        .navigationTitle("Settings")
        .fullScreenCover(isPresented: $showRawNMEA) {
            ReadRawNMEA()
        }
    }
}

// MARK: - CompactRow Component
struct CompactRow<Destination: View>: View {
    let title: String
    let icon: String
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.gray) // Matches system accent color
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.subheadline) // Adjust font size
                    .padding(.vertical, 6) // Add compact vertical padding
            }
        }
    }
}

// MARK: - Supporting Views
struct GeneralSettingsView: View {
    @Environment(SettingsManager.self) private var settingsManager
    
    var body: some View {
        Form {
            Toggle("Metric Wind", isOn: Binding(
                get: { settingsManager.metricWind },
                set: { settingsManager.metricWind = $0 }
            ))
            
            Stepper("Tack Tolerance: \(Int(settingsManager.tackTolerance))°",
                    value: Binding(
                        get: { settingsManager.tackTolerance },
                        set: { settingsManager.tackTolerance = $0 }
                    ),
                    in: 1...20)
        }
        .navigationTitle("General Settings")
    }
}

struct CalibrationView: View {
    var body: some View {
        List {
            CompactRow(title: "Calibrate Speed Log", icon: "tachometer", destination: CalibrateSpeedLog())
        }
        .navigationTitle("Calibration")
    }
}

struct AlarmsView: View {
    var body: some View {
        Text("Set and manage your alarms here.")
            .font(.headline)
            .padding()
            .navigationTitle("Alarms")
    }
}

struct GlossaryView: View {
    var body: some View {
        Text("View the glossary of terms here.")
            .font(.headline)
            .padding()
            .navigationTitle("Glossary")
    }
}

// MARK: - Preview
#Preview {
    SettingsMenuView()
        .environment(NMEAParser())
        .environment(SettingsManager())
}
