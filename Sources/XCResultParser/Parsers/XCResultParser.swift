//
//  XCResultParser.swift
//  XCResultParser
//
//  Created by Shahid Latif on 06/04/2025.
//

import Foundation
import XCResultKit

class XCResultParser {
    private let resultFile: XCResultFile
    private let buildNumber: String
    private let versionNumber: String
    private let outputPath: String
    var testRun: String?
    let runId = "ios-\(Int(Date().timeIntervalSince1970 * 1000))"

    init(xcResultFilePath: String, buildNumber: String, versionNumber: String, outputPath: String) {
        self.buildNumber = buildNumber
        self.versionNumber = versionNumber
        self.outputPath = outputPath
        self.resultFile = XCResultFile(url: URL(fileURLWithPath: xcResultFilePath))
    }

    func parseResults() throws -> TestRunResults {
        guard let invocationRecords = resultFile.getInvocationRecord() else {
            throw NSError(domain: "XCResult", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invocation records not found"])
        }

        let actions = invocationRecords.actions.filter { $0.actionResult.testsRef?.id != nil }
        guard let action = actions.first else {
            throw NSError(domain: "XCResult", code: 2, userInfo: [NSLocalizedDescriptionKey: "No test action found"])
        }
        
        let result = action.actionResult

        let summaries = resultFile.getTestPlanRunSummaries(id: result.testsRef?.id ?? "")
        guard let testableSummaries = summaries?.summaries.first?.testableSummaries.first?.tests else {
            throw NSError(domain: "XCResult", code: 3, userInfo: [NSLocalizedDescriptionKey: "No testable summaries found"])
        }

        var testResults: [String: TestCategory] = [:]
        for summary in testableSummaries {
            guard let suiteName = summary.name else { continue }
            let category = Categorizer.categorize(testSuiteName: suiteName)

            if testResults[category] == nil {
                testResults[category] = TestCategory(name: category, testSuites: [])
            }

            if let index = testResults[category]!.testSuites.firstIndex(where: { $0.name == suiteName }) {
                processSubtests(summary.subtests, into: &testResults[category]!.testSuites[index])
            } else {
                var newSuite = TestSuite(name: suiteName, passed: 0, failed: 0, tests: [])
                processSubtests(summary.subtests, into: &newSuite)
                testResults[category]?.testSuites.append(newSuite)
            }
        }

        let testPlanName = action.testPlanName ?? "❌ Not Found in test plan"
        let duration = FormatterHelper.timeDifference(start: action.startedTime, end: action.endedTime)
        

        return TestRunResults(
            testPlanName: testPlanName,
            totalTimeTaken: duration,
            totalTestCases: result.metrics.testsCount ?? -1,
            failedTestCases: result.metrics.testsFailedCount ?? -1,
            deviceName: action.runDestination.displayName,
            deviceOS: action.runDestination.targetDeviceRecord.operatingSystemVersion,
            testResults: testResults,
            runId: runId,
            buildNumber: buildNumber,
            versionNumber: versionNumber
        )
    }

    private func processSubtests(_ subtests: [ActionTestMetadata], into suite: inout TestSuite) {
        for subtest in subtests {
            var errorMessage: String?
            var testCaseImages: [String]?

            if subtest.testStatus == "Success" {
                suite.passed += 1
            } else if subtest.testStatus == "Failure" {
                if let summary = resultFile.getActionTestSummary(id: subtest.summaryRef?.id ?? "") {
                    errorMessage = "\(summary.failureSummaries.first?.message ?? "No message") at line \(summary.failureSummaries.first?.lineNumber ?? -1)"
                    suite.failed += 1

                    let testname = subtest.name?.replacingOccurrences(of: "()", with: "") ?? ""
                    let testFilePath = "/\(testname)/\(summary.repetitionPolicySummary?.iteration ?? 1)"
                    
                    FileHelper.createDirectoryIfNeeded(at: "\(imagesDirectoryPath)/\(testFilePath)")
                    testCaseImages = getAttachmentsAndSubactivities(resultFile: resultFile, subtest: subtest, imageDirectory: imagesDirectoryPath, testFilePath: testFilePath)
                }
            }

            let attachments = textAttachments(resultFile: resultFile, subtest: subtest)
            var testCases = attachments.components(separatedBy: "\n").map { $0 }
            if testCases.count > 15 { testCases = [] }

            let testCase = TestCase(
                name: subtest.name ?? "",
                status: subtest.testStatus,
                duration: subtest.duration ?? 0,
                errorMessage: errorMessage,
                textCases: testCases,
                testImages: testCaseImages
            )
            suite.tests.append(testCase)
        }
    }
    
    private func textAttachments(resultFile: XCResultFile, subtest: ActionTestMetadata) -> String {
        guard let activitySummaries = resultFile.getActionTestSummary(id: subtest.summaryRef?.id ?? "")?.activitySummaries else {
            return ""
        }

        return activitySummaries
            .flatMap { $0.attachments }
            .compactMap { attachment -> String? in
                guard attachment.uniformTypeIdentifier == "public.plain-text",
                      let data = resultFile.getPayload(id: attachment.payloadRef?.id ?? "")
                else { return nil }
                return String(data: data, encoding: .utf8)
            }
            .first ?? "" // Return only the first valid attachment text
    }

    private func getAttachmentsAndSubactivities(resultFile: XCResultFile, subtest: ActionTestMetadata, imageDirectory: String, testFilePath: String) -> [String] {
        guard let activitySummaries = resultFile.getActionTestSummary(id: subtest.summaryRef?.id ?? "")?.activitySummaries else {
            return []
        }

        var imageData: [Data] = []
        var imagesPath = [String]()
        
        // Iterate through each activity summary
        for activitySummary in activitySummaries {
            // Process attachments for each activity summary
            let attachments = activitySummary.attachments.filter { $0.uniformTypeIdentifier == "public.jpeg" }
            
            for attachment in attachments {
                if let data = resultFile.getPayload(id: attachment.payloadRef?.id ?? "") {
                    let imageFileName = attachment.filename ?? UUID().uuidString
                    
                    let fileURL = URL(fileURLWithPath: "\(imageDirectory)\(testFilePath)").appendingPathComponent(imageFileName)

                    do {
                        try data.write(to: fileURL)
                        imagesPath.append(testFilePath + "/" + imageFileName)
                    } catch {
                        print("Failed to save image: \(error)")
                    }
                    
                    imageData.append(data)
                }
            }

            // Process subactivities for each activity summary
            for subactivity in activitySummary.subactivities {
                let subactivityAttachments = subactivity.attachments.filter { $0.uniformTypeIdentifier == "public.jpeg" }

                for attachment in subactivityAttachments {
                    if let data = resultFile.getPayload(id: attachment.payloadRef?.id ?? "") {
                        let imageFileName = attachment.filename ?? UUID().uuidString
                        
                        let fileURL = URL(fileURLWithPath: "\(imageDirectory)\(testFilePath)").appendingPathComponent(imageFileName)

                        do {
                            try data.write(to: fileURL)
                            imagesPath.append(testFilePath + "/" + imageFileName)
                        } catch {
                            print("Failed to save image: \(error)")
                        }
                    }
                }
            }
        }
        
        return imagesPath
    }
}
