//
//  TestReport.swift
//  XCResultParser
//
//  Created by Shahid Latif on 12/03/2025.
//

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
