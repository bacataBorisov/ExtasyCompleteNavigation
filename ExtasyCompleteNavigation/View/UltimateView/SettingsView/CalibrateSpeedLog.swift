import SwiftUI

struct CalibrateSpeedLog: View {
    
    @Environment(SettingsManager.self) private var settingsManager
    @Environment(NMEAParser.self) private var navigationReadings
    
    @State private var calibrationCoefficient: String = ""
    @State private var manualCalibrationEnabled: Bool = false
    @State private var sogComparisonEnabled: Bool = false
    @State private var calculatedCoefficient: Double?
    @State private var speedLogValues: [Double] = [] // Stores the last N speed log values for SMA
    @State private var sogValues: [Double] = [] // Stores the last N SOG values for SMA
    @State private var lastAppliedCoefficient: String = "N/A" // Track last applied coefficient
    private let windowSize = 5 // Number of values to include in the moving average

    var body: some View {
        
        
        VStack {
            // Manual Calibration Section
            Section {
                Toggle("Manual Calibration", isOn: $manualCalibrationEnabled.animation())
            }

            if manualCalibrationEnabled {
                Section {
                    Text("Enter Calibration Coefficient")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("Coefficient", text: $calibrationCoefficient)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                        
                        MinimalButton(title: "Apply") {
                            applyManualCalibration()
                            calibrationCoefficient = "0.00"  // Reset after applying
                        }
                    }
                    
                    Text("Last Applied: \(lastAppliedCoefficient)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            Divider()
            // Compare with SOG Section
            Section {
                Toggle("Compare with SOG", isOn: $sogComparisonEnabled.animation())
            }

            if sogComparisonEnabled, let coefficient = calculatedCoefficient {
                Section {
                    Text("Suggested Coefficient (SMA): \(String(format: "%.3f", coefficient))")
                        .font(.footnote)
                        .foregroundColor(.green)
                    
                    MinimalButton(title: "Apply Suggested") {
                        calibrationCoefficient = String(format: "%.3f", coefficient)
                        applyManualCalibration()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Calibrate Speed Log")
        .onAppear {
            loadCurrentCalibration()
        }
        .onChange(of: sogComparisonEnabled) {
            if sogComparisonEnabled {
                startMonitoringSOG()
            }
        }
        .padding(.all)
        Spacer()
    }

    // MARK: - Methods
    
    private func loadCurrentCalibration() {
        calibrationCoefficient = String(format: "%.3f", settingsManager.calibrationCoefficient)
        lastAppliedCoefficient = calibrationCoefficient  // Load previously set coefficient
    }

    private func applyManualCalibration() {
        if let coefficient = Double(calibrationCoefficient) {
            settingsManager.calibrationCoefficient = coefficient
            navigationReadings.hydroProcessor.updateCalibrationCoeff(value: coefficient)
            lastAppliedCoefficient = String(format: "%.3f", coefficient)
            debugLog("Manual calibration applied: \(coefficient)")
        } else {
            debugLog("Invalid manual calibration coefficient.")
        }
    }

    private func startMonitoringSOG() {
        // Periodically update the calculated coefficient
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateCalculatedCoefficient()
        }
    }

    private func updateCalculatedCoefficient() {
        guard sogComparisonEnabled,
              let sog = navigationReadings.gpsData?.speedOverGround,
              let speedLog = navigationReadings.hydroData?.boatSpeedLag,
              speedLog > 0 else {
            calculatedCoefficient = nil
            return
        }

        // Add the latest readings to the arrays
        speedLogValues.append(speedLog)
        sogValues.append(sog)

        // Ensure the arrays do not exceed the window size
        if speedLogValues.count > windowSize {
            speedLogValues.removeFirst()
        }
        if sogValues.count > windowSize {
            sogValues.removeFirst()
        }

        // Calculate the SMA (Simple Moving Average)
        if speedLogValues.count == windowSize, sogValues.count == windowSize {
            let avgSpeedLog = speedLogValues.reduce(0, +) / Double(windowSize)
            let avgSOG = sogValues.reduce(0, +) / Double(windowSize)
            calculatedCoefficient = avgSOG / avgSpeedLog
            debugLog("Calculated coefficient (SMA): \(String(format: "%.3f", calculatedCoefficient ?? 0))")
        }
    }
}

// MARK: - Minimal Button Style
struct MinimalButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.all, 2)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.gradient)
                )
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        CalibrateSpeedLog()
            .environment(SettingsManager())
            .environment(NMEAParser())
    }
}
