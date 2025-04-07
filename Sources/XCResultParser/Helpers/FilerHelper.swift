//
//  FilerHelper.swift
//  XCResultParser
//
//  Created by Shahid Latif on 06/04/2025.
//

import Foundation

class FileHelper {
    
    /// Writes Data to the specified file path
    static func write(data: Data, to outputPath: String) throws {
        let outputUrl = URL(fileURLWithPath: outputPath)
        try data.write(to: outputUrl)
        print("✅ File written to \(outputPath)")
    }

    /// Creates a directory at the given path if it doesn’t exist
    static func createDirectoryIfNeeded(at outputPath: String) {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: outputPath) {
            do {
                try fileManager.createDirectory(atPath: outputPath, withIntermediateDirectories: true, attributes: nil)
                print("📁 Created directory at \(outputPath)")
            } catch {
                print("❌ Failed to create directory: \(error)")
            }
        }
    }

    /// Reads Data from a file at a given path
    static func readData(from path: String) throws -> Data {
        let fileURL = URL(fileURLWithPath: path)
        return try Data(contentsOf: fileURL)
    }
}
