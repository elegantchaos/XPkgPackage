// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 20/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Runner

public struct InstalledPackage {
    public typealias ManifestCommand = [String]
    public typealias ManifestLink = [String]

    struct Manifest: Codable {
        let install: [ManifestCommand]?
        let remove: [ManifestCommand]?
        let updating: [ManifestCommand]?
        let updated: [ManifestCommand]?
        let links: [ManifestLink]?
        let dependencies: [String]?
    }

    public let local: URL
    let verboseEnabled: Bool

    public init(local: URL) {
        self.local = local
        self.verboseEnabled = false
    }

    public init(fromCommandLine arguments: [String]) {
        guard arguments.count > 3 else {
            let name = URL(fileURLWithPath: arguments[0]).lastPathComponent
            print("Usage: \(name) <package-name> <package-path> <action>")
            exit(1)
        }

        let localPath = arguments[2]
        let localURL = URL(fileURLWithPath: localPath)

        self.local = localURL
        self.verboseEnabled = arguments.contains("--verbose")
    }

    public func actionName(fromCommandLine arguments: [String]) -> String {
        arguments[3]
    }

    public func action(fromCommandLine arguments: [String]) -> Action? {
        Action(rawValue: actionName(fromCommandLine: arguments))
    }

    public func performAction(fromCommandLine arguments: [String], links: [ManifestLink], commands: [ManifestLink] = []) throws {
        guard let action = action(fromCommandLine: arguments) else {
            output("Unrecognised action \(actionName(fromCommandLine: arguments)).")
            return
        }

        switch action {
            case .install:
                manageLinks(creating: links)
                try run(commands: commands)

            case .remove:
                try run(commands: commands)
                manageLinks(removing: links)
        }
    }

    public func output(_ message: String) {
        print(message)
    }

    public func verbose(_ message: String) {
        if verboseEnabled {
            print(message)
        }
    }

    public func output<S: CustomStringConvertible>(_ object: S) {
        print(object.description)
    }

    public func verbose<S: CustomStringConvertible>(_ object: S) {
        if verboseEnabled {
            print(object.description)
        }
    }

    public func error(_ message: String, _ error: Error?) {
        output(message)
        if let error = error {
            verbose("\(error)")
        }
    }

    public func fail(_ message: String, code: Int32) -> Never {
        output(message)
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
        verbose("resolved \(spec) as \(resolved)")
        return resolved
    }

    /// Try a block of code.
    /// If it fails, output an error and optionally perform some cleanup.
    /// - Parameter action: A description of the action that the block is performing.
    /// - Parameter cleanup: A cleanup block to run on failed.
    /// - Parameter block: The block to attempt.
    public func attempt(action: String, cleanup: (() throws -> Void)? = nil, block: () throws -> Void) {
        verbose(action)
        do {
            try block()
        } catch {
            try? cleanup?()
            output("\(action) failed.\n\(error)")
        }
    }

    /**
     Run through a list of linkSpecs and create each one.
     */

    public func manageLinks(creating links: [ManifestLink]?) {
        let fileManager = FileManager.default
        if let links = links {
            for link in links {
                let (name, linkURL, linkedURL) = resolve(link: link)
                attempt(action: "Link (\(name) as \(linkURL))") {
                    // is there's already something where we're making a link?
                    let fileExists = fileManager.fileExists(at: linkURL)
                    let fileIsSymlink = fileManager.fileIsSymLink(at: linkURL)
                    if fileExists || fileIsSymlink {
                        // if we've not backed it up already, do so
                        let backup = linkURL.appendingPathExtension("backup")
                        if !(fileManager.fileExists(at: backup) || fileManager.fileIsSymLink(at: backup)) {
                            try fileManager.moveItem(at: linkURL, to: backup)
                        }

                        // it's a symlink, or backed up, so hopefully safe to overwrite
                        try? fileManager.removeItem(at: linkURL)
                    }

                    // make the containing folder if it doesn't exist
                    try? fileManager.createDirectory(at: linkURL.deletingLastPathComponent(), withIntermediateDirectories: true)

                    // make the link
                    try fileManager.createSymbolicLink(at: linkURL, withDestinationURL: linkedURL)
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
                let (_, linkURL, _) = resolve(link: link)
                attempt(action: "Unlink \(linkURL)") {
                    if fileManager.fileIsSymLink(at: linkURL) {
                        try fileManager.removeItem(at: linkURL)
                        let backup = linkURL.appendingPathExtension("backup")
                        if fileManager.fileExists(at: backup) {
                            try fileManager.moveItem(at: backup, to: linkURL)
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
            output(result.stdout)
        } else {
            output("Failed to run \(command).\n\n\(result.status) \(result.stdout) \(result.stderr)")
        }
    }

    /**
     Run commands listed in the .xpkg file for a given action.
     */

    public func run(legacyAction action: String, config url: URL) throws {
        let decoder = JSONDecoder()
        if let manifest = try? decoder.decode(Manifest.self, from: Data(contentsOf: url)) {
            switch action {
                case "install":
                    manageLinks(creating: manifest.links)
                    try run(commands: manifest.install)

                case "remove":
                    try run(commands: manifest.remove)
                    manageLinks(removing: manifest.links)

                default:
                    output("Unknown action \(action).")
            }
        } else {
            output("Couldn't decode manifest.")
        }
    }

    /**
     Run a list of commands.
     */

    public func run(commands: [ManifestCommand]?) throws {
        if let commands = commands {
            for command in commands {
                if command.count > 0 {
                    let tool = command[0]
                    let arguments = Array(command.dropFirst())
                    switch tool {
                        case "link": manageLinks(creating: [arguments])
                        case "unlink": manageLinks(removing: [arguments])
                        default:
                            verbose("running \(tool)")
                            try external(command: tool, arguments: arguments)
                    }
                }
            }
        }
    }
}
