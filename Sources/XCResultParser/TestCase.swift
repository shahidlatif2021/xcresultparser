//
//  TestCase.swift
//  XCResultParser
//
//  Created by Shahid Latif on 12/03/2025.
//

struct TestCase: Codable {
    let name: String
    let status: String
    let duration: Double
    let errorMessage: String?
    let textCases: [String]
}
