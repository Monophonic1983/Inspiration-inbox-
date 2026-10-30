// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Persistence",
    platforms: [.iOS(.v26)],
    products: [.library(name: "Persistence", targets: ["Persistence"])],
    dependencies: [],
    targets: [
        .target(name: "Persistence", dependencies: []),
        .testTarget(name: "PersistenceTests", dependencies: ["Persistence"]),
    ]
)
