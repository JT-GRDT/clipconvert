// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClipConvert",
    products: [
        .library(name: "ClipConvertCore", targets: ["ClipConvertCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.6.0")
    ],
    targets: [
        .target(
            name: "ClipConvertCore",
            dependencies: [.product(name: "Markdown", package: "swift-markdown")]
        ),
        .testTarget(
            name: "ClipConvertCoreTests",
            dependencies: ["ClipConvertCore"]
        )
    ]
)
