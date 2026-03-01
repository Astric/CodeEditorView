//
//  CodeEditorView.swift
//  CodeEditorView
//

import UIKit

public class CodeEditorView: UIScrollView {

    private let canvas = CoreTextCanvasView()
    private let gutterView = GutterView()
    private var linePositions: [(lineNumber: Int, y: CGFloat, height: CGFloat)] = []

    public var text: NSAttributedString? {
        didSet {
            canvas.highlightedCode = text
            setNeedsLayout()
        }
    }

    public var wordWrap = false {
        didSet {
            canvas.wordWrap = wordWrap
            setNeedsLayout()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        canvas.backgroundColor = .tertiarySystemBackground
        canvas.delegate = self
        addSubview(canvas)

        gutterView.backgroundColor = .secondarySystemBackground
        addSubview(gutterView)

        delaysContentTouches = false
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let gutterWidth = GutterView.width
        let gutterSpacing: CGFloat = 4.0

        // Canvas gets the width minus the gutter so word-wrap works correctly
        let availableWidth = bounds.width - gutterWidth - gutterSpacing
        let canvasSize = canvas.sizeThatFits(
            CGSize(
                width: availableWidth,
                height: .greatestFiniteMagnitude
            )
        )

        canvas.frame = CGRect(
            x: gutterWidth + gutterSpacing,
            y: 0,
            width: canvasSize.width,
            height: canvasSize.height
        )
        
        contentSize = CGSize(
            width: gutterWidth + gutterSpacing + canvasSize.width,
            height: canvasSize.height
        )

        gutterView.frame = CGRect(
            x: contentOffset.x,
            y: contentOffset.y,
            width: gutterWidth,
            height: bounds.height
        )

        gutterView.update(lines: linePositions, scrollOffsetY: contentOffset.y)
    }
}

extension CodeEditorView: CoreTextCanvasViewDelegate {
    func canvasView(
        _ canvas: CoreTextCanvasView,
        didLayoutLines lines: [(lineNumber: Int, y: CGFloat, height: CGFloat)]
    ) {
        linePositions = lines
        gutterView.update(lines: lines, scrollOffsetY: contentOffset.y)
    }
}
