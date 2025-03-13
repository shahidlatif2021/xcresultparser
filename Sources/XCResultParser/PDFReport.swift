//
//  PDFReport.swift
//  XCResultParser
//
//  Created by Shahid Latif on 13/03/2025.
//

import TPPDF
import Foundation

func generatePDF(testResults: TestRunResults, outputPath: String) {
    let document = PDFDocument(format: .a4)
    
    // 📌 Header Section
    document.add(.headerLeft, text: "QA Automation Report")
    document.add(.contentLeft, text: "Test Plan: \(testResults.testPlanName)")
    document.add(.contentLeft, text: "Device: \(testResults.deviceName) (\(testResults.deviceOS))")
    document.add(.contentLeft, text: "Total Tests: \(testResults.totalTestCases)")
    document.add(.contentLeft, text: "Failed Tests: \(testResults.failedTestCases)")
    document.add(.contentLeft, text: "Total Time: \(testResults.totalTimeTaken)")

    document.add(space: 10)

    
    // 📌 Iterate over test categories
    for (categoryName, category) in testResults.testResults {
        document.add(.contentLeft, text: "Category: \(categoryName)")

        for suite in category.testSuites {
            document.add(.contentLeft, text: "Suite: \(suite.name)")

            // ✅ Creating a table object
            let rows = suite.tests.count + 1
            let columns = 3
            let table = PDFTable(rows: rows, columns: columns)

            // ✅ Define Table Style
            table.style = PDFTableStyleDefaults.simple
            do {
                // ✅ Setting headers
                table[0, 0].content = try PDFTableContent(content: "Test Name")
                table[0, 1].content = try PDFTableContent(content: "Status")
                table[0, 2].content = try PDFTableContent(content: "Duration (s)")
                
                // ✅ Set style for all header cells
                //            table[0, 0...2].allCellsStyle = PDFTableStyleDefaults.header
                
                // ✅ Adding Test Case Data
                for (index, testCase) in suite.tests.enumerated() {
                    table[index + 1, 0].content = try PDFTableContent(content: testCase.name)
                    table[index + 1, 1].content = try PDFTableContent(content: testCase.status)
                    table[index + 1, 2].content = try PDFTableContent(content: String(format: "%.2f", testCase.duration))
                    
                    //                table[index + 1, 0...2].allCellsStyle = PDFTableStyleDefaults.row
                    //                table[index + 1, 0...2].allCellsAlignment = .center
                }
            } catch {
                print("❌ Error generating PDF: \(error.localizedDescription)")
            }

            // ✅ Add the table to the document
            document.add(table: table)
            document.add(space: 5)
        }
        document.add(space: 10)
    }

    // 📌 Save PDF
    do {
        let url = URL(fileURLWithPath: outputPath)
        let generator = PDFGenerator(document: document)
        try generator.generate(to: url)
        print("✅ PDF successfully saved at \(outputPath)")
    } catch {
        print("❌ Error generating PDF: \(error.localizedDescription)")
    }
}








