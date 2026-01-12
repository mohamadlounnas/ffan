// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "smc-write",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "smc-write", targets: ["smc-write"]),
    ],
    dependencies: [
        .package(url: "https://github.com/srimanachanta/SMCKit.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "smc-write",
            dependencies: ["SMCKit"],
            path: "Sources/smc-write"
        )
    ]
)
