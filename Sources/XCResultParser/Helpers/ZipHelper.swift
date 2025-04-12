//
//  ZipHelper.swift
//  XCResultParser
//
//  Created by Shahid Latif on 08/04/2025.
//

import Foundation
import ZIPFoundation

struct ZipHelper {
    func zipFolder(folderURL: URL, zipFileName: String) throws -> URL {
        let fileManager = FileManager()
        let zipURL = folderURL.deletingLastPathComponent().appendingPathComponent("\(zipFileName)")

        if fileManager.fileExists(atPath: zipURL.path) {
            try fileManager.removeItem(at: zipURL)
        }

        try fileManager.zipItem(at: folderURL, to: zipURL)
        return zipURL
    }
}
