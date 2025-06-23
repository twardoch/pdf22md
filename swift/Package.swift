// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PDF22MD",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "PDF22MD",
            targets: ["PDF22MD"]),
        .executable(
            name: "pdf22md-swift",
            targets: ["PDF22MDCli"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/google/swift-benchmark", from: "0.1.2")
    ],
    targets: [
        .target(
            name: "PDF22MD",
            dependencies: [],
            path: "Sources/PDF22MD",
            swiftSettings: [
                .unsafeFlags(["-O", "-whole-module-optimization"], .when(configuration: .release))
            ]),
        .executableTarget(
            name: "PDF22MDCli",
            dependencies: [
                "PDF22MD",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/PDF22MDCli",
            swiftSettings: [
                .unsafeFlags(["-O", "-whole-module-optimization"], .when(configuration: .release))
            ]),
        .testTarget(
            name: "PDF22MDTests",
            dependencies: ["PDF22MD"],
            path: "Tests/PDF22MDTests")
    ]
)