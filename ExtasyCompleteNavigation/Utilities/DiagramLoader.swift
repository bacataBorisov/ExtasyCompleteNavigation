//
//  DiagramLoader.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 26.11.24.
//


import Foundation

class DiagramLoader {
    /// Loads the polar diagram from a text file and parses it into a 2D array of `Double`.
    ///
    /// - Parameter fileName: The name of the file (without extension) to load the diagram from.
    /// - Returns: A 2D array representing the polar diagram or `nil` if the file cannot be loaded or parsed.
    static func loadDiagram(from fileName: String) -> [[Double]]? {
        // Locate the file in the main bundle
        guard let filePath = Bundle.main.path(forResource: fileName, ofType: "txt") else {
            print("File \(fileName) not found in bundle.")
            return nil
        }
        
        // Read the file content
        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            return parseDiagram(from: content)
        } catch {
            print("Failed to read file \(fileName): \(error.localizedDescription)")
            return nil
        }
    }

    /// Parses the content of the diagram file into a 2D array of `Double`.
    ///
    /// - Parameter content: The content of the diagram file as a single string.
    /// - Returns: A 2D array of `Double` values.
    private static func parseDiagram(from content: String) -> [[Double]] {
        var diagram: [[Double]] = []
        
        // Split the content into lines and parse each line
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            // Skip empty lines
            guard !line.isEmpty else { continue }
            
            // Split the line into components, ignoring extra spaces
            let tokens = line.split(separator: " ").compactMap { Double($0) }
            
            // Ensure the line contains valid numeric data
            if !tokens.isEmpty {
                diagram.append(tokens)
            }
        }
        
        return diagram
    }
}
