import PackageDescription

let package = Package(
    name: "VaporGraph",
    dependencies: [
        .Package(url: "https://github.com/vapor/fluent-provider.git", majorVersion: 1)
    ]
)
