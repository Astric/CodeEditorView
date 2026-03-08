#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

//
//  SyntaxTheme.swift
//  CodeEditorView
//



public struct SyntaxTheme {
    public let baseFont: PlatformFont
    public let baseColor: PlatformColor
    public let captureColors: [String: PlatformColor]

    public init(
        baseFont: PlatformFont = .monospacedSystemFont(ofSize: 16, weight: .medium),
        baseColor: PlatformColor = .platformLabel,
        captureColors: [String: PlatformColor] = [:]
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
            baseColor: .platformLabel,
            captureColors: [
                "keyword": .systemPink,
                "function": .systemCyan,
                "function.builtin": .systemCyan,
                "type": .systemMint,
                "variable": .platformLabel,
                "property": .systemTeal,
                "operator": .platformLabel,
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
