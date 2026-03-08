//
//  PlatformViewRepresentable.swift
//  CodeEditorView
//

import SwiftUI

#if os(macOS)
import AppKit

public protocol PlatformViewRepresentable: NSViewRepresentable {
    associatedtype PlatformViewType: NSView
    func makePlatformView(context: Context) -> PlatformViewType
    func updatePlatformView(_ uiView: PlatformViewType, context: Context)
}

extension PlatformViewRepresentable {
    public func makeNSView(context: Context) -> PlatformViewType {
        makePlatformView(context: context)
    }

    public func updateNSView(_ nsView: PlatformViewType, context: Context) {
        updatePlatformView(nsView, context: context)
    }
}

#elseif os(iOS)
import UIKit

public protocol PlatformViewRepresentable: UIViewRepresentable {
    associatedtype PlatformViewType: UIView
    func makePlatformView(context: Context) -> PlatformViewType
    func updatePlatformView(_ uiView: PlatformViewType, context: Context)
}

extension PlatformViewRepresentable {
    public func makeUIView(context: Context) -> PlatformViewType {
        makePlatformView(context: context)
    }

    public func updateUIView(_ uiView: PlatformViewType, context: Context) {
        updatePlatformView(uiView, context: context)
    }
}
#endif
