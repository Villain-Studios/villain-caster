import AppKit
import ApplicationServices

/// Moves/resizes the focused window of the frontmost app via the
/// Accessibility API. Works because the launcher panel is non-activating:
/// the user's app stays frontmost while our panel is open.
///
/// Requires Accessibility permission (System Settings → Privacy & Security
/// → Accessibility). First use triggers the system prompt.
enum WindowManager {

    /// Fills the window's current screen (visible frame, keeps menu bar/Dock).
    @discardableResult
    static func maximizeFocusedWindow() -> Bool {
        guard ensureAccessibility() else { return false }
        guard let window = focusedWindow(), let axFrame = frame(of: window) else { return false }
        let cocoaFrame = axToCocoa(axFrame)
        guard let screen = screenContaining(cocoaFrame) else { return false }
        setFrame(cocoaToAX(screen.visibleFrame), on: window)
        return true
    }

    /// Moves the window to the next display, keeping its size (clamped) and
    /// relative position within the screen.
    @discardableResult
    static func moveFocusedWindowToNextDisplay() -> Bool {
        let screens = NSScreen.screens
        guard screens.count > 1 else { return false }
        guard ensureAccessibility() else { return false }
        guard let window = focusedWindow(), let axFrame = frame(of: window) else { return false }

        let cocoaFrame = axToCocoa(axFrame)
        guard let currentScreen = screenContaining(cocoaFrame),
              let currentIndex = screens.firstIndex(of: currentScreen) else { return false }
        let target = screens[(currentIndex + 1) % screens.count].visibleFrame
        let source = currentScreen.visibleFrame

        let size = CGSize(width: min(cocoaFrame.width, target.width),
                          height: min(cocoaFrame.height, target.height))
        // Preserve the window's relative position on the new screen.
        let relX = source.width > cocoaFrame.width
            ? (cocoaFrame.minX - source.minX) / (source.width - cocoaFrame.width) : 0
        let relY = source.height > cocoaFrame.height
            ? (cocoaFrame.minY - source.minY) / (source.height - cocoaFrame.height) : 0
        let origin = CGPoint(
            x: target.minX + relX.clamped01 * (target.width - size.width),
            y: target.minY + relY.clamped01 * (target.height - size.height)
        )
        setFrame(cocoaToAX(CGRect(origin: origin, size: size)), on: window)
        return true
    }

    static var hasSecondDisplay: Bool {
        NSScreen.screens.count > 1
    }

    // MARK: - Accessibility plumbing

    /// True when trusted; otherwise shows the system permission prompt once.
    private static func ensureAccessibility() -> Bool {
        if AXIsProcessTrusted() { return true }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        return false
    }

    private static func focusedWindow() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var window: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &window) == .success
        else { return nil }
        return (window as! AXUIElement)
    }

    private static func frame(of window: AXUIElement) -> CGRect? {
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success
        else { return nil }
        var position = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(positionRef as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
        return CGRect(origin: position, size: size)
    }

    private static func setFrame(_ rect: CGRect, on window: AXUIElement) {
        var position = rect.origin
        var size = rect.size
        if let value = AXValueCreate(.cgPoint, &position) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
        }
        if let value = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
        }
        // Some apps clamp the size against the old position — set it again.
        if let value = AXValueCreate(.cgPoint, &position) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
        }
    }

    // MARK: - Coordinate conversion
    // AX uses a top-left origin (y grows down, relative to the primary
    // screen's top edge); Cocoa uses bottom-left (y grows up). The mapping is
    // symmetric around the primary screen's height.

    private static var primaryHeight: CGFloat {
        NSScreen.screens.first?.frame.maxY ?? 0
    }

    private static func axToCocoa(_ rect: CGRect) -> CGRect {
        CGRect(x: rect.minX, y: primaryHeight - rect.minY - rect.height,
               width: rect.width, height: rect.height)
    }

    private static func cocoaToAX(_ rect: CGRect) -> CGRect {
        CGRect(x: rect.minX, y: primaryHeight - rect.minY - rect.height,
               width: rect.width, height: rect.height)
    }

    private static func screenContaining(_ cocoaFrame: CGRect) -> NSScreen? {
        NSScreen.screens.max { a, b in
            a.frame.intersection(cocoaFrame).area < b.frame.intersection(cocoaFrame).area
        } ?? NSScreen.main
    }
}

private extension CGRect {
    var area: CGFloat { isNull ? 0 : width * height }
}

private extension CGFloat {
    var clamped01: CGFloat { Swift.min(Swift.max(self, 0), 1) }
}
