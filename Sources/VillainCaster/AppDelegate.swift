import AppKit
import Carbon.HIToolbox

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: PanelController!
    private var statusItem: NSStatusItem!
    private let hotKey = HotKeyManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        panelController = PanelController()
        setUpStatusItem()
        hotKey.onPress = { [weak self] in
            self?.panelController.toggle()
        }
        let registered = hotKey.register(keyCode: UInt32(kVK_Space), modifiers: UInt32(cmdKey))
        if !registered {
            NSLog("VillainCaster: could not register ⌘Space. Disable Spotlight's shortcut in System Settings → Keyboard → Keyboard Shortcuts → Spotlight.")
        }
    }

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "VillainCaster")
        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            let menu = NSMenu()
            let settingsItem = NSMenuItem(title: "Settings…",
                                          action: #selector(openSettings),
                                          keyEquivalent: ",")
            settingsItem.target = self
            menu.addItem(settingsItem)
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "Quit VillainCaster",
                                    action: #selector(NSApplication.terminate(_:)),
                                    keyEquivalent: "q"))
            // Attach the menu only for this click so left-click keeps toggling the panel.
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            panelController.toggle()
        }
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }
}
