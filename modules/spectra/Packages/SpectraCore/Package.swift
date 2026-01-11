// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpectraCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "SpectraCore",
            targets: ["SpectraCore"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SpectraCore",
            dependencies: [],
            path: "Sources/SpectraCore"
        ),
        .testTarget(
            name: "SpectraCoreTests",
            dependencies: ["SpectraCore"],
            path: "Tests/SpectraCoreTests"
        ),
    ]
)
