// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ModelStore",
    platforms: [.iOS(.v26)],
    products: [.library(name: "ModelStore", targets: ["ModelStore"])],
    dependencies: [],
    targets: [
        .target(name: "ModelStore", dependencies: [], resources: [.process("catalog.json")]),
        .testTarget(name: "ModelStoreTests", dependencies: ["ModelStore"]),
    ]
)
