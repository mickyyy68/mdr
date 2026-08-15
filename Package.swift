// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "mdr",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", exact: "0.8.0")
    ],
    targets: [
        .target(
            name: "MDReaderCore",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ]
        ),
        .executableTarget(
            name: "mdr",
            dependencies: ["MDReaderCore"]
        ),
        .testTarget(
            name: "mdrTests",
            dependencies: ["MDReaderCore"]
        )
    ]
)