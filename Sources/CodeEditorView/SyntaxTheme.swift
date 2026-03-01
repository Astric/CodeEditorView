//
//  SyntaxTheme.swift
//  CodeEditorView
//

import UIKit

public struct SyntaxTheme {
    public let baseFont: UIFont
    public let baseColor: UIColor
    public let captureColors: [String: UIColor]

    public init(
        baseFont: UIFont = .monospacedSystemFont(ofSize: 16, weight: .medium),
        baseColor: UIColor = .label,
        captureColors: [String: UIColor] = [:]
    ) {
        self.baseFont = baseFont
        self.baseColor = baseColor
        self.captureColors = captureColors
    }
}

extension SyntaxTheme {
    public static var `default`: SyntaxTheme {
        return SyntaxTheme(
            baseFont: .monospacedSystemFont(ofSize: 16, weight: .medium),
            baseColor: .label,
            captureColors: [
                "keyword": .systemPink,
                "function": .systemCyan,
                "function.builtin": .systemCyan,
                "type": .systemMint,
                "variable": .label,
                "property": .systemTeal,
                "operator": .label,
                "tag": .systemRed,
                "attribute": .systemIndigo,
                "string.special.key": .systemCyan,
                "string": .systemOrange,
                "number": .systemPurple,
                "constant.builtin": .systemPink,
                "escape": .systemYellow,
                "comment": .systemGreen,
            ]
        )
    }
}
