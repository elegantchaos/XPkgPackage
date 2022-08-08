// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/07/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct ManifestLink {
    let source: String
    let destination: String?

    public init(source: String, destination: String? = nil) {
        self.source = source
        self.destination = destination
    }

    public init(_ args: [String]) {
        self.source = args.first!
        self.destination = args.count > 1 ? args.last : nil
    }

    public static func link(_ source: String, to destination: String? = nil) -> Self {
        Self(source: source, destination: destination)
    }

    public static func script(_ name: String, ext: String = "sh", to destination: String? = nil) -> Self {
        Self(source: "Scripts/\(name)\(ext.isEmpty ? "" : ".\(ext)")", destination: destination)
    }

    public static func function(_ name: String) -> Self {
        Self(source: "Fish/Functions/\(name).fish", destination: "~/.config/fish/functions/\(name).fish")
    }

    /**
     Resolve a link.

     If only the source is suppled, the link is created in the bin folder (either
     ~/.local/bin or /usr/local/bin, depending on which mode we're in), using the same
     name as the file it's linking to. In this case we also strip off any extension, so
     a linked file `blah.sh` becomes just `blah` in the bin folder.

     By default we assume that the source path is local to the package. If it doesn't exist
     there, we try treating it as absolute and expanding ~ etc.

     If the destination path is supplied, we treat it as absolute, and expand ~ etc in it.
     */

    public func resolve(package: Package) -> ResolvedLink {
        var linked = package.local.appendingPathComponent(source)
        if !FileManager.default.fileExists(at: linked) {
            linked = URL(expandedFilePath: source)
        }

        let name = linked.lastPathComponent
        let link = destination.map { URL(expandedFilePath: $0) } ?? package.binURL.appendingPathComponent(name).deletingPathExtension()
        let resolved = ResolvedLink(name: name, source: linked, destination: link)
        return resolved
    }
}


extension ManifestLink: CustomStringConvertible {
    public var description: String {
        return "\(source) -> \(destination ?? URL(fileURLWithPath: source).lastPathComponent)"
    }
}
