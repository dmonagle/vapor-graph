// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "VaporGraph",
    products: [
        .library(name: "VaporGraph", targets: ["VaporGraph", "StructuredDataGraphExtensions"]),
        ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-provider.git", from: Version(1, 0, 0)),
    ],
    targets: [
        .target(name: "VaporGraph", dependencies: ["StructuredDataGraphExtensions", "FluentProvider"]),
        .target(name: "StructuredDataGraphExtensions", dependencies: ["FluentProvider"]),

        // Testing
        .testTarget(name: "VaporGraphTests", dependencies: ["VaporGraph"]),
        .testTarget(name: "StructuredDataGraphExtensionsTests", dependencies: ["StructuredDataGraphExtensions"]),
        ]
)

package.swiftLanguageVersions = [3, 4]
