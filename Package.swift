// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "XPkgPackage",
    
    platforms: [
        .macOS(.v10_13)
    ],
    
    products: [
        .library(
            name: "XPkgPackage",
            targets: ["XPkgPackage"]
        ),
    ],

    dependencies: [
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.7.4"),
        .package(url: "https://github.com/elegantchaos/Runner.git", from: "1.3.2"),
        
        // tools
        .package(url: "https://github.com/elegantchaos/ActionBuilderPlugin.git", from: "1.0.2"),
        .package(url: "https://github.com/elegantchaos/SwiftFormatterPlugin.git", from: "1.0.2")

    ],
    
    targets: [
        .target(
            name: "XPkgPackage",
            dependencies: ["Runner", "Logger"]
        ),
        
        .testTarget(
            name: "XPkgPackageTests",
            dependencies: ["XPkgPackage"]
        ),
    ],
    
    swiftLanguageVersions: [
        .v5
    ]
)
