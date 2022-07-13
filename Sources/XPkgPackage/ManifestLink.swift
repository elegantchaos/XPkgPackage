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

    public static func script(_ name: String, ext: String? = nil, to destination: String? = nil) -> Self {
        let extStr = ext.map { ".\($0)" } ?? ""
        return Self(source: "Scripts/\(name)\(extStr)", destination: destination)
    }

    public static func function(_ name: String) -> Self {
        Self(source: "Fish/Functions/\(name).fish", destination: "~/.config/fish/functions/\(name).fish")
    }
}
//
//
//extension ManifestLink: ExpressibleByArrayLiteral {
//    public init(arrayLiteral elements: String...) {
//        self.source = elements.first!
//        self.destination = elements.count > 1 ? elements.last : nil
//    }
//}
