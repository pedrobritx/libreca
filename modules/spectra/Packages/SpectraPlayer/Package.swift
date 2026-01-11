// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpectraPlayer",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "SpectraPlayer",
            targets: ["SpectraPlayer"]
        ),
    ],
    dependencies: [
        .package(path: "../SpectraCore"),
    ],
    targets: [
        .target(
            name: "SpectraPlayer",
            dependencies: ["SpectraCore"],
            path: "Sources/SpectraPlayer"
        ),
        .testTarget(
            name: "SpectraPlayerTests",
            dependencies: ["SpectraPlayer"],
            path: "Tests/SpectraPlayerTests"
        ),
    ]
)
