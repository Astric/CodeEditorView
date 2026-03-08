#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

//
//  CodeEditor.swift
//  CodeEditorView
//

import SwiftUI


public struct CodeEditor: PlatformViewRepresentable {
    private let code: String
    private let language: LanguageConfiguration?
    private var isWordWrapEnabled: Bool = false
    private var customBackgroundColor: PlatformColor = .platformSystemBackground
    private var customTheme: SyntaxTheme = .default

    public init(code: String, language: LanguageConfiguration? = nil) {
        self.code = code
        self.language = language
    }

    public func wordWrap(_ enabled: Bool = true) -> Self {
        var copy = self
        copy.isWordWrapEnabled = enabled
        return copy
    }

    public func backgroundColor(_ color: PlatformColor) -> Self {
        var copy = self
        copy.customBackgroundColor = color
        return copy
    }

    public func font(_ font: PlatformFont) -> Self {
        var copy = self
        copy.customTheme = SyntaxTheme(
            baseFont: font,
            baseColor: copy.customTheme.baseColor,
            captureColors: copy.customTheme.captureColors
        )
        return copy
    }

    public func theme(_ theme: SyntaxTheme) -> Self {
        var copy = self
        copy.customTheme = theme
        return copy
    }

    public func makePlatformView(context: Context) -> CodeEditorView {
        let view = CodeEditorView()
        updateView(view)
        return view
    }

    public func updatePlatformView(_ uiView: CodeEditorView, context: Context) {
        updateView(uiView)
    }

    private func updateView(_ view: CodeEditorView) {
        view.platformBackgroundColor = customBackgroundColor
        view.wordWrap = isWordWrapEnabled

        if let language = language {
            do {
                let highlighter = try SyntaxHighlighter(configuration: language, theme: customTheme)
                view.text = highlighter.highlight(code)
            } catch {
                print("CodeEditor failed to highlight: \(error)")
                view.text = NSAttributedString(
                    string: code, attributes: [.font: customTheme.baseFont])
            }
        } else {
            view.text = NSAttributedString(string: code, attributes: [.font: customTheme.baseFont])
        }
    }
}
