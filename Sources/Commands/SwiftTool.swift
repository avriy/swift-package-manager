/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
 */

import Basic
import Get
import PackageLoading
import PackageGraph

// FIXME: Find a home for this. Ultimately it might need access to some of the
// options, and we might just want the SwiftTool type to become a class.
private let sharedManifestLoader = ManifestLoader(resources: ToolDefaults())

private class ToolWorkspaceDelegate: WorkspaceDelegate {
    func fetchingMissingRepositories(_ urls: Set<String>) {
    }
    
    func fetching(repository: String) {
    }

    func cloning(repository: String) {
    }

    func checkingOut(repository: String, at reference: String) {
    }
}

public class SwiftTool {
    /// The command line arguments this tool should honor.
    let args: [String]

    public init() {
        self.args = Array(CommandLine.arguments.dropFirst())
    }

    /// Execute the tool.
    public func run() {
        runImpl()
    }

    /// Run method implmentation to be overridden by subclasses.
    func runImpl() {
        fatalError("Must be implmented by subclasses")
    }

    /// The shared package graph loader.
    var manifestLoader: ManifestLoader {
        return sharedManifestLoader
    }

    /// Fetch and load the complete package at the given path.
    func loadPackage(at path: AbsolutePath, _ opts: Options) throws -> PackageGraph {
        if opts.enableNewResolver {
            // Get the active workspace.
            let delegate = ToolWorkspaceDelegate()
            let workspace = try Workspace(rootPackage: path, dataPath: opts.path.build, manifestLoader: manifestLoader, delegate: delegate)

            // Fetch and load the package graph.
            let graph = try workspace.loadPackageGraph()

            // Create the legacy `Packages` subdirectory.
            try workspace.createPackagesDirectory(graph)

            return graph
        } else {
            // Create the packages directory container.
            let packagesDirectory = PackagesDirectory(root: path, manifestLoader: manifestLoader)

            // Fetch and load the manifests.
            let (rootManifest, externalManifests) = try packagesDirectory.loadManifests()
        
            return try PackageGraphLoader().load(rootManifest: rootManifest, externalManifests: externalManifests)
        }
    }
}
