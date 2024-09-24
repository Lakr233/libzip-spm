// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "libzip-spm",
    products: [
        .library(name: "zip", targets: ["zip"]),
    ],
    targets: [
        .target(name: "zip", dependencies: [
            "czip",
        ]),
        .binaryTarget(
            name: "czip",
            url: "https://github.com/Lakr233/libzip-spm/releases/download/storage.1.11.1/libzip.xcframework.zip",
            checksum: "835b6e83cd5eae39f11ef432e504dc4f6d9d462410527370688d18c98ea11315"
        ),
    ]
)
