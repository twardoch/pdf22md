// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PDF22MDBenchmarks",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(path: "../swift"),
        .package(url: "https://github.com/google/swift-benchmark", from: "0.1.2")
    ],
    targets: [
        .executableTarget(
            name: "PDF22MDBenchmarks",
            dependencies: [
                .product(name: "PDF22MD", package: "swift"),
                .product(name: "Benchmark", package: "swift-benchmark")
            ],
            path: "Sources")
    ]
)