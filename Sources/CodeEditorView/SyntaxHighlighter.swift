//
//  SyntaxHighlighter.swift
//  CodeEditorView
//

import SwiftTreeSitter
import UIKit

public final class SyntaxHighlighter {
    static let spacesPerTab = 4
    private let parser: Parser
    private let highlightsQuery: Query
    private let theme: SyntaxTheme

    public init(configuration: LanguageConfiguration, theme: SyntaxTheme) throws {
        self.theme = theme

        self.parser = Parser()
        try self.parser.setLanguage(configuration.treeSitterLanguage)
        self.highlightsQuery = try Query(
            language: configuration.treeSitterLanguage,
            data: configuration.highlightsQueryData
        )
    }

    /// Highlight the given source string and return an NSAttributedString.
    public func highlight(_ source: String) -> NSAttributedString {
        let attributed = NSMutableAttributedString(
            string: source,
            attributes: [
                .font: theme.baseFont,
                .foregroundColor: theme.baseColor,
            ]
        )

        // Add paragraph styles for hanging indents
        let spaceWidth = (" " as NSString).size(withAttributes: [.font: theme.baseFont]).width
        let nsString = source as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        nsString.enumerateSubstrings(in: fullRange, options: .byParagraphs) {
            (substring, substringRange, enclosingRange, stop) in
            guard let text = substring else { return }

            // Count leading spaces/tabs
            var leadingSpaces = 0
            for char in text {
                if char == " " {
                    leadingSpaces += 1
                } else if char == "\t" {
                    leadingSpaces += Self.spacesPerTab
                } else {
                    break
                }
            }

            if leadingSpaces > 0 {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.firstLineHeadIndent = 0
                paragraphStyle.headIndent = CGFloat(leadingSpaces) * spaceWidth

                attributed.addAttribute(
                    .paragraphStyle, value: paragraphStyle, range: enclosingRange)
            }
        }

        // Parse the source with tree-sitter
        guard let tree = parser.parse(source) else {
            return attributed
        }

        // highlights query against the full tree
        let cursor = highlightsQuery.execute(in: tree)
        let highlights = cursor.highlights()

        for namedRange in highlights {
            let range = namedRange.range

            guard range.location != NSNotFound,
                range.location + range.length <= attributed.length
            else {
                continue
            }

            if let color = colorForCapture(namedRange.name) {
                attributed.addAttribute(.foregroundColor, value: color, range: range)
            }
        }

        return attributed
    }

    private func colorForCapture(_ name: String) -> UIColor? {
        if let color = theme.captureColors[name] {
            return color
        }

        var components = name.split(separator: ".")
        while !components.isEmpty {
            components.removeLast()
            let prefix = components.joined(separator: ".")
            if let color = theme.captureColors[prefix] {
                return color
            }
        }

        return nil
    }
}

public enum SyntaxHighlighterError: Error, LocalizedError {
    case queryBundleNotFound
    case queryFileNotFound

    public var errorDescription: String? {
        switch self {
        case .queryBundleNotFound:
            return "Could not find the TreeSitter resource bundle"
        case .queryFileNotFound:
            return "Could not find highlights.scm in the TreeSitter bundle"
        }
    }
}
