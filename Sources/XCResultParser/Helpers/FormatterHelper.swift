//
//  FormatterHelper.swift
//  XCResultParser
//
//  Created by Shahid Latif on 06/04/2025.
//

import Foundation

enum FormatterHelper {
    static func timeDifference(start: Date, end: Date) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        return formatter.string(from: start, to: end) ?? "0:00:00"
    }
}
