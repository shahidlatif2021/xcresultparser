//
//  Models.swift
//  XCResultParser
//
//  Created by Shahid Latif on 06/04/2025.
//

import Foundation

struct TestRunResults: Codable {
    let testPlanName: String
    let totalTimeTaken: String
    let totalTestCases: Int
    let failedTestCases: Int
    let deviceName: String
    let deviceOS: String
    let testResults: [String: TestCategory]
    let runId: String
    let buildNumber: String
    let versionNumber: String
}

struct TestCategory: Codable {
    let name: String
    var testSuites: [TestSuite]
}

struct TestSuite: Codable {
    let name: String
    var passed: Int
    var failed: Int
    var tests: [TestCase]
}

struct TestCase: Codable {
    let name: String
    let status: String?
    let duration: Double
    let errorMessage: String?
    let textCases: [String]
    let testImages:[String]?
}
