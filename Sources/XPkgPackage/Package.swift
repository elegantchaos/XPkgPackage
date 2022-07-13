// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/07/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Logger
import Runner

public struct Package {
    public typealias ManifestCommand = [String]
    public typealias FishFunction = String
    public typealias FishFunctions = [FishFunction]

    public let local: URL
    let output: Channel
    let verbose: Channel
    let arguments: [String]

    public init(arguments: [String] = CommandLine.arguments) {
        guard arguments.count > 3 else {
            let name = URL(fileURLWithPath: arguments[0]).lastPathComponent
            print("Usage: \(name) <package-name> <package-path> <action>")
            exit(1)
        }

        let localPath = arguments[2]
        let localURL = URL(fileURLWithPath: localPath)

        self.local = localURL
        self.output = Logger.stdout
        self.verbose = Channel("verbose")
        self.arguments = arguments
    }

    public var actionName: String {
        arguments[3]
    }

    public var action: Action? {
        Action(rawValue: actionName)
    }

    @discardableResult public func run(links: [ManifestLink], commands: [ManifestCommand] = []) throws -> Action {
        guard let action = action else {
            output.log("Unrecognised action \(actionName).")
            throw PackageError.unknownCommand
        }

        switch action {
            case .install:
                manageLinks(creating: links)
                try perform(commands: commands)

            case .remove:
                try perform(commands: commands)
                manageLinks(removing: links)
        }

        return action
    }

    public func output(_ message: String) {
        output.log(message)
    }

    public func verbose(_ message: String) {
        verbose.log(message)
    }

    public func error(_ message: String, _ error: Error?) {
        output.log(message)
        if let error = error {
            verbose.log(error)
        }
    }

    public func fail(_ message: String, code: Int32) -> Never {
        output.log(message)
        exit(code)
    }

    /**
     The directory to use for binary links.
     By default we use the user's local bin.
     */

    var binURL: URL {
        //        if (global) {
        //            return URL(fileURLWithPath: "/usr/local/bin")
        //        } else {
        let localBin = "~/.local/bin" as NSString
        return URL(fileURLWithPath: localBin.expandingTildeInPath)
        //        }
    }

    /**
     Given a link specifier in the form: [localPath]. or [localPath, linkPath],
     return a triple: (localName, linkURL, localURL).

     If only the localPath is suppled, the link is created in the bin folder (either
     ~/.local/bin or /usr/local/bin, depending on which mode we're in), using the same
     name as the file it's linking to. In this case we also strip off any extension, so
     a linked file `blah.sh` becomes just `blah` in the bin folder.

     If both paths are supplied, we expand ~ etc in the link file path.
     */

    public func resolve(link spec: [String]) -> (String, URL, URL) {
        var linked = local.appendingPathComponent(spec[0])
        if !FileManager.default.fileExists(at: linked) {
            linked = URL(expandedFilePath: spec[0])
        }
        let name = linked.lastPathComponent
        let link: URL

        if spec.count == 1 {
            link = binURL.appendingPathComponent(name).deletingPathExtension()
        } else {
            link = URL(expandedFilePath: spec[1])
        }
        let resolved = (name, link, linked)
        verbose.log("resolved \(spec) as \(resolved)")
        return resolved
    }

    /// Try a block of code.
    /// If it fails, output an error and optionally perform some cleanup.
    /// - Parameter action: A description of the action that the block is performing.
    /// - Parameter cleanup: A cleanup block to run on failed.
    /// - Parameter block: The block to attempt.
    public func attempt(action: String, cleanup: (() throws -> Void)? = nil, block: () throws -> Void) {
        verbose.log(action)
        do {
            try block()
        } catch {
            try? cleanup?()
            output.log("\(action) failed.\n\(error)")
        }
    }

    /**
     Run through a list of linkSpecs and create each one.
     */

    public func manageLinks(creating links: [ManifestLink]?) {
        let fileManager = FileManager.default
        if let links = links {
            for link in links {
                let resolved = link.resolve(package: self)
                attempt(action: "Link (\(resolved.name) as \(resolved.destination))") {
                    // is there's already something where we're making a link?
                    let fileExists = fileManager.fileExists(at: resolved.destination)
                    let fileIsSymlink = fileManager.fileIsSymLink(at: resolved.destination)
                    if fileExists || fileIsSymlink {
                        // if we've not backed it up already, do so
                        let backup = resolved.destination.appendingPathExtension("backup")
                        if !(fileManager.fileExists(at: backup) || fileManager.fileIsSymLink(at: backup)) {
                            try fileManager.moveItem(at: resolved.destination, to: backup)
                        }

                        // it's a symlink, or backed up, so hopefully safe to overwrite
                        try? fileManager.removeItem(at: resolved.destination)
                    }

                    // make the containing folder if it doesn't exist
                    try? fileManager.createDirectory(at: resolved.destination.deletingLastPathComponent(), withIntermediateDirectories: true)

                    // make the link
                    try fileManager.createSymbolicLink(at: resolved.destination, withDestinationURL: resolved.source)
                }
            }
        }
    }

    /**
     Run through a list of linkSpecs and remove each one.
     */

    public func manageLinks(removing links: [ManifestLink]?) {
        let fileManager = FileManager.default
        if let links = links {
            for link in links {
                let resolved = link.resolve(package: self)
                attempt(action: "Unlink \(resolved.destination)") {
                    if fileManager.fileIsSymLink(at: resolved.destination) {
                        try fileManager.removeItem(at: resolved.destination)
                        let backup = resolved.destination.appendingPathExtension("backup")
                        if fileManager.fileExists(at: backup) {
                            try fileManager.moveItem(at: backup, to: resolved.destination)
                        }
                    }
                }
            }
        }
    }

    /**
     Run an external command.
     */

    func external(command: String, arguments: [String]) throws {
        let fileManager = FileManager.default
        // var executable = URL(expandedFilePath: command).absoluteURL
        var args = arguments
        var executable = local.appendingPathComponent(command)
        if !fileManager.fileExists(at: executable) {
            executable = URL(expandedFilePath: command)
        }
        if !fileManager.fileExists(at: executable) {
            executable = URL(fileURLWithPath: "/usr/bin/env")
            args.insert(command, at: 0)
        }

        let runner = Runner(for: executable, cwd: local)
        let result = try runner.sync(arguments: args, stdoutMode: .passthrough)
        if result.status == 0 {
            output.log(result.stdout)
        } else {
            output.log("Failed to run \(command).\n\n\(result.status) \(result.stdout) \(result.stderr)")
        }
    }

    /**
     Run a list of commands.
     */

    public func perform(commands: [ManifestCommand]?) throws {
        if let commands = commands {
            for command in commands {
                if command.count > 0 {
                    let tool = command[0]
                    let arguments = Array(command.dropFirst())
                    switch tool {
                        case "link": manageLinks(creating: [ManifestLink(arguments)])
                        case "unlink": manageLinks(removing: [ManifestLink(arguments)])
                        default:
                            verbose.log("running \(tool)")
                            try external(command: tool, arguments: arguments)
                    }
                }
            }
        }
    }
}
