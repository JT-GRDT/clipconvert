// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClipConvert",
    products: [
        .library(name: "ClipConvertCore", targets: ["ClipConvertCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", .upToNextMinor(from: "0.8.0"))
    ],
    targets: [
        .target(
            name: "ClipConvertCore",
            dependencies: [.product(name: "Markdown", package: "swift-markdown")]
        ),
        .testTarget(
            name: "ClipConvertCoreTests",
            dependencies: ["ClipConvertCore"],
            resources: [
                .copy("Fixtures"),
                .copy("Negative")
            ]
        )
    ]
)
