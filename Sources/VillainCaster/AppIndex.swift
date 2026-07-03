import Foundation

struct AppEntry {
    let name: String
    let url: URL
}

final class AppIndex {
    private var apps: [AppEntry] = []
    private var lastScan: Date = .distantPast
    private let scanQueue = DispatchQueue(label: "villaincaster.appscan", qos: .userInitiated)
    private let lock = NSLock()

    func scanIfNeeded() {
        guard Date().timeIntervalSince(lastScan) > 60 else { return }
        lastScan = Date()
        scanQueue.async { [weak self] in
            guard let self else { return }
            let found = Self.scanAll()
            self.lock.lock()
            self.apps = found
            self.lock.unlock()
        }
    }

    func searchScored(_ query: String) -> [(score: Int, entry: AppEntry)] {
        lock.lock()
        let snapshot = apps
        lock.unlock()

        return snapshot
            .compactMap { entry -> (score: Int, entry: AppEntry)? in
                guard let score = Fuzzy.score(query: query, target: entry.name) else { return nil }
                return (score, entry)
            }
            .sorted { $0.score == $1.score ? $0.entry.name < $1.entry.name : $0.score > $1.score }
    }

    private static func scanAll() -> [AppEntry] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let roots = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            "/System/Library/CoreServices/Applications",
            "\(home)/Applications",
        ]
        var found: [String: AppEntry] = [:]
        for root in roots {
            collect(root, depth: 0, into: &found)
        }
        return Array(found.values)
    }

    private static func collect(_ dir: String, depth: Int, into found: inout [String: AppEntry]) {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(atPath: dir) else { return }
        for item in items where !item.hasPrefix(".") {
            let path = dir + "/" + item
            if item.hasSuffix(".app") {
                found[path] = AppEntry(name: String(item.dropLast(4)), url: URL(fileURLWithPath: path))
            } else if depth < 2 {
                var isDirectory: ObjCBool = false
                if fm.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
                    collect(path, depth: depth + 1, into: &found)
                }
            }
        }
    }
}

enum Fuzzy {
    /// Subsequence match with bonuses for prefix, word-boundary and
    /// consecutive hits. Returns nil when the query is not a subsequence.
    static func score(query: String, target: String) -> Int? {
        let q = Array(query.lowercased())
        let t = Array(target.lowercased())
        guard !q.isEmpty else { return nil }

        var score = 0
        var qi = 0
        var lastMatch = -2
        for (ti, char) in t.enumerated() {
            guard qi < q.count else { break }
            if char == q[qi] {
                var bonus = 10
                if ti == 0 {
                    bonus += 100
                } else if !t[ti - 1].isLetter && !t[ti - 1].isNumber {
                    bonus += 40
                }
                if ti == lastMatch + 1 { bonus += 25 }
                score += bonus
                lastMatch = ti
                qi += 1
            }
        }
        guard qi == q.count else { return nil }
        // Slightly favor shorter names so "Music" beats "Music Converter Pro".
        return score - max(0, t.count - q.count)
    }
}
