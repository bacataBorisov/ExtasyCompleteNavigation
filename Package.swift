// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ExtasyNavigationCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ExtasyNavigationCore",
            targets: ["ExtasyNavigationCore"]
        )
    ],
    targets: [
        .target(
            name: "ExtasyNavigationCore",
            path: "NavigationCorePackage/Sources/ExtasyNavigationCore"
        ),
        .testTarget(
            name: "ExtasyNavigationCoreTests",
            dependencies: ["ExtasyNavigationCore"],
            path: "NavigationCorePackage/Tests/ExtasyNavigationCoreTests"
        )
    ]
)
