// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "MuFlo",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "MuFlo",
            targets: ["MuFlo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/musesum/MuPar.git", from: "0.23.0"),
        .package(url: "https://github.com/musesum/MuVisit.git", from: "0.23.0"),
        .package(url: "https://github.com/musesum/MuSkyFlo.git", from: "0.23.0"),
        .package(url: "https://github.com/musesum/MuTime.git", from: "0.23.0"),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-numerics",  .upToNextMajor(from: "1.0.0"))
    ],

    targets: [
        .target(name: "MuFlo",
                dependencies: [
                    .product(name: "Numerics", package: "swift-numerics"),
                    .product(name: "Collections", package: "swift-collections"),
                    .product(name: "MuSkyFlo", package: "MuSkyFlo"),
                    .product(name: "MuTime", package: "MuTime"),
                    .product(name: "MuVisit", package: "MuVisit"),
                    .product(name: "MuPar", package: "MuPar")],
                resources: [.process("Resources")]),
        .testTarget(name: "MuFloTests", dependencies: ["MuSkyFlo","MuFlo"]),
    ]
)
