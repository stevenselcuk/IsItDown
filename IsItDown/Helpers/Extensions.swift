//
//  Extensions.swift
//  YouBar
//
//  Created by Steven J. Selcuk on 16.08.2022.
//

import Foundation
import Cocoa
extension UserDefaults {
    public func optionalString(forKey defaultName: String) -> String? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? String
        }
        return nil
    }

    public func optionalAny(forKey defaultName: String) -> Any? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value
        }
        return nil
    }

    public func optionalInt(forKey defaultName: String) -> Int? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Int
        }
        return nil
    }

    public func optionalBool(forKey defaultName: String) -> Bool? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Bool
        }
        return nil
    }
    public func optionalFloat(forKey defaultName: String) -> Float? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Float
        }
        return nil
    }
}


extension NSWindow {
    /// Positions the `NSWindow` at the horizontal-vertical center of the `visibleFrame` (takes Status Bar and Dock sizes into account)
    public func positionCenter() {
        if let screenSize = screen?.visibleFrame.size {
            setFrameOrigin(NSPoint(x: (screenSize.width - frame.size.width) / 2, y: (screenSize.height - frame.size.height) / 2))
        }
    }

    public func positionTopCenter() {
        if let screenSize = screen?.visibleFrame.size {
            setFrameOrigin(NSPoint(x: (screenSize.width - frame.size.width) / 2, y: (screenSize.height - frame.size.height) - 100))
        }
    }

    /// Centers the window within the `visibleFrame`, and sizes it with the width-by-height dimensions provided.
    public func setCenterFrame(width: Int, height: Int) {
        if let screenSize = screen?.visibleFrame.size {
            let x = (screenSize.width - frame.size.width) / 2
            let y = (screenSize.height - frame.size.height) / 2
            setFrame(NSRect(x: x, y: y, width: CGFloat(width), height: CGFloat(height)), display: true)
        }
    }

    /// Returns the center x-point of the `screen.visibleFrame` (the frame between the Status Bar and Dock).
    /// Falls back on `screen.frame` when `.visibleFrame` is unavailable (includes Status Bar and Dock).
    public func xCenter() -> CGFloat {
        if let screenSize = screen?.visibleFrame.size { return (screenSize.width - frame.size.width) / 2 }
        if let screenSize = screen?.frame.size { return (screenSize.width - frame.size.width) / 2 }
        return CGFloat(0)
    }

    /// Returns the center y-point of the `screen.visibleFrame` (the frame between the Status Bar and Dock).
    /// Falls back on `screen.frame` when `.visibleFrame` is unavailable (includes Status Bar and Dock).
    public func yCenter() -> CGFloat {
        if let screenSize = screen?.visibleFrame.size { return (screenSize.height - frame.size.height) / 2 }
        if let screenSize = screen?.frame.size { return (screenSize.height - frame.size.height) / 2 }
        return CGFloat(0)
    }
}
