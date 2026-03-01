// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CodeEditorView",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "CodeEditorView",
            targets: ["CodeEditorView"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/tree-sitter/swift-tree-sitter", from: "0.9.0"),
    ],
    targets: [
        .target(
            name: "CodeEditorView",
            dependencies: [
                .product(name: "SwiftTreeSitter", package: "swift-tree-sitter"),
                "TreeSitterJSON",
                "TreeSitterCSS",
                "TreeSitterHTML",
                "TreeSitterGo",
                "TreeSitterSwift",
                "TreeSitterPython",
            ]
        ),

        // MARK: - Vendored Tree-Sitter Grammars

        .target(
            name: "TreeSitterPython",
            path: "Sources/TreeSitterPython",
            sources: ["src/parser.c", "src/scanner.c"],
            resources: [.copy("queries")],
            publicHeadersPath: "include",
            cSettings: [.headerSearchPath("src")]
        ),

        .target(
            name: "TreeSitterJSON",
            path: "Sources/TreeSitterJSON",
            sources: ["src/parser.c"],
            resources: [.copy("queries")],
            publicHeadersPath: "include",
            cSettings: [.headerSearchPath("src")]
        ),
        .target(
            name: "TreeSitterCSS",
            path: "Sources/TreeSitterCSS",
            sources: ["src/parser.c", "src/scanner.c"],
            resources: [.copy("queries")],
            publicHeadersPath: "include",
            cSettings: [.headerSearchPath("src")]
        ),
        .target(
            name: "TreeSitterHTML",
            path: "Sources/TreeSitterHTML",
            sources: ["src/parser.c", "src/scanner.c"],
            resources: [.copy("queries")],
            publicHeadersPath: "include",
            cSettings: [.headerSearchPath("src")]
        ),
        .target(
            name: "TreeSitterGo",
            path: "Sources/TreeSitterGo",
            sources: ["src/parser.c"],
            resources: [.copy("queries")],
            publicHeadersPath: "include",
            cSettings: [.headerSearchPath("src")]
        ),
        .target(
            name: "TreeSitterSwift",
            path: "Sources/TreeSitterSwift",
            sources: ["src/parser.c", "src/scanner.c"],
            resources: [.copy("queries")],
            publicHeadersPath: "include",
            cSettings: [.headerSearchPath("src")]
        ),
    ]
)
