// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpectraApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "SpectraApp",
            targets: ["SpectraApp"]
        ),
    ],
    dependencies: [
        .package(path: "../../../Packages/SpectraCore"),
        .package(path: "../../../Packages/SpectraLibrary"),
        .package(path: "../../../Packages/SpectraPlayer"),
        .package(path: "../../../Packages/SpectraSync"),
        .package(path: "../../../Packages/SpectraEPG"),
        .package(path: "../../../Packages/SpectraUI"),
    ],
    targets: [
        .executableTarget(
            name: "SpectraApp",
            dependencies: [
                "SpectraCore",
                "SpectraLibrary",
                "SpectraPlayer",
                "SpectraSync",
                "SpectraEPG",
                "SpectraUI",
            ],
            path: "Sources"
        ),
    ]
)
