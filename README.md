# Spotless

A tiny macOS app that pauses your keyboard with one click, so you can wipe down your
keyboard and MacBook without typing gibberish or triggering shortcuts.

- One button: **Lock** swallows every key (letters, modifiers, media/brightness/volume keys).
  Click **Unlock** with the trackpad or mouse when you're done.
- **Auto-release:** the keyboard is handed back the moment the screen locks, the screen saver
  starts, the display or Mac sleeps, the user switches, or the Mac shuts down — so you can always
  type your password at the login screen.
- Live counter of keys caught while locked.

> The Touch ID / power key is handled by macOS itself and can't be blocked. If you press it,
> the Mac locks and Spotless releases the keyboard automatically.

## Requirements

- macOS 14 or later
- Xcode command line tools (`xcode-select --install`)

## Build & run

```sh
./build.sh          # builds Spotless.app in the project root
open Spotless.app
```

On first launch click **Grant Access** and enable Spotless in
System Settings → Privacy & Security → Accessibility. The app is ad-hoc signed, so macOS may ask
again after a rebuild (remove the old entry and re-add it if the toggle seems stuck).

To install, drag `Spotless.app` into `/Applications`.

## Releasing a new version

```sh
./build.sh 1.1.0    # writes VERSION, builds; build number = git commit count
```

Log every version in [docs/HISTORY.md](docs/HISTORY.md) and tag it: `git tag v1.1.0`.

## Checking the UI without a screen

```sh
Spotless.app/Contents/MacOS/Spotless --render-previews /tmp/spotless-previews
```

Writes a PNG of every UI state (needs permission, ready, locked, auto-released).

## Regenerating the icon

```sh
swift Tools/make-icon.swift /tmp/AppIcon.iconset
iconutil -c icns /tmp/AppIcon.iconset -o Assets/AppIcon.icns
```

## Layout

| Path | What |
| --- | --- |
| `Sources/KeyboardBlocker.swift` | CGEventTap that swallows keys; lock/sleep observers; Accessibility permission |
| `Sources/ContentView.swift` | The whole UI and the colour `Palette` |
| `Sources/SpotlessApp.swift` | App entry point, window styling, `--render-previews` flag |
| `Sources/PreviewRenderer.swift` | Off-screen PNG renders of each UI state |
| `Tools/make-icon.swift` | Draws the app icon |
| `Assets/AppIcon.icns` | Generated icon (committed) |
| `build.sh` | Compiles with `swiftc` and assembles the `.app` bundle |
