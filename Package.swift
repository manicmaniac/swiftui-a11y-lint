// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swiftui-a11y-lint",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(
            name: "swiftui-a11y-lint",
            targets: ["swiftui-a11y-lint"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "swiftui-a11y-lint",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "swiftui-a11y-lintTests",
            dependencies: ["swiftui-a11y-lint"]
        ),
    ]
)
