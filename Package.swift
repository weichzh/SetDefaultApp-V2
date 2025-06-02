// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SetDefaultApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SetDefaultApp", targets: ["SetDefaultApp"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "SetDefaultApp",
            dependencies: [],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        )
    ]
) 