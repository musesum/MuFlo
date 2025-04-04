// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MuFlo",
    platforms: [.iOS(.v17)],
    products: [.library(name: "MuFlo", targets: ["MuFlo"])],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .branch("development")),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-numerics",  .upToNextMajor(from: "1.0.0"))
    ],

    targets: [
        .target(name: "MuFlo",
                dependencies: [
                    .product(name: "Numerics", package: "swift-numerics"),
                    .product(name: "Collections", package: "swift-collections"),
                    .product(name: "ZIPFoundation", package: "ZIPFoundation"),
                    ],
                resources: [.process("Resources")]),
        .testTarget(name: "MuFloTests", dependencies: ["MuFlo"]),
    ]
)
