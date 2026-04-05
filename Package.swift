// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "libzip-spm",
    products: [
        .library(name: "zip", targets: ["zip"]),
    ],
    targets: [
        .target(
            name: "zip",
            dependencies: [
                "czip",
            ],
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("bz2"),
            ]
        ),
        .binaryTarget(
            name: "czip",
            url: "https://github.com/Lakr233/libzip-spm/releases/download/storage.1.11.4/libzip.xcframework.zip",
            checksum: "86b80255bdaedcfede9ad4e232f14dc1ff03b5abde444dcc5b91866cd2bf7a2b"
        ),
    ]
)
