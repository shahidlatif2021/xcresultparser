// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "XCResultParser",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/shahidlatif2021/XCResultKit.git", .branch("main")),
        .package(url: "https://github.com/Techprimate/TPPDF.git", from: "2.6.1"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0")
    ],
    targets: [
        .executableTarget(
            name: "XCResultParser",
            dependencies: ["XCResultKit", "TPPDF", .product(name: "ZIPFoundation", package: "ZIPFoundation")]
        ),
        .testTarget(
            name: "XCResultParserTests",
            dependencies: ["XCResultParser"]
        ),
    ]
)
