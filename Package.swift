import PackageDescription

let package = Package(
    name: "VaporGraph",
    targets: [
        Target(name: "VaporGraph", dependencies: ["StructuredDataGraphExtensions"]),
        Target(name: "StructuredDataGraphExtensions"),
    ],
    dependencies: [
        .Package(url: "https://github.com/vapor/fluent-provider.git", majorVersion: 1)
    ]
)
