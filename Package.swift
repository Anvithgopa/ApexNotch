// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "ApexNotch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ApexNotch", targets: ["ApexNotch"]),
        .executable(name: "ApexNotchTests", targets: ["ApexNotchTests"])
    ],
    targets: [
        .target(
            name: "ApexNotchCore",
            path: "Sources/ApexNotchCore",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency")
            ]
        ),
        .executableTarget(
            name: "ApexNotch",
            dependencies: ["ApexNotchCore"],
            path: "Sources/ApexNotchApp",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency")
            ]
        ),
        .executableTarget(
            name: "ApexNotchTests",
            dependencies: ["ApexNotchCore"],
            path: "Tests/ApexNotchTests",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency")
            ]
        )
    ]
)
