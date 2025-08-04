// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "countdown-background",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "CountdownWallpaper",
            path: "Sources"
        )
    ]
)
