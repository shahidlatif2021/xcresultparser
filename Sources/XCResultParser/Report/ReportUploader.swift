//
//  ReportUploader.swift
//  XCResultParser
//
//  Created by Shahid Latif on 06/04/2025.
//

import Foundation

class ReportUploader {
    var jsonPath: String
    var token: String
    
    init(jsonPath: String, token: String) {
        self.jsonPath = jsonPath
        self.token = token
    }
    
    func upload(testResults: TestRunResults) {
        guard let url = URL(string: "https://automation-insights.almosafer.io/api/dump/ios") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let semaphore = DispatchSemaphore(value: 0)

        do {
            request.httpBody = try Data(contentsOf: URL(fileURLWithPath: jsonPath))

            URLSession.shared.dataTask(with: request) { data, response, error in
                defer { semaphore.signal() }
                if let error = error {
                    print("❌ Error: \(error)")
                } else if let res = response as? HTTPURLResponse {
                    print("✅ Status Code: \(res.statusCode)")
                }
                if let data = data, let responseText = String(data: data, encoding: .utf8) {
                    print("📥 Response: \(responseText)")
                }
            }.resume()

            if semaphore.wait(timeout: .now() + 60) == .timedOut {
                print("⚠️ Upload timed out")
            }
        } catch {
            print("❌ Failed to upload report: \(error)")
        }
    }
}
