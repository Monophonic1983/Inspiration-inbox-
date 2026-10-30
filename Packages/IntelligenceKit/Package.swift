// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IntelligenceKit",
    platforms: [.iOS(.v26)],
    products: [.library(name: "IntelligenceKit", targets: ["IntelligenceKit"])],
    dependencies: [.package(path: "../Persistence"), ],
    targets: [
        .target(name: "IntelligenceKit", dependencies: [.product(name: "Persistence", package: "Persistence"), ]),
        .testTarget(name: "IntelligenceKitTests", dependencies: ["IntelligenceKit"]),
    ]
)
