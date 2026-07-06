# VillainCaster

Minimal Spotlight/Raycast replacement. Only the features you actually use.

## Features

Type `help` (or `?`) in the launcher for this list in-app.

| Input | Does |
|-------|------|
| `wez` | Fuzzy app search, ⏎ launches |
| `33 / 3` | Calculator — `+ - * / % ^ ( )`, result inline, ⏎ copies |
| `32 sek to eur` | Currency — codes, names or symbols (`5 euro to dollar`); ECB rates via frankfurter.dev, exotic currencies via open.er-api.com |
| `time in tokyo` | World clock — tz cities, `nyc`, `cet`; bare `time` = local |
| `weather` | Current conditions + next 3 days (ipapi.co + open-meteo.com) |
| `emoji shrug` | Emoji search, ⏎ copies |
| `g` / `yt` / `gh` + query | Web search — Google, YouTube, GitHub |
| `work email` | Snippets — copy your emails/phone/address; set values via menu bar icon → Settings… |
| `maximize` | Fill screen with the focused window¹ |
| `move window` | Send focused window to next display (only with 2+ monitors)¹ |
| `sleep` / `lock` / `trash` / `dark` | Sleep Mac, lock screen, empty trash², toggle dark mode² |
| `quit` | Quit VillainCaster |
| *(empty)* | Your 3 most-used items (frecency: usage count with 7-day half-life) |

¹ needs Accessibility permission — ² needs a one-time Automation approval

No file search. On purpose. No API keys anywhere.

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
