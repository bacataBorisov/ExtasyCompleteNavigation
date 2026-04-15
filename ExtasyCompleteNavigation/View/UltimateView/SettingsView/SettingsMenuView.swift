import SwiftUI

struct SettingsMenuView: View {
    @Environment(SettingsManager.self) private var settingsManager
    @Environment(NMEAParser.self) private var navigationReadings
    @State private var showAdvancedSettings = false

    var body: some View {
        Group {
            if showAdvancedSettings {
                AdvancedSettingsView(onDone: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showAdvancedSettings = false
                    }
                })
            } else {
                List {
                    // General Settings
                    CompactRow(title: "General", icon: "gearshape.fill", destination: GeneralSettingsView())

                    // Calibration
                    CompactRow(title: "Calibration", icon: "speedometer", destination: CalibrationView())

                    // Alarms
                    CompactRow(title: "Set Alarms", icon: "exclamationmark.triangle.fill", destination: AlarmsView())

                    // Glossary
                    CompactRow(title: "View Glossary", icon: "book.fill", destination: GlossaryView())

                    // Advanced: same navigation column (map column / phone stack) — no full-screen cover.
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showAdvancedSettings = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "gearshape.2.fill")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 20))
                                .frame(width: 28, alignment: .center)
                            Text("Advanced")
                                .font(.subheadline)
                                .padding(.vertical, 6)
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(showAdvancedSettings ? "Advanced Settings" : "Settings")
        .animation(.easeInOut(duration: 0.25), value: showAdvancedSettings)
    }
}



// MARK: - CompactRow Component
struct CompactRow<Destination: View>: View {
    let title: String
    let icon: String
    let destination: Destination

    var body: some View {
        NavigationLink {
            destination
                .frame(minWidth: 1, maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 20))
                    .frame(width: 28, alignment: .center)

                Text(title)
                    .font(.subheadline)
                    .padding(.vertical, 6)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Supporting Views
struct GeneralSettingsView: View {
    @Environment(SettingsManager.self) private var settingsManager
    
    var body: some View {
        Form {
            Section("Boat") {
                TextField("Boat Name", text: Binding(
                    get: { settingsManager.boatName },
                    set: { settingsManager.boatName = $0 }
                ))
            }
            
            Section("Wind") {
                Toggle("Metric Wind (m/s)", isOn: Binding(
                    get: { settingsManager.metricWind },
                    set: { settingsManager.metricWind = $0 }
                ))
            }
            
            Section("Navigation") {
                Stepper("Alignment bar range: ±\(Int(settingsManager.tackTolerance))°",
                        value: Binding(
                            get: { settingsManager.tackTolerance },
                            set: { settingsManager.tackTolerance = $0 }
                        ),
                        in: 5...30, step: 5)

                Picker("UI + Watch refresh", selection: Binding(
                    get: { settingsManager.uiRefreshIntervalPreset },
                    set: { settingsManager.uiRefreshIntervalPreset = $0 }
                )) {
                    Text("0.5 s").tag(0)
                    Text("1 s").tag(1)
                    Text("2 s").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: .infinity)

                Picker("Distance Unit", selection: Binding(
                    get: { settingsManager.distanceUnit },
                    set: { settingsManager.distanceUnit = $0 }
                )) {
                    Text("Nautical Miles").tag(0)
                    Text("Cables").tag(1)
                    Text("Meters").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: .infinity)
            }
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
    @Environment(SettingsManager.self) private var settingsManager
    
    var body: some View {
        Form {
            Section("Depth Alarm") {
                Toggle("Enable Depth Alarm", isOn: Binding(
                    get: { settingsManager.depthAlarmEnabled },
                    set: { settingsManager.depthAlarmEnabled = $0 }
                ))
                
                if settingsManager.depthAlarmEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Threshold: \(String(format: "%.1f", settingsManager.depthAlarmThreshold)) m")
                            .font(.subheadline)

                        Slider(
                            value: Binding(
                                get: { settingsManager.depthAlarmThreshold },
                                set: { settingsManager.depthAlarmThreshold = $0 }
                            ),
                            in: 1...20,
                            step: 0.5
                        )
                        .frame(maxWidth: .infinity)

                        Text("Visual + haptic + sound alert when depth falls below this value")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .navigationTitle("Alarms")
    }
}

struct GlossaryView: View {
    private let terms: [(abbr: String, full: String, description: String)] = [
        ("AWA", "Apparent Wind Angle", "Wind angle relative to the boat's heading as felt on board"),
        ("AWD", "Apparent Wind Direction", "Compass direction the apparent wind is coming from"),
        ("AWS", "Apparent Wind Speed", "Speed of the wind as measured on the moving boat"),
        ("TWA", "True Wind Angle", "Wind angle corrected for boat speed and heading"),
        ("TWD", "True Wind Direction", "Actual compass direction the wind is coming from"),
        ("TWS", "True Wind Speed", "Actual wind speed corrected for boat movement"),
        ("COG", "Course Over Ground", "Actual direction of travel over the earth's surface"),
        ("SOG", "Speed Over Ground", "Actual speed over the earth's surface (from GPS)"),
        ("HDG", "Heading", "Direction the bow is pointing (from compass)"),
        ("VMG", "Velocity Made Good", "Speed component toward the wind or downwind — how efficiently you're sailing toward a windward or leeward target"),
        ("VMC", "Velocity Made Good to Course", "Speed component directly toward the active waypoint"),
        ("BTM", "Bearing to Mark", "Compass bearing from the boat to the active waypoint"),
        ("DTM", "Distance to Mark", "Straight-line distance to the active waypoint"),
        ("DPT", "Depth", "Water depth below the transducer"),
        ("SLG", "Speed Log", "Boat speed through the water (from hull sensor)"),
        ("DST", "Distance Log", "Cumulative distance traveled through the water"),
        ("TMP", "Sea Temperature", "Water temperature at the transducer"),
        ("ETA", "Estimated Time of Arrival", "Predicted arrival time at the active waypoint"),
        ("NM", "Nautical Mile", "1,852 meters — standard marine distance unit"),
        ("NMEA", "National Marine Electronics Association", "Standard protocol for marine instrument communication (0183)"),
    ]
    
    var body: some View {
        List(terms, id: \.abbr) { term in
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(term.abbr)
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 52, alignment: .leading)
                        .layoutPriority(1)
                    Text(term.full)
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(term.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Glossary")
    }
}

// MARK: - Preview
#Preview {
    SettingsMenuView()
        .environment(NMEAParser())
        .environment(SettingsManager())
}
