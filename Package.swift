import PackageDescription

let package = Package(
    name: "VaporGraph",
    targets: [
        Target(name: "VaporGraph", dependencies: ["GraphVaporExtensions"]),
        Target(name: "GraphVaporExtensions"),
    ],
    dependencies: [
        .Package(url: "https://github.com/vapor/fluent-provider.git", majorVersion: 1)
    ]
)
