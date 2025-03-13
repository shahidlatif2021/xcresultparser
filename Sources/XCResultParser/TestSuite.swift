//
//  TestSuite.swift
//  XCResultParser
//
//  Created by Shahid Latif on 12/03/2025.
//

/// Represents a test suite containing multiple test cases
struct TestSuite: Codable {
    let name: String
    var passed: Int
    var failed: Int
    var tests: [TestCase]
}
