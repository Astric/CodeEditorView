//
//  LanguageConfiguration.swift
//  CodeEditorView
//

import Foundation
import SwiftTreeSitter
import TreeSitterJSON
import TreeSitterCSS
import TreeSitterHTML
import TreeSitterGo
import TreeSitterSwift
import TreeSitterPython

public struct LanguageConfiguration {
    public let treeSitterLanguage: Language
    public let highlightsQueryData: Data
    
    public init(treeSitterLanguage: Language, highlightsQueryData: Data) {
        self.treeSitterLanguage = treeSitterLanguage
        self.highlightsQueryData = highlightsQueryData
    }
}

public extension LanguageConfiguration {
    static func json() throws -> LanguageConfiguration {
        try make(language: Language(language: tree_sitter_json()), bundleName: "CodeEditorView_TreeSitterJSON")
    }

    static func css() throws -> LanguageConfiguration {
        try make(language: Language(language: tree_sitter_css()), bundleName: "CodeEditorView_TreeSitterCSS")
    }

    static func html() throws -> LanguageConfiguration {
        try make(language: Language(language: tree_sitter_html()), bundleName: "CodeEditorView_TreeSitterHTML")
    }

    static func golang() throws -> LanguageConfiguration {
        try make(language: Language(language: tree_sitter_go()), bundleName: "CodeEditorView_TreeSitterGo")
    }

    static func swift() throws -> LanguageConfiguration {
        try make(language: Language(language: tree_sitter_swift()), bundleName: "CodeEditorView_TreeSitterSwift")
    }

    static func python() throws -> LanguageConfiguration {
        try make(language: Language(language: tree_sitter_python()), bundleName: "CodeEditorView_TreeSitterPython")
    }
}

private extension LanguageConfiguration {
    static func make(language: Language, bundleName: String) throws -> LanguageConfiguration {
        guard let bundleURL = Bundle.main.url(forResource: bundleName, withExtension: "bundle"),
              let resourceBundle = Bundle(url: bundleURL) else {
            throw SyntaxHighlighterError.queryBundleNotFound
        }

        guard let queryURL = resourceBundle.url(forResource: "highlights", withExtension: "scm", subdirectory: "queries") else {
            throw SyntaxHighlighterError.queryFileNotFound
        }

        return LanguageConfiguration(
            treeSitterLanguage: language,
            highlightsQueryData: try Data(contentsOf: queryURL)
        )
    }
}
