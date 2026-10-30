// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ModelStore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "ModelStore", targets: ["ModelStore"])],
    dependencies: [],
    targets: [
        .target(name: "ModelStore", dependencies: []),
        .testTarget(name: "ModelStoreTests", dependencies: ["ModelStore"]),
    ]
)
