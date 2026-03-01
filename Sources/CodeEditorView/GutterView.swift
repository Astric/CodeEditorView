//
//  GutterView.swift
//  CodeEditorView
//

import UIKit

/// The view that displays the line numbers.
/// It's a fixed view, it doesn't scroll alongside the scrollView.
/// Instead, it updates the line numbers as the scrollViewDidScroll
class GutterView: UIView {

    static let width: CGFloat = 44

    private var allLines: [(lineNumber: Int, y: CGFloat, height: CGFloat)] = []
    private var scrollOffsetY: CGFloat = 0

    private let numberAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular),
        .foregroundColor: UIColor.secondaryLabel,
    ]

    func update(lines: [(lineNumber: Int, y: CGFloat, height: CGFloat)], scrollOffsetY: CGFloat) {
        self.allLines = lines
        self.scrollOffsetY = scrollOffsetY
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        // Right-edge separator
        ctx.setFillColor(UIColor.separator.cgColor)
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
