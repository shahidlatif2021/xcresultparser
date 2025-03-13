// swift-tools-version:5.3

import Foundation
import XCResultKit

// Ensure that the user provided the xcresult path argument
if CommandLine.arguments.count < 2 {
    print("Usage: XCResultParser <path_to_xcresult>")
    exit(1)
}

let xcresultPath = CommandLine.arguments[1]

do {
    // Initialize the XCResult object from the given path
    let result = try XCResult(path: xcresultPath)

    // Print the result or you can process it further
    print("XCResult file loaded successfully!")

    // Example: Print the test summary
    let testSummary = result.testSummary
    print("Test Summary: \(testSummary)")

    // Access other parts of the result as needed
    // Example: List all failed tests
    let failedTests = result.failedTests
    if failedTests.isEmpty {
        print("No failed tests")
    } else {
        print("Failed Tests: \(failedTests)")
    }

} catch {
    print("Error parsing XCResult file: \(error)")
    exit(1)
}
