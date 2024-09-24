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
            url: "https://github.com/Lakr233/libzip-spm/releases/download/storage.v1.11.1/libzip.xcframework.zip",
            checksum: "87ef5296b97624839a3e59c52c05007627d583e48c1610522a418f3bda66c221"
        ),
    ]
)
