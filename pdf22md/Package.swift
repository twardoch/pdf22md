// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pdf22md",
    platforms: [
        .macOS(.v12) // Required for async/await
    ],
    products: [
        // Library product for programmatic usage
        .library(
            name: "PDF22MD",
            targets: ["PDF22MD"]
        ),
        .executable(
            name: "pdf22md",
            targets: ["PDF22MDCli"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        // Main library target
        .target(
            name: "PDF22MD",
            dependencies: [],
            path: "Sources/PDF22MD",
            swiftSettings: [
                .define("VERSION", .when(platforms: [.macOS]))
            ]
        ),
        .executableTarget(
            name: "PDF22MDCli",
            dependencies: [
                "PDF22MD",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/PDF22MDCli"
        ),
        // Test target
        .testTarget(
            name: "PDF22MDTests",
            dependencies: ["PDF22MD"],
            path: "Tests/PDF22MDTests"
        )
    ]
) 