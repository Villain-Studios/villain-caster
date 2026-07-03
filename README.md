# VillainCaster

Minimal Spotlight/Raycast replacement. Only the features you actually use.

## Features

- **⌘Space** opens a single input field (nothing else)
- **Fuzzy app search** — type `saf` → Safari, ⏎ launches
- **Calculator** — `33 / 3`, `(2 + 3) * 4`, `2^10`, ⏎ copies result
- **Currency** — `32 sek to eur` (ECB rates via frankfurter.dev, no API key)
- **Weather** — `weather` (location via ipapi.co, data via open-meteo.com, no API key)
- **Window management** — `maximize` fills the screen with the focused window,
  `move window to next display` sends it to the other monitor (only listed when
  a second display is connected). Requires Accessibility permission: the system
  prompts on first use; grant it, then restart VillainCaster.
- No file search. On purpose.

## Build & run

```sh
make run        # build + run directly (dev)
make app        # build build/VillainCaster.app
make install    # copy to /Applications
```

## Important: free up ⌘Space

Spotlight owns ⌘Space by default. Disable it first:

System Settings → Keyboard → Keyboard Shortcuts… → Spotlight →
uncheck "Show Spotlight search".

Then start VillainCaster.

## Keys

| Key | Action |
|-----|--------|
| ⌘Space | toggle panel |
| ↑ / ↓ | move selection |
| ⏎ | launch app / copy result |
| Esc | close |
| ⌘S | save screenshot of the panel to Desktop |

## Autostart

System Settings → General → Login Items → add `/Applications/VillainCaster.app`.
