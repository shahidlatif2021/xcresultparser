//
//  Categorizer.swift
//  XCResultParser
//
//  Created by Shahid Latif on 06/04/2025.
//


enum Categorizer {
    static func categorize(testSuiteName: String) -> String {
        switch testSuiteName {
        case let name where name.starts(with: "Hotel"): return "Hotels"
        case let name where name.starts(with: "Activities"): return "Activities"
        case let name where name.starts(with: "MyAccount"): return "MyAccount"
        case let name where name.starts(with: "Home"): return "Home"
        case let name where name.starts(with: "Flight"): return "Flights"
        default: return "Uncategorized"
        }
    }
}
