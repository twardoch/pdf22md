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
        )
    ],
    dependencies: [],
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

        // Test target
        .testTarget(
            name: "PDF22MDTests",
            dependencies: ["PDF22MD"],
            path: "Tests/PDF22MDTests"
        )
    ]
) 