//
//  GutterView.swift
//  CodeEditorView
//

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// The view that displays the line numbers.
/// It's a fixed view, it doesn't scroll alongside the scrollView.
/// Instead, it updates the line numbers as the scrollViewDidScroll
class GutterView: PlatformView {

    #if os(macOS)
    override var isFlipped: Bool { true }
    #endif

    static let width: CGFloat = 44

    private var allLines: [(lineNumber: Int, y: CGFloat, height: CGFloat)] = []
    private var scrollOffsetY: CGFloat = 0

    private let numberAttributes: [NSAttributedString.Key: Any] = [
        .font: PlatformFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular),
        .foregroundColor: PlatformColor.platformSecondaryLabel,
    ]

    func update(lines: [(lineNumber: Int, y: CGFloat, height: CGFloat)], scrollOffsetY: CGFloat) {
        self.allLines = lines
        self.scrollOffsetY = scrollOffsetY
        setNeedsDisplay()
    }

    #if os(iOS)
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        performDraw(rect)
    }
    #elseif os(macOS)
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        performDraw(dirtyRect)
    }
    #endif

    private func performDraw(_ rect: CGRect) {
        guard let ctx = PlatformGraphicsContext.current else { return }

        // Right-edge separator
        ctx.setFillColor(PlatformColor.platformSeparator.cgColor)
        ctx.fill(
            CGRect(
                x: bounds.maxX - 0.5,
                y: rect.minY,
                width: 0.5,
                height: rect.height
            )
        )

        for entry in allLines {
            let localY = entry.y - scrollOffsetY

            // Skip lines outside the visible rect
            guard localY < rect.maxY, localY + entry.height > rect.minY else { continue }

            let label = "\(entry.lineNumber)" as NSString
            let size = label.size(withAttributes: numberAttributes)

            // Right-align with 8pt padding, vertically centered within the line
            let x = bounds.width - size.width - 8
            let y = localY + (entry.height - size.height) / 2

            label.draw(at: CGPoint(x: x, y: y), withAttributes: numberAttributes)
        }
    }
}
