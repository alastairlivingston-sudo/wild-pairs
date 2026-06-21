// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WildPairs",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "WildPairsCore",
            targets: ["WildPairsCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WildPairsCore",
            dependencies: [],
            path: "WildPairsCore"
        ),
        .testTarget(
            name: "WildPairsTests",
            dependencies: ["WildPairsCore"],
            path: "WildPairsTests"
        )
    ]
)
