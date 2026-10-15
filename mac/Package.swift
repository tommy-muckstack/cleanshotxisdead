// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CleanShotXIsDead",
    platforms: [.macOS("14.2")],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "CleanShotXIsDead",
            dependencies: [.product(name: "Sparkle", package: "Sparkle")],
            path: "src",
            resources: [.copy("Resources/Sounds")]
        ),
        .testTarget(name: "CleanShotXIsDeadTests", dependencies: ["CleanShotXIsDead"], path: "Tests"),
    ]
)
