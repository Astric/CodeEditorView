#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

//
//  CodeEditorView.swift
//  CodeEditorView
//



#if os(macOS)
class FlippedView: PlatformView {
    override var isFlipped: Bool { true }
}
#endif

public class CodeEditorView: PlatformScrollView {

    #if os(macOS)
    public override var isFlipped: Bool { true }
    #endif

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

    #if os(macOS)
    private func setupScrollListener() {
        self.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(boundsDidChange),
            name: NSView.boundsDidChangeNotification,
            object: self.contentView
        )
    }

    @objc private func boundsDidChange(_ notification: Notification) {
        gutterView.update(lines: linePositions, scrollOffsetY: platformContentOffset.y)
    }
    #endif

    private func setup() {
        self.platformBackgroundColor = .platformSystemBackground
        canvas.platformBackgroundColor = .clear
        canvas.delegate = self
        gutterView.platformBackgroundColor = .platformSecondarySystemBackground

        #if os(iOS)
        addSubview(canvas)
        addSubview(gutterView)
        delaysContentTouches = false
        #elseif os(macOS)
        let container = FlippedView()
        container.addSubview(canvas)
        self.documentView = container
        self.addSubview(gutterView)
        
        self.hasVerticalScroller = true
        self.hasHorizontalScroller = true
        self.autohidesScrollers = true
        self.drawsBackground = false
        
        setupScrollListener()
        #endif
    }

    #if os(iOS)
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }
    #elseif os(macOS)
    public override func layout() {
        super.layout()
        updateLayout()
    }
    #endif

    private func updateLayout() {
        let gutterWidth = GutterView.width
        let gutterSpacing: CGFloat = 4.0

        // Canvas gets the width minus the gutter so word-wrap works correctly
        let availableWidth = bounds.width - gutterWidth - gutterSpacing
        
        #if os(iOS)
        let canvasSize = canvas.sizeThatFits(
            CGSize(
                width: availableWidth,
                height: .greatestFiniteMagnitude
            )
        )
        #elseif os(macOS)
        let canvasSize = canvas.platformSizeThatFits(
            CGSize(
                width: availableWidth,
                height: .greatestFiniteMagnitude
            )
        )
        #endif

        let finalCanvasWidth = max(canvasSize.width, availableWidth)
        let finalCanvasHeight = max(canvasSize.height, bounds.height)

        canvas.frame = CGRect(
            x: gutterWidth + gutterSpacing,
            y: 0,
            width: finalCanvasWidth,
            height: finalCanvasHeight
        )
        
        setPlatformContentSize(CGSize(
            width: gutterWidth + gutterSpacing + finalCanvasWidth,
            height: finalCanvasHeight
        ))

        let currentOffset = platformContentOffset

        #if os(iOS)
        gutterView.frame = CGRect(
            x: currentOffset.x,
            y: currentOffset.y,
            width: gutterWidth,
            height: bounds.height
        )
        #elseif os(macOS)
        gutterView.frame = CGRect(
            x: 0,
            y: 0,
            width: gutterWidth,
            height: bounds.height
        )
        #endif

        gutterView.update(lines: linePositions, scrollOffsetY: currentOffset.y)
    }
}

extension CodeEditorView: CoreTextCanvasViewDelegate {
    func canvasView(
        _ canvas: CoreTextCanvasView,
        didLayoutLines lines: [(lineNumber: Int, y: CGFloat, height: CGFloat)]
    ) {
        linePositions = lines
        gutterView.update(lines: lines, scrollOffsetY: platformContentOffset.y)
    }
}
