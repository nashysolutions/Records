// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Records",
    platforms: [
        .iOS(.v10), .macOS(.v10_12)
    ],
    products: [
        .library(
            name: "Records",
            targets: ["Records"]
        ),
    ],
    targets: [
        .target(
            name: "Records",
            dependencies: []
        ),
        .testTarget(
            name: "RecordsTests",
            dependencies: ["Records"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
