// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpectraSync",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "SpectraSync",
            targets: ["SpectraSync"]
        ),
    ],
    dependencies: [
        .package(path: "../SpectraCore"),
    ],
    targets: [
        .target(
            name: "SpectraSync",
            dependencies: ["SpectraCore"],
            path: "Sources/SpectraSync"
        ),
        .testTarget(
            name: "SpectraSyncTests",
            dependencies: ["SpectraSync"],
            path: "Tests/SpectraSyncTests"
        ),
    ]
)
