[comment]: <> (Header Generated by ActionStatus 1.0.2 - 320)

[![Test results][tests shield]][actions] [![Latest release][release shield]][releases] [![swift 5.1 shield] ![swift 5.2 shield] ![swift 5.3 shield] ![swift dev shield]][swift] ![Platforms: macOS, Linux][platforms shield]

[release shield]: https://img.shields.io/github/v/release/elegantchaos/XPkgPackage
[platforms shield]: https://img.shields.io/badge/platforms-macOS_Linux-lightgrey.svg?style=flat "macOS, Linux"
[tests shield]: https://github.com/elegantchaos/XPkgPackage/workflows/Tests/badge.svg
[swift 5.1 shield]: https://img.shields.io/badge/swift-5.1-F05138.svg "Swift 5.1"
[swift 5.2 shield]: https://img.shields.io/badge/swift-5.2-F05138.svg "Swift 5.2"
[swift 5.3 shield]: https://img.shields.io/badge/swift-5.3-F05138.svg "Swift 5.3"
[swift dev shield]: https://img.shields.io/badge/swift-dev-F05138.svg "Swift dev"

[swift]: https://swift.org
[releases]: https://github.com/elegantchaos/XPkgPackage/releases
[actions]: https://github.com/elegantchaos/XPkgPackage/actions

[comment]: <> (End of ActionStatus Header)

# XPkgPackage

Support for XPkg packages.

Usage:

```swift

import XPkgPackage

let links = [
    ["local/file", "~/place/to/link/file"],
]

let package = InstalledPackage(fromCommandLine: CommandLine.arguments)
try! package.performAction(fromCommandLine: CommandLine.arguments, links: links)

```

Provides a way to parse the arguments passed by `xpkg`, and get back a struct representing this package.

The struct supplies an API for creating links, running commands, and finding out which `xpkg` action is being performed.
