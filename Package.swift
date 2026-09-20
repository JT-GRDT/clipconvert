// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClipConvert",
    products: [
        .library(name: "ClipConvertCore", targets: ["ClipConvertCore"])
    ],
    targets: [
        .target(name: "ClipConvertCore"),
        .testTarget(
            name: "ClipConvertCoreTests",
            dependencies: ["ClipConvertCore"]
        )
    ]
)
