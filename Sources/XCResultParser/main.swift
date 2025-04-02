// swift-tools-version:5.6

import XCResultKit
import Foundation


// Drop the first argument, which is the executable name
let arguments = CommandLine.arguments.dropFirst()

var inputPath: String?
var outputPath: String?
var reportFormat: String? = "json"

var index = 1
while index < arguments.count {
    let arg = arguments[index]

    switch arg {
    case "-input":
        if index + 1 < (arguments.count + 1) {
            inputPath = arguments[index + 1]
            index += 1
        }
    case "-output":
        if index + 1 < (arguments.count + 1) {
            outputPath = arguments[index + 1]
            index += 1
        }
    case "-reportFormat":
        if index + 1 < (arguments.count + 1) {
            reportFormat = arguments[index + 1].lowercased()
            index += 1
        }
    default:
        break
    }
    index += 1
}

// Validate required arguments
guard let input = inputPath, let output = outputPath, let format = reportFormat else {
    print("❌ Missing required parameters")
    print("Usage: XCResultParse -input <Path> -output <Path with file> --reportFormat <json/pdf>")
    exit(1)
}

guard format == "json" || format == "pdf" else {
    print("❌ Invalid report format. Supported formats: json, pdf")
    exit(1)
}

// Debugging logs
print("✅ Input File: \(input)")
print("✅ Output File: \(output)")
print("✅ Report Format: \(format)")


// Ensure that the user provided the xcresult path argumentvar testResults: [String: TestCategory] = [:]
var testResults = [String: TestCategory]()

do {
    // Load XCResult file
    let resultFile = XCResultFile(url: URL(fileURLWithPath: inputPath!))
    let invocationRecords = resultFile.getInvocationRecord()
    let notFound = "❌ Not Found in test plan"

    let actions = invocationRecords!.actions
    
    let filteredRecords = actions.filter { record in
        // Check if testsRef is not nil and id is not nil
        return record.actionResult.testsRef?.id != nil
    }
    guard let actionResult = filteredRecords.first?.actionResult else {
        print("❌ No action result found.")
        exit(1)
    }
    
    guard let action = filteredRecords.first else {
        print("❌ No action found")
        exit(1)
    }
    
    
    let testSummaries = resultFile.getTestPlanRunSummaries(id: actionResult.testsRef?.id ?? "")
    
    let testPlanName = action.testPlanName ?? notFound
    let totalTimeTaken = timeDifferenceString(start: action.startedTime, end: action.endedTime)
    let deviceName = action.runDestination.displayName
    let deviceOS = action.runDestination.targetDeviceRecord.operatingSystemVersion
    let totalTestCases = actionResult.metrics.testsCount ?? -1
    let failedTestCases = actionResult.metrics.testsFailedCount ?? -1
    
    guard let testableSummaries = testSummaries!.summaries.first?.testableSummaries.first?.tests else {
        print("❌ No Testable summaries found")
        exit(1)
    }

    // Iterate through the test summaries
    for testSummary in testableSummaries {
        guard let testSuiteName = testSummary.name else { continue }

        // Categorize test suite
        let category = categorizeTestSuite(testSuiteName)

        // Ensure category exists
        if testResults[category] == nil {
            testResults[category] = TestCategory(name: category, testSuites: [])
        }

        // Check if the test suite already exists in the category
        if let suiteIndex = testResults[category]!.testSuites.firstIndex(where: { $0.name == testSuiteName }) {
            // Test suite exists, process subtests
            processSubtests(testSummary.subtests, in: &testResults[category]!.testSuites[suiteIndex], resultFile: resultFile)
        } else {
            // Create new test suite
            var newSuite = TestSuite(name: testSuiteName, passed: 0, failed: 0, tests: [])
            processSubtests(testSummary.subtests, in: &newSuite, resultFile: resultFile)
            testResults[category]?.testSuites.append(newSuite)
        }
    }
    
    let currentEpochTime = Int(Date().timeIntervalSince1970 * 1000)
    let output = TestRunResults(testPlanName: testPlanName, totalTimeTaken: totalTimeTaken, totalTestCases: totalTestCases, failedTestCases: failedTestCases, deviceName: deviceName, deviceOS: deviceOS, testResults: testResults, runId: "ios-\(currentEpochTime)")

    // Write results to JSON
    if reportFormat == "json" {
        try writeTestResultsToJSON(output, outputPath: outputPath!)
    } else if reportFormat == "pdf" {
        generatePDF(testResults: output, outputPath: outputPath!)
    }

} catch {
    print("❌ Error : \(error)")
    exit(1)
}

// MARK: - Helper Functions

/// Categorizes the test suite into a broader category
func categorizeTestSuite(_ testSuiteName: String) -> String {
    switch testSuiteName {
    case let name where name.starts(with: "Hotel"):
        return "Hotels"
    case let name where name.starts(with: "Activities"):
        return "Activities"
    case let name where name.starts(with: "Account"):
        return "MyAccount"
    case let name where name.starts(with: "Home"):
        return "Home"
    case let name where name.starts(with: "Flight"):
        return "Flights"
    default:
        return "Uncategorized"
    }
}

/// Processes subtests and assigns them to the corresponding test suite
func processSubtests(_ subtests: [ActionTestMetadata], in testSuite: inout TestSuite, resultFile: XCResultFile) {
    for subtest in subtests {
        var errorMessage: String?

        // Determine test result
        if subtest.testStatus == "Success" {
            testSuite.passed += 1
        } else if subtest.testStatus == "Failure" {
            if let actionSummary = resultFile.getActionTestSummary(id: subtest.summaryRef?.id ?? "") {
                let message = actionSummary.failureSummaries.first?.message
                let lineNumber = actionSummary.failureSummaries.first?.lineNumber
                errorMessage = "\(message ?? "No message") at line \(lineNumber ?? -1)"
            }
            testSuite.failed += 1
        }
        
        let testCases = textAttachments(resultFile: resultFile, subtest: subtest)
        var testCasesArray = testCases.components(separatedBy: "\n").map( { String($0) })
        if testCasesArray.count > 15 {
            testCasesArray = []
        }
        
        // Create test case object
        let testCase = TestCase(name: subtest.name ?? "", status: subtest.testStatus, duration: subtest.duration ?? 0, errorMessage: errorMessage, textCases: testCasesArray)

        // Append test case to the suite
        testSuite.tests.append(testCase)
    }
}

/// Writes the structured test results to a JSON file
func writeTestResultsToJSON(_ testResults: TestRunResults, outputPath: String) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let jsonData = try encoder.encode(testResults)
    
    let outputUrl = URL(fileURLWithPath: outputPath)
    try jsonData.write(to: outputUrl)
    
    print("✅ Test results written to \(outputPath)")
}

func timeDifferenceString(start: Date, end: Date) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .positional // Example: "1:25:42"
    
    return formatter.string(from: start, to: end) ?? "0:00:00"
}

func textAttachments(resultFile: XCResultFile, subtest: ActionTestMetadata) -> String {
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

