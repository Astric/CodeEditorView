#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

//
//  PlatformSupport.swift
//  CodeEditorView
//

import SwiftUI
#if os(iOS)


public typealias PlatformView = UIView
public typealias PlatformScrollView = UIScrollView
public typealias PlatformColor = UIColor
public typealias PlatformFont = UIFont
public typealias PlatformImage = UIImage
public typealias PlatformBezierPath = UIBezierPath
public typealias PlatformGestureRecognizer = UIGestureRecognizer

#elseif os(macOS)
import AppKit
public typealias PlatformView = NSView
public typealias PlatformScrollView = NSScrollView
public typealias PlatformColor = NSColor
public typealias PlatformFont = NSFont
public typealias PlatformImage = NSImage
public typealias PlatformBezierPath = NSBezierPath

#endif

#if os(macOS)
extension PlatformView {
    func setNeedsDisplay() {
        self.needsDisplay = true
    }

    func setNeedsLayout() {
        self.needsLayout = true
    }
}
#endif

extension PlatformView {
    var platformBackgroundColor: PlatformColor? {
        get {
            #if os(iOS)
            return backgroundColor
            #elseif os(macOS)
            guard let color = layer?.backgroundColor else { return nil }
            return NSColor(cgColor: color)
            #endif
        }
        set {
            #if os(iOS)
            backgroundColor = newValue
            #elseif os(macOS)
            wantsLayer = true
            layer?.backgroundColor = newValue?.cgColor
            #endif
        }
    }
}

extension PlatformColor {
    public static var platformLabel: PlatformColor {
        #if os(iOS)
        return .label
        #elseif os(macOS)
        return .labelColor
        #endif
    }

    public static var platformSystemBackground: PlatformColor {
        #if os(iOS)
        return .systemBackground
        #elseif os(macOS)
        return .windowBackgroundColor
        #endif
    }

    public static var platformSecondarySystemBackground: PlatformColor {
        #if os(iOS)
        return .secondarySystemBackground
        #elseif os(macOS)
        return .controlBackgroundColor
        #endif
    }

    public static var platformTertiarySystemBackground: PlatformColor {
        #if os(iOS)
        return .tertiarySystemBackground
        #elseif os(macOS)
        return .textBackgroundColor
        #endif
    }

    public static var platformSeparator: PlatformColor {
        #if os(iOS)
        return .separator
        #elseif os(macOS)
        return .separatorColor
        #endif
    }

    public static var platformSecondaryLabel: PlatformColor {
        #if os(iOS)
        return .secondaryLabel
        #elseif os(macOS)
        return .secondaryLabelColor
        #endif
    }

    public static var platformBlue: PlatformColor {
        #if os(iOS)
        return .systemBlue
        #elseif os(macOS)
        return .systemBlue
        #endif
    }
}

struct PlatformPasteboard {
    static func setString(_ string: String) {
        #if os(iOS)
        UIPasteboard.general.string = string
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #endif
    }
}

extension PlatformScrollView {
    var platformContentOffset: CGPoint {
        #if os(iOS)
        return contentOffset
        #elseif os(macOS)
        return contentView.bounds.origin
        #endif
    }

    func setPlatformContentSize(_ size: CGSize) {
        #if os(iOS)
        contentSize = size
        #elseif os(macOS)
        documentView?.setFrameSize(size)
        #endif
    }
}

struct PlatformGraphicsContext {
    static var current: CGContext? {
        #if os(iOS)
        return UIGraphicsGetCurrentContext()
        #elseif os(macOS)
        return NSGraphicsContext.current?.cgContext
        #endif
    }
}
