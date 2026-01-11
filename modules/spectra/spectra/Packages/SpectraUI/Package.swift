// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpectraUI",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "SpectraUI",
            targets: ["SpectraUI"]
        ),
    ],
    dependencies: [
        .package(path: "../SpectraCore"),
        .package(path: "../SpectraEPG"),
    ],
    targets: [
        .target(
            name: "SpectraUI",
            dependencies: ["SpectraCore", "SpectraEPG"],
            path: "Sources/SpectraUI"
        ),
        .testTarget(
            name: "SpectraUITests",
            dependencies: ["SpectraUI"],
            path: "Tests/SpectraUITests"
        ),
    ]
)
