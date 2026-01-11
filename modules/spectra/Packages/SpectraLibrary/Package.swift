// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpectraLibrary",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "SpectraLibrary",
            targets: ["SpectraLibrary"]
        ),
    ],
    dependencies: [
        .package(path: "../SpectraCore"),
    ],
    targets: [
        .target(
            name: "SpectraLibrary",
            dependencies: ["SpectraCore"],
            path: "Sources/SpectraLibrary"
        ),
        .testTarget(
            name: "SpectraLibraryTests",
            dependencies: ["SpectraLibrary"],
            path: "Tests/SpectraLibraryTests"
        ),
    ]
)
