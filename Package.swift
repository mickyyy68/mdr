// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "mdreader",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.4.0")
    ],
    targets: [
        .target(
            name: "MDReaderCore",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ]
        ),
        .executableTarget(
            name: "mdreader",
            dependencies: ["MDReaderCore"]
        ),
        .testTarget(
            name: "mdreaderTests",
            dependencies: ["MDReaderCore"]
        )
    ]
)