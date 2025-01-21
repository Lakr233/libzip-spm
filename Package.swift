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
            url: "https://github.com/Lakr233/libzip-spm/releases/download/storage.1.11.3/libzip.xcframework.zip",
            checksum: "bc5e0cb40dddba91529573ee3ef1f3c7a9506e601c7e99727efa0437f697cd22"
        ),
    ]
)
