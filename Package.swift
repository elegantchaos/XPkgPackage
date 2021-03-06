// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "XPkgPackage",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "XPkgPackage",
            targets: ["XPkgPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.5.5"),
        .package(url: "https://github.com/elegantchaos/Runner.git", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "XPkgPackage",
            dependencies: ["Runner", "Logger"]),
        .testTarget(
            name: "XPkgPackageTests",
            dependencies: ["XPkgPackage"]),
    ]
)
