#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

//
//  CoreTextCanvasView.swift
//  CodeEditorView
//

import CoreText


protocol CoreTextCanvasViewDelegate: AnyObject {
    func canvasView(
        _ canvas: CoreTextCanvasView,
        didLayoutLines lines: [(lineNumber: Int, y: CGFloat, height: CGFloat)]
    )
}

class CustomCATiledLayer: CATiledLayer {
    override class func fadeDuration() -> CFTimeInterval { 0 }
}

class CoreTextCanvasView: PlatformView {

    #if os(macOS)
    override var isFlipped: Bool { true }
    #endif

    weak var delegate: CoreTextCanvasViewDelegate?

    private var cachedFrameBounds: CGRect = .zero
    private var cachedFramesetter: CTFramesetter?
    private var cachedSize: CGSize?
    private var textFrame: CTFrame?
    private var blinkTimer: Timer?

    private var cursorIndex: Int? {
        didSet {
            updateCursorPosition()
            resetBlinkTimer()
        }
    }

    private var selectionRange: NSRange? {
        didSet {
            setNeedsDisplay()
        }
    }

    private var selectionStart: Int?

    var selectionColor: PlatformColor = PlatformColor.systemBlue.withAlphaComponent(0.3)

    var highlightedCode: NSAttributedString? {
        didSet {
            // Invalidate all caches when text changes
            cachedFramesetter = nil
            cachedSize = nil
            textFrame = nil

            if let text = highlightedCode, text.length > 0 {
                // Create the framesetter once and cache it
                cachedFramesetter = CTFramesetterCreateWithAttributedString(
                    text as CFAttributedString
                )
            }

            setNeedsDisplay()
            setNeedsLayout()
        }
    }

    var wordWrap = false {
        didSet {
            cachedSize = nil
            textFrame = nil
            setNeedsDisplay()
            setNeedsLayout()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        #if os(iOS)
        isUserInteractionEnabled = true
        #endif

        if let tiledLayer = self.layer as? CustomCATiledLayer {
            tiledLayer.tileSize = CGSize(width: 1024, height: 1024)
        }

        setupGestures()
    }

    #if os(iOS)
    private func setupGestures() {
        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(_:))
        )
        addGestureRecognizer(longPress)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: self)

        switch gesture.state {
        case .began:
            if let index = characterIndex(at: point) {
                selectionStart = index
                cursorIndex = index
                selectionRange = nil  // Start a new selection
                becomeFirstResponder()
            }
        case .changed:
            if let currentIndex = characterIndex(at: point), let start = selectionStart {
                let location = min(start, currentIndex)
                let length = abs(currentIndex - start)
                selectionRange = NSRange(location: location, length: length)
                cursorIndex = currentIndex  // Move cursor as we drag
            }
        case .ended, .cancelled:
            if let range = selectionRange, range.length > 0 {
                // Show edit menu
            } else {
                selectionStart = nil
            }
        default:
            break
        }
    }
    #else
    private func setupGestures() {}
    #endif

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    #if os(iOS)
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return platformSizeThatFits(size)
    }
    #endif

    func platformSizeThatFits(_ size: CGSize) -> CGSize {
        // Return cached size if available
        if let cachedSize = cachedSize { return cachedSize }

        guard let text = highlightedCode, text.length > 0,
            let framesetter = cachedFramesetter
        else { return .zero }

        let width = wordWrap ? size.width : CGFloat.greatestFiniteMagnitude

        let constraints = CGSize(width: width, height: .greatestFiniteMagnitude)

        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRangeMake(0, text.length),
            nil,
            constraints,
            nil
        )

        let result = CGSize(
            width: ceil(suggestedSize.width) + 20, height: ceil(suggestedSize.height) + 20)
        cachedSize = result
        return result
    }

    #if os(iOS)
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }
    #elseif os(macOS)
    override func layout() {
        super.layout()
        updateLayout()
    }
    #endif

    private func updateLayout() {
        ensureTextFrame()
        delegate?.canvasView(self, didLayoutLines: computeAllLinePositions())
    }

    // Maps each CTLine to a logical source line number and returns its UIKit Y position.
    private func computeAllLinePositions() -> [(lineNumber: Int, y: CGFloat, height: CGFloat)] {
        guard let frame = textFrame, let text = highlightedCode else { return [] }

        // Build an array of character offsets where each logical line starts
        let string = text.string as NSString
        var lineStartOffsets: [Int] = [0]
        for i in 0..<string.length where string.character(at: i) == 10 {  // '\n'
            lineStartOffsets.append(i + 1)
        }

        let lines = CTFrameGetLines(frame) as! [CTLine]
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &origins)

        var result: [(lineNumber: Int, y: CGFloat, height: CGFloat)] = []
        var lastLogicalLine = -1

        for i in 0..<lines.count {
            let line = lines[i]
            let origin = origins[i]
            let stringRange = CTLineGetStringRange(line)

            // Find which logical line this CTLine belongs to
            let logicalLine = lineStartOffsets.lastIndex(where: { $0 <= stringRange.location }) ?? 0

            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            var leading: CGFloat = 0
            CTLineGetTypographicBounds(line, &ascent, &descent, &leading)

            // Convert from CoreText to UIKit (top-left) coordinate system
            let uiKitY = bounds.height - (origin.y + ascent)
            let lineHeight = ascent + descent + leading

            // skip wrapped continuations
            if logicalLine != lastLogicalLine {
                result.append((lineNumber: logicalLine + 1, y: uiKitY, height: lineHeight))
                lastLogicalLine = logicalLine
            }
        }

        return result
    }

    private func ensureTextFrame() {
        guard let text = highlightedCode, text.length > 0,
            let framesetter = cachedFramesetter
        else {
            textFrame = nil
            return
        }

        let drawingRect = bounds.insetBy(dx: 10, dy: 10)

        if textFrame != nil && cachedFrameBounds == drawingRect { return }

        let path = CGPath(rect: drawingRect, transform: nil)
        textFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, text.length), path, nil)
        cachedFrameBounds = drawingRect
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
        guard let context = PlatformGraphicsContext.current,
            highlightedCode != nil
        else { return }

        // Reuse the cached frame
        ensureTextFrame()
        guard let frame = textFrame else { return }

        context.saveGState()

        #if os(iOS)
        // Flip the coordinate system for CoreText on iOS
        context.textMatrix = .identity
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1.0, y: -1.0)
        let flippedRect = CGRect(
            x: rect.origin.x,
            y: bounds.height - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
        #elseif os(macOS)
        // In a flipped NSView, Y goes down. CoreText draws text upright if textMatrix Y scale is -1.
        context.textMatrix = CGAffineTransform(scaleX: 1.0, y: -1.0)
        let flippedRect = rect // No flip needed for bounds checking since we draw in top-left
        #endif

        let lines = CTFrameGetLines(frame) as! [CTLine]
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &origins)

        // selection background
        if let selectionRange = selectionRange, selectionRange.length > 0 {
            selectionColor.setFill()

            for i in 0..<lines.count {
                let line = lines[i]
                let lineRange = CTLineGetStringRange(line)
                let intersection = NSIntersectionRange(
                    NSRange(location: lineRange.location, length: lineRange.length), selectionRange)

                if intersection.length > 0 {
                    let xStart = CTLineGetOffsetForStringIndex(line, intersection.location, nil)
                    let xEnd = CTLineGetOffsetForStringIndex(
                        line, intersection.location + intersection.length, nil)

                    var ascent: CGFloat = 0
                    var descent: CGFloat = 0
                    var leading: CGFloat = 0
                    CTLineGetTypographicBounds(line, &ascent, &descent, &leading)

                    let origin = origins[i]
                    
                    #if os(iOS)
                    let selectionRect = CGRect(
                        x: origin.x + xStart, y: origin.y - descent, width: xEnd - xStart,
                        height: ascent + descent)
                    #elseif os(macOS)
                    let selectionRect = CGRect(
                        x: origin.x + xStart, y: bounds.height - (origin.y + ascent), width: xEnd - xStart,
                        height: ascent + descent)
                    #endif

                    // Only draw if it's within the current tile's rect
                    if selectionRect.intersects(flippedRect) {
                        context.fill(selectionRect)
                    }
                }
            }
        }

        for i in 0..<lines.count {
            let origin = origins[i]
            let line = lines[i]

            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            var leading: CGFloat = 0
            CTLineGetTypographicBounds(line, &ascent, &descent, &leading)

            #if os(iOS)
            let lineTop = origin.y + ascent
            let lineBottom = origin.y - descent - leading
            if lineTop < flippedRect.minY || lineBottom > flippedRect.maxY { continue }
            context.textPosition = origin
            #elseif os(macOS)
            let uiKitY = bounds.height - (origin.y + ascent)
            let lineTop = uiKitY
            let lineBottom = uiKitY + ascent + descent + leading
            if lineBottom < flippedRect.minY || lineTop > flippedRect.maxY { continue }
            context.textPosition = CGPoint(x: origin.x, y: bounds.height - origin.y)
            #endif

            CTLineDraw(line, context)
        }
        
        context.restoreGState()
    }

    private lazy var cursorLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = PlatformColor.platformBlue.cgColor
        layer.isHidden = true
        #if os(iOS)
        self.layer.addSublayer(layer)
        #elseif os(macOS)
        self.wantsLayer = true
        self.layer?.addSublayer(layer)
        #endif
        return layer
    }()

    #if os(iOS)
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.becomeFirstResponder()

        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        handlePointerEvent(at: point)
    }
    #elseif os(macOS)
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        self.window?.makeFirstResponder(self)
        let point = convert(event.locationInWindow, from: nil)
        handlePointerEvent(at: point)
    }
    #endif

    private func handlePointerEvent(at point: CGPoint) {
        if let index = characterIndex(at: point) {
            cursorIndex = index
            selectionRange = nil
        }
    }

    /// Positions the cursor layer using CoreText line geometry — no redraw needed
    private func updateCursorPosition() {
        guard let cursorIndex = cursorIndex, let frame = textFrame else {
            cursorLayer.isHidden = true
            return
        }

        let lines = CTFrameGetLines(frame) as! [CTLine]
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &origins)

        for i in 0..<lines.count {
            let line = lines[i]
            let stringRange = CTLineGetStringRange(line)

            if cursorIndex >= stringRange.location
                && cursorIndex <= stringRange.location + stringRange.length
            {
                let origin = origins[i]
                let xOffset = CTLineGetOffsetForStringIndex(line, cursorIndex, nil)

                var ascent: CGFloat = 0
                var descent: CGFloat = 0
                CTLineGetTypographicBounds(line, &ascent, &descent, nil)

                // Convert from CoreText (bottom-left) to UIKit (top-left) coordinates
                let uiKitY = bounds.height - (origin.y + ascent)

                CATransaction.begin()
                CATransaction.setDisableActions(true)
                cursorLayer.frame = CGRect(
                    x: origin.x + xOffset,
                    y: uiKitY,
                    width: 2.0,
                    height: ascent + descent
                )
                cursorLayer.isHidden = false
                CATransaction.commit()

                break
            }
        }
    }

    private func resetBlinkTimer() {
        blinkTimer?.invalidate()
        cursorLayer.isHidden = false

        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.cursorIndex != nil else { return }
            self.cursorLayer.isHidden.toggle()
        }
    }

    func characterIndex(at point: CGPoint) -> Int? {
        guard let frame = textFrame else { return nil }

        // Flip the Y-coordinate to match CoreText's bottom-left origin
        let flippedY = bounds.height - point.y
        let coreTextPoint = CGPoint(x: point.x, y: flippedY)

        // Get all the lines and their origins
        let lines = CTFrameGetLines(frame) as! [CTLine]
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &origins)

        // Loop through the lines to find the one we tapped
        for i in 0..<lines.count {
            let line = lines[i]
            let origin = origins[i]

            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            var leading: CGFloat = 0
            CTLineGetTypographicBounds(line, &ascent, &descent, &leading)

            let lineBottom = origin.y - descent - leading
            let lineTop = origin.y + ascent

            if coreTextPoint.y >= lineBottom && coreTextPoint.y <= lineTop {
                let relativePoint = CGPoint(
                    x: coreTextPoint.x - origin.x, y: coreTextPoint.y - origin.y)
                let index = CTLineGetStringIndexForPosition(line, relativePoint)
                return index
            }
        }

        return nil
    }
}

#if os(iOS)
extension CoreTextCanvasView: UIKeyInput {
    override class var layerClass: AnyClass {
        return CustomCATiledLayer.self
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
    var hasText: Bool {
        return highlightedCode?.length ?? 0 > 0
    }

    func insertText(_ text: String) {
        print("Keyboard sent character: \(text)")
    }

    func deleteBackward() {
        print("Keyboard sent backspace!")
    }

    override func copy(_ sender: Any?) {
        guard let selectionRange = selectionRange,
            let text = highlightedCode?.string,
            let range = Range(selectionRange, in: text)
        else { return }
        PlatformPasteboard.setString(String(text[range]))
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copy(_:)) {
            return selectionRange != nil && selectionRange!.length > 0
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
#elseif os(macOS)
extension CoreTextCanvasView {
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    @objc func copy(_ sender: Any?) {
        guard let selectionRange = selectionRange,
            let text = highlightedCode?.string,
            let range = Range(selectionRange, in: text)
        else { return }
        PlatformPasteboard.setString(String(text[range]))
    }
}
#endif
