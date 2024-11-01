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
            url: "https://github.com/Lakr233/libzip-spm/releases/download/storage.1.11.2/libzip.xcframework.zip",
            checksum: "e642cd24b8fb92cb9318296549e894171e180a5811c9ea16a8d3700d6871e675"
        ),
    ]
)
