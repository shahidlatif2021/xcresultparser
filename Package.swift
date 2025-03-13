// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "XCResultParser",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/shahidlatif2021/XCResultKit.git", .branch("main")),
        .package(url: "https://github.com/Techprimate/TPPDF.git", from: "2.6.1")
    ],
    targets: [
        .executableTarget(
            name: "XCResultParser",
            dependencies: ["XCResultKit", "TPPDF"]  // Ensure XCResultKit is correctly listed here
        ),
        .testTarget(
            name: "XCResultParserTests",
            dependencies: ["XCResultParser"]
        ),
    ]
)
