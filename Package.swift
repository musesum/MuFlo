// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MuFlo",
    platforms: [.iOS(.v17), .visionOS(.v2), .watchOS(.v10)],
    products: [.library(name: "MuFlo", targets: ["MuFlo"])],
    dependencies: [
        .package(url: "https://github.com/musesum/MuPeers.git", branch: "main"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", branch: "development"),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-numerics",  .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0")
    ],

    targets: [
        .target(name: "MuFlo",
                dependencies: [
                    .product(name: "MuPeers", package: "MuPeers",
                             condition: .when(platforms: [.iOS, .visionOS])),
                    .product(name: "Numerics", package: "swift-numerics"),
                    .product(name: "Collections", package: "swift-collections"),
                    .product(name: "ZIPFoundation", package: "ZIPFoundation"),
                    .product(name: "NIO", package: "swift-nio",
                             condition: .when(platforms: [.iOS, .visionOS])),
                    ],
                resources: [.process("Resources")]),
        .testTarget(name: "MuFloTests", dependencies: ["MuFlo"]),
    ]
)
