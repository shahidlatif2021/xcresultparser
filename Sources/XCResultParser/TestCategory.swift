//
//  TestCategory.swift
//  XCResultParser
//
//  Created by Shahid Latif on 12/03/2025.
//


struct TestCategory: Codable {
    let name: String
    var testSuites: [TestSuite]
}
