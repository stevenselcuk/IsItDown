//
//  FocusViewHelper.swift
//  YouBar
//
//  Created by Steven J. Selcuk on 16.08.2022.
//

import Cocoa
import SwiftUI

class FocusNSView: NSView {
    override var acceptsFirstResponder: Bool {
        return true
    }
}

/// Gets the keyboard focus if nothing else is focused.
struct FocusView: NSViewRepresentable {

    func makeNSView(context: NSViewRepresentableContext<FocusView>) -> FocusNSView {
        return FocusNSView()
    }

    func updateNSView(_ nsView: FocusNSView, context: Context) {

        // Delay making the view the first responder to avoid SwiftUI errors.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            if let window = nsView.window {

                // Only set the focus if nothing else is focused.
                if let _ = window.firstResponder as? NSWindow {
                    window.makeFirstResponder(nsView)
                }
            }
        }
    }
}
