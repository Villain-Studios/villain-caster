// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "VillainCaster",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "VillainCaster",
            path: "Sources/VillainCaster",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
