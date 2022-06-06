// swift-tools-version:5.6

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
