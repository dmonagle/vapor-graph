import PackageDescription

let package = Package(
    name: "VaporGraph",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 5),
    ]
)
