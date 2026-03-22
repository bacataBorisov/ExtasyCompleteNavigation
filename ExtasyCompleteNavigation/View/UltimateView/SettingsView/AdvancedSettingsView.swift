//  AdvancedSettingsView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 2.02.25.

import SwiftUI
import CloudKit

// MARK: - Advanced Settings View
struct AdvancedSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(SettingsManager.self) private var settingsManager
    @State private var showRawNMEA = false

    var body: some View {
        NavigationView {
            List {
                // Sensor Smoothing
                Section {
                    SmoothingRow(
                        label: "Wind",
                        detail: "AWA · TWA · AWS · TWS",
                        level: Binding(
                            get: { settingsManager.windDamping },
                            set: { settingsManager.windDamping = $0; navigationReadings.updateWindDamping(level: $0) }
                        )
                    )
                    SmoothingRow(
                        label: "Speed & Course",
                        detail: "SOG · COG",
                        level: Binding(
                            get: { settingsManager.speedDamping },
                            set: { settingsManager.speedDamping = $0; navigationReadings.updateSpeedDamping(level: $0) }
                        )
                    )
                    SmoothingRow(
                        label: "Heading",
                        detail: "HDG",
                        level: Binding(
                            get: { settingsManager.headingDamping },
                            set: { settingsManager.headingDamping = $0; navigationReadings.updateHeadingDamping(level: $0) }
                        )
                    )
                    SmoothingRow(
                        label: "Depth & Hydro",
                        detail: "DPT · SWT · BSPD",
                        level: Binding(
                            get: { settingsManager.hydroDamping },
                            set: { settingsManager.hydroDamping = $0; navigationReadings.updateHydroDamping(level: $0) }
                        )
                    )
                } header: {
                    Text("Sensor Smoothing")
                } footer: {
                    Text("0 = raw signal, no filtering  ·  11 = maximum damping. Higher values reduce noise but slow response to real changes.")
                }
                // Read NMEA Button
                Button(action: {
                    showRawNMEA.toggle()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                        Text("Read NMEA")
                            .font(.subheadline)
                            .padding(.vertical, 6)
                    }
                }
                .buttonStyle(.plain)
                
                // Export CSV Button
                Button(action: {
                    exportCSVFiles()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                        Text("Export CSV")
                            .font(.subheadline)
                            .padding(.vertical, 6)
                    }
                }
                .buttonStyle(.plain)

                // Sync to iCloud Button
                Button(action: {
                    syncFilesToiCloud()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "icloud.and.arrow.up")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                        Text("Sync to iCloud")
                            .font(.subheadline)
                            .padding(.vertical, 6)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Advanced Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showRawNMEA) {
            ReadRawNMEA()
        }
    }
    
    // Export CSV Functionality
    private func exportCSVFiles() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        let csvFiles = try? fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles).filter { $0.pathExtension == "csv" }

        guard let filesToShare = csvFiles, !filesToShare.isEmpty else {
            debugLog("No CSV files available to share.")
            return
        }

        let activityVC = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
        }
    }

    // MARK: - Sync CSV Files to iCloud
    func syncFilesToiCloud() {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first,
              let iCloudURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
            debugLog("iCloud Drive is not available.")
            return
        }

        do {
            // Ensure the iCloud Documents directory exists
            if !fileManager.fileExists(atPath: iCloudURL.path) {
                try fileManager.createDirectory(at: iCloudURL, withIntermediateDirectories: true, attributes: nil)
                debugLog("Created iCloud Documents directory.")
            }

            let csvFiles = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles).filter { $0.pathExtension == "csv" }

            for file in csvFiles {
                let destinationURL = iCloudURL.appendingPathComponent(file.lastPathComponent)
                if !fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.setUbiquitous(true, itemAt: file, destinationURL: destinationURL)
                    debugLog("File \(file.lastPathComponent) synced to iCloud.")
                } else {
                    debugLog("File \(file.lastPathComponent) already exists in iCloud.")
                }
            }
        } catch {
            debugLog("Failed to sync files to iCloud: \(error)")
        }
    }
}

// MARK: - SmoothingRow
private struct SmoothingRow: View {
    let label: String
    let detail: String
    @Binding var level: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.subheadline)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(level)")
                    .font(.system(.body, design: .monospaced).bold())
                    .frame(minWidth: 24, alignment: .trailing)
                Stepper("", value: $level, in: 0...11)
                    .labelsHidden()
            }
            // Visual bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * CGFloat(level) / 11.0, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    AdvancedSettingsView()
        .environment(NMEAParser())
        .environment(SettingsManager())
}
