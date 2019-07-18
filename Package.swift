// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "XPkgPackage",
    products: [
        .library(
            name: "XPkgPackage",
            targets: ["XPkgPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.3.7"),
        .package(url: "https://github.com/elegantchaos/Runner.git", from: "1.0.1"),
    ],
    targets: [
        .target(
            name: "XPkgPackage",
            dependencies: ["Runner"]),
        .testTarget(
            name: "XPkgPackageTests",
            dependencies: ["XPkgPackage"]),
    ]
)
