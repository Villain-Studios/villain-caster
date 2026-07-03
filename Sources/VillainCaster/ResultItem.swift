import AppKit

struct ResultItem {
    var icon: NSImage?
    var title: String
    var subtitle: String?
    /// Stable id for usage tracking ("app:<path>" / "command:<title>");
    /// nil for untracked rows like weather or loading placeholders.
    var usageKey: String? = nil
    var action: (() -> Void)?
}

/// Persists how often each item was executed so the empty query can show
/// the most-used ones.
enum UsageStore {
    private static let defaultsKey = "usageCounts"

    static func record(_ id: String) {
        var counts = UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: Int] ?? [:]
        counts[id, default: 0] += 1
        UserDefaults.standard.set(counts, forKey: defaultsKey)
    }

    static func top(_ limit: Int) -> [String] {
        let counts = UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: Int] ?? [:]
        return counts
            .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .prefix(limit)
            .map(\.key)
    }
}

enum Clipboard {
    static func copy(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
}
