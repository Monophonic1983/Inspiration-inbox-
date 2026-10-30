// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CaptureKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "CaptureKit", targets: ["CaptureKit"])],
    dependencies: [.package(path: "../Persistence"), ],
    targets: [
        .target(name: "CaptureKit", dependencies: [.product(name: "Persistence", package: "Persistence"), ]),
        .testTarget(name: "CaptureKitTests", dependencies: ["CaptureKit"]),
    ]
)
