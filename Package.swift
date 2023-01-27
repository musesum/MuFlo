// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "Flo",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "Flo",
            targets: ["Flo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/musesum/Par.git", from: "0.3.0"),
        .package(url: "https://github.com/musesum/MuSkyFlo.git", from: "0.3.0"),
        .package(url: "https://github.com/musesum/MuTime.git", from: "0.3.0"),
        .package(url: "https://github.com/apple/swift-collections.git",
                 .upToNextMajor(from: "1.0.0") // or `.upToNextMinor
        )
    ],

    targets: [
        .target(name: "Flo",
                dependencies: [
                    .product(name: "Collections", package: "swift-collections"),
                    .product(name: "MuSkyFlo", package: "MuSkyFlo"),
                    .product(name: "MuTime", package: "MuTime"),
                    .product(name: "Par", package: "Par")],
                resources: [.process("Resources")]),
        .testTarget(name: "FloTests", dependencies: ["MuSkyFlo","Flo"]),
    ]
)
