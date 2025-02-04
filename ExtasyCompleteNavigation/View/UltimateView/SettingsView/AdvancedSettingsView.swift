//  AdvancedSettingsView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 2.02.25.

import SwiftUI
import CloudKit

// MARK: - Advanced Settings View
struct AdvancedSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showRawNMEA = false

    var body: some View {
        NavigationView {
            List {
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

// MARK: - Preview
#Preview {
    AdvancedSettingsView()
}
