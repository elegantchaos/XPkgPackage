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
