// swift-tools-version:5.6

import XCResultKit
import Foundation


// Drop the first argument, which is the executable name
let arguments = CommandLine.arguments.dropFirst()

var inputPath: String?
var outputPath: String?
var reportFormat: String? = "json"
var buildNumber: String? = "50267"
var verionsNumber: String? =  "8.47.0"

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
    case "-buildNumber":
        if index + 1 < (arguments.count + 1) {
            buildNumber = arguments[index + 1].lowercased()
        }
    case "-versionNumber":
        if index + 1 < (arguments.count + 1) {
            verionsNumber = arguments[index + 1].lowercased()
            index += 1
        }
    default:
        break
    }
    index += 1
}

// Validate required arguments
guard let input = inputPath, let output = outputPath, let format = reportFormat, let bNumber = buildNumber, let vNumber = verionsNumber else {
    print("❌ Missing required parameters")
    print("Usage: XCResultParse -input <Path> -output <Path with file> -reportFormat <json/pdf> -buildNumber <abc> -versionNumber <oxy>")
    exit(1)
}

guard format == "json" || format == "pdf" else {
    print("❌ Invalid report format. Supported formats: json, pdf")
    exit(1)
}

// Debugging logs
let tokenNotFound = "Report token not found from environment variable"
print("✅ Input File: \(input)")
print("✅ Output File: \(output)")
print("✅ Report Format: \(format)")


let bearerToken = ProcessInfo.processInfo.environment["CUSTOM_REPORT_TOKEN"]

guard let token = bearerToken else {
    print("❌ Report token is not set exiting utility")
    exit(1)
}

let xcresultParser = XCResultParser(xcResultFilePath: inputPath!, buildNumber: buildNumber!, versionNumber: verionsNumber!, outputPath: output)
let reportUploader = ReportUploader(jsonPath: outputPath!, token: token)
let imagesDirectoryPath = URL(fileURLWithPath: output).deletingLastPathComponent().path + "/\(xcresultParser.runId)"
FileHelper.createDirectoryIfNeeded(at: imagesDirectoryPath)
do {
    let results = try xcresultParser.parseResults()
    try JSONReportWriter.write(results: results, to: output)
    reportUploader.upload(testResults: results)
} catch {
    print("Error")
}
