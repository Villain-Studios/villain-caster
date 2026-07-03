import AppKit

/// What the panel should render for a query.
enum QueryOutput {
    case empty
    case list([ResultItem])
    /// Shown inline to the right of the input; `copyValue` is what ⏎ copies.
    case inline(display: String, copyValue: String?)
}

/// A built-in action that competes with apps in the fuzzy search.
private struct Command {
    let title: String
    let subtitle: String
    let symbol: String
    let isAvailable: () -> Bool
    let run: () -> Void
}

final class QueryEngine {
    private let appIndex = AppIndex()
    private var generation = 0
    private var pendingNetworkWork: DispatchWorkItem?

    private let commands: [Command] = [
        Command(title: "Maximize Window",
                subtitle: "Fill the screen with the focused window",
                symbol: "macwindow",
                isAvailable: { true },
                run: { WindowManager.maximizeFocusedWindow() }),
        Command(title: "Move Window to Next Display",
                subtitle: "Send the focused window to the other monitor",
                symbol: "rectangle.on.rectangle",
                isAvailable: { WindowManager.hasSecondDisplay },
                run: { WindowManager.moveFocusedWindowToNextDisplay() }),
        Command(title: "Quit VillainCaster",
                subtitle: "Close this launcher",
                symbol: "power",
                isAvailable: { true },
                run: { NSApp.terminate(nil) }),
    ]

    func refreshApps() {
        appIndex.scanIfNeeded()
    }

    /// Routes the query to the right handler. `deliver` may be called more
    /// than once (loading placeholder, then final results); stale async
    /// results are dropped via the generation counter.
    func query(_ raw: String, deliver: @escaping (QueryOutput) -> Void) {
        generation += 1
        let gen = generation
        pendingNetworkWork?.cancel()

        let text = raw.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else {
            let frequent = frequentItems()
            deliver(frequent.isEmpty ? .empty : .list(frequent))
            return
        }

        if let currencyQuery = CurrencyQuery.parse(text) {
            deliver(.inline(display: "= …", copyValue: nil))
            debounced(gen) { finish in
                Currency.convert(currencyQuery) { display, copyValue in
                    finish(.inline(display: display, copyValue: copyValue))
                }
            } deliver: { deliver($0) }
            return
        }

        if Weather.matches(text) {
            deliver(.list([ResultItem(icon: nil, title: "Fetching weather…", subtitle: nil, action: nil)]))
            debounced(gen) { finish in
                Weather.fetch { finish(.list($0)) }
            } deliver: { deliver($0) }
            return
        }

        if let value = Calculator.evaluate(text) {
            deliver(.inline(display: "= \(value)", copyValue: value))
            return
        }

        // Frecency boost: items you actually launch outrank same-fuzzy-score
        // neighbors ("zen" → Zen Browser above an app literally named Zen),
        // and the boost fades for things not used in a while.
        let frecency = UsageStore.decayedAll()
        func boost(_ item: ResultItem) -> Int {
            guard let key = item.usageKey else { return 0 }
            return Int(min(frecency[key] ?? 0, 20) * 10)
        }

        var scored: [(score: Int, item: ResultItem)] = appIndex.searchScored(text).map { score, entry in
            let item = appItem(entry)
            return (score + boost(item), item)
        }
        for command in commands where command.isAvailable() {
            guard let score = Fuzzy.score(query: text, target: command.title) else { continue }
            let item = commandItem(command)
            scored.append((score + boost(item), item))
        }
        scored.sort { $0.score > $1.score }
        deliver(.list(scored.prefix(8).map(\.item)))
    }

    // MARK: - Item builders

    private func appItem(_ entry: AppEntry) -> ResultItem {
        ResultItem(
            icon: NSWorkspace.shared.icon(forFile: entry.url.path),
            title: entry.name,
            subtitle: nil,
            usageKey: "app:\(entry.url.path)",
            action: { NSWorkspace.shared.openApplication(at: entry.url,
                                                         configuration: NSWorkspace.OpenConfiguration()) }
        )
    }

    private func commandItem(_ command: Command) -> ResultItem {
        let icon = NSImage(systemSymbolName: command.symbol, accessibilityDescription: command.title)?
            .withSymbolConfiguration(.init(pointSize: 16, weight: .regular))
        return ResultItem(
            icon: icon,
            title: command.title,
            subtitle: command.subtitle,
            usageKey: "command:\(command.title)",
            action: command.run
        )
    }

    /// Most-executed items, shown when the input is empty.
    private func frequentItems() -> [ResultItem] {
        var items: [ResultItem] = []
        for key in UsageStore.top(10) {
            if key.hasPrefix("app:") {
                let path = String(key.dropFirst(4))
                guard FileManager.default.fileExists(atPath: path) else { continue }
                var name = (path as NSString).lastPathComponent
                if name.hasSuffix(".app") { name = String(name.dropLast(4)) }
                items.append(appItem(AppEntry(name: name, url: URL(fileURLWithPath: path))))
            } else if key.hasPrefix("command:") {
                let title = String(key.dropFirst(8))
                guard let command = commands.first(where: { $0.title == title }),
                      command.isAvailable() else { continue }
                items.append(commandItem(command))
            }
            if items.count == 3 { break }
        }
        return items
    }

    /// Runs a network fetch after a short debounce so keystrokes don't spam
    /// the APIs. Results are only delivered if the query hasn't changed.
    private func debounced(_ gen: Int,
                           _ fetch: @escaping (@escaping (QueryOutput) -> Void) -> Void,
                           deliver: @escaping (QueryOutput) -> Void) {
        let work = DispatchWorkItem { [weak self] in
            fetch { output in
                DispatchQueue.main.async {
                    guard let self, gen == self.generation else { return }
                    deliver(output)
                }
            }
        }
        pendingNetworkWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
    }
}
