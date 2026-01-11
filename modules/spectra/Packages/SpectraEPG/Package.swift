// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpectraEPG",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "SpectraEPG",
            targets: ["SpectraEPG"]
        ),
    ],
    dependencies: [
        .package(path: "../SpectraCore"),
    ],
    targets: [
        .target(
            name: "SpectraEPG",
            dependencies: ["SpectraCore"],
            path: "Sources/SpectraEPG"
        ),
        .testTarget(
            name: "SpectraEPGTests",
            dependencies: ["SpectraEPG"],
            path: "Tests/SpectraEPGTests"
        ),
    ]
)
