//
//  JSONReportWriter.swift
//  XCResultParser
//
//  Created by Shahid Latif on 06/04/2025.
//

import Foundation

struct JSONReportWriter {
    static func write(results: TestRunResults, to outputPath: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(results)
        try data.write(to: URL(fileURLWithPath: outputPath))
        print("✅ Test results written to \(outputPath)")
    }
}
