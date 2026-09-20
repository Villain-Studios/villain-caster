import Foundation

/// System-level commands invoked from the launcher.
/// Empty trash and dark mode use AppleScript — macOS shows a one-time
/// Automation permission prompt (Finder / System Events) on first use.
enum SystemActions {
    static func sleep() {
        run("/usr/bin/pmset", ["sleepnow"])
    }

    /// Sleeps the displays; the session locks if "require password after
    /// sleep" is enabled (the default).
    static func lockScreen() {
        run("/usr/bin/pmset", ["displaysleepnow"])
    }

    static func emptyTrash() {
        runAppleScript("tell application \"Finder\" to empty trash")
    }

    /// Dock-style reopen: opens a window when Finder has none, otherwise
    /// brings an existing window forward. Plain activate() is a no-op when
    /// Finder is running with zero windows.
    static func openFinder() {
        runAppleScript("""
        tell application "Finder"
          reopen
          activate
        end tell
        """)
    }

    static func toggleDarkMode() {
        runAppleScript("""
        tell application "System Events" to tell appearance preferences \
        to set dark mode to not dark mode
        """)
    }

    private static func run(_ path: String, _ arguments: [String]) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = arguments
        try? task.run()
    }

    private static func runAppleScript(_ script: String) {
        run("/usr/bin/osascript", ["-e", script])
    }
}
