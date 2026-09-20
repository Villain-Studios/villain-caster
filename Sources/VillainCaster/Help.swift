import AppKit

/// "help" or "?" → cheat sheet of everything the launcher understands.
enum Help {
    /// Shows as soon as the input is unambiguous — "hel"/"help"/"?" — no
    /// Enter needed; longer text ("helium") falls through to app search.
    static func matches(_ text: String) -> Bool {
        let lower = text.lowercased()
        return lower == "?" || (lower.count >= 3 && "help".hasPrefix(lower))
    }

    static func items() -> [ResultItem] {
        var rows: [(icon: String, title: String, subtitle: String)] = [
            ("app.badge", "Type an app name", "Fuzzy search, ⏎ launches — e.g. \"wez\" → WezTerm"),
            ("equal.circle", "33 / 3", "Calculator — + - * / % ^ ( ), result inline, ⏎ copies"),
            ("dollarsign.circle", "32 sek to eur", "Currency — codes, names or symbols (\"5 euro to dollar\")"),
            ("clock", "time in tokyo", "World clock — cities, \"nyc\", \"cet\", bare \"time\" = local"),
            ("cloud.sun", "weather", "Current conditions + next 3 days at your location"),
            ("face.smiling", "emoji shrug", "Emoji search, ⏎ copies"),
            ("magnifyingglass", "g / yt / gh query", "Web search — Google, YouTube, GitHub"),
            ("doc.on.clipboard", "work email", "Snippets — set values via menu bar icon → Settings…"),
            ("macwindow", "maximize", "Monitor size minus the menu bar"),
            ("rectangle.on.rectangle", "move window", "Send focused window to the next display"),
            ("moon.zzz", "sleep / lock / trash / dark", "Sleep Mac, lock screen, empty trash, toggle dark mode"),
            ("keyboard", "Esc close · ⌘S / ⌘⇧S screenshot", "Empty input shows your most-used items"),
        ]
        if !WindowManager.hasSecondDisplay {
            rows.removeAll { $0.title == "move window" }
        }
        return rows.map { row in
            ResultItem(
                icon: NSImage(systemSymbolName: row.icon, accessibilityDescription: row.title)?
                    .withSymbolConfiguration(.init(pointSize: 16, weight: .regular)),
                title: row.title,
                subtitle: row.subtitle,
                action: nil
            )
        }
    }
}
