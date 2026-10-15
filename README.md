# Paws Off

A tiny macOS app that pauses your keyboard with one click — so you can wipe down your keyboard
without typing gibberish, or leave your Mac running without your pets typing into it.

## Modes

**Clean** — lock the keyboard while you clean it.
- Optional auto-unlock timer (30 s / 1 min / 2 min) with a countdown ring on the button.
- Click **Unlock** with the trackpad or mouse when you're done.

**Away** — lock the keyboard while you step away and leave things running.
- Type your **unlock phrase** (default `unlock`) to release it — easy for people, impossible for paws.
- See what happened when you're back: "Paws detected while you were away · 214 keys stopped in 47 min".

## Everywhere

- **Paw detection:** when 4+ letter keys are held at once, or 2+ are held for 3 seconds (a cat walking or
  sitting on the keyboard), Paws Off locks in Away mode on its own. Turn it off in Settings.
- **Global shortcut:** ⌃⌥⌘L locks and unlocks from any app.
- **Menu bar paw:** lock for cleaning, lock while away, or unlock. The app keeps running in the menu bar
  when you close the window.
- **Auto-release:** the keyboard is handed back the moment the screen locks, the screen saver starts,
  the display or Mac sleeps, the user switches, or the Mac shuts down — so you can always type your
  password at the login screen.
- Blocks letters, modifiers and media/brightness/volume keys; the trackpad and mouse always work.

> The Touch ID / power key is handled by macOS itself and can't be blocked. If it's pressed,
> the Mac locks and Paws Off releases the keyboard automatically.

## Requirements

- macOS 14 or later
- Xcode command line tools (`xcode-select --install`)

## Build & run

```sh
./build.sh          # builds "Paws Off.app" in the project root
open "Paws Off.app"
```

On first launch click **Grant Access** and enable Paws Off in
System Settings → Privacy & Security → Accessibility. The app is ad-hoc signed, so macOS may ask
again after a rebuild (remove the old entry and re-add it if the toggle seems stuck).

To install, drag `Paws Off.app` into `/Applications`.

## Releasing a new version

```sh
./build.sh 1.2.0    # writes VERSION, builds; build number = git commit count
```

Log every version in [docs/HISTORY.md](docs/HISTORY.md), commit, and tag it: `git tag v1.2.0`.

Read [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) before changing code: it lists the rules that keep the app safe (there must always be a way to unlock).

## Checking the UI without a screen

```sh
"Paws Off.app/Contents/MacOS/PawsOff" --render-previews /tmp/pawsoff-previews
```

Writes a PNG of every UI state plus the Settings sheet. (Text fields render as a yellow
placeholder box off-screen; that's an ImageRenderer limitation, not a bug.)

## Regenerating the icon

```sh
swift Tools/make-icon.swift /tmp/AppIcon.iconset
iconutil -c icns /tmp/AppIcon.iconset -o Assets/AppIcon.icns
```

## Layout

| Path | What |
| --- | --- |
| `Sources/KeyboardBlocker.swift` | Event tap, lock/unlock, timer, unlock phrase, paw detection, shortcut, auto-release observers, settings, preview states |
| `Sources/ContentView.swift` | Main window |
| `Sources/SettingsView.swift` | Settings sheet (unlock phrase, paw detection, shortcut) |
| `Sources/MenuBarContent.swift` | Menu bar menu |
| `Sources/Theme.swift` | `Palette` colours and shared controls (mode picker, chips, switch, keycap) |
| `Sources/PawsOffApp.swift` | App entry point, window + menu bar scenes, `--render-previews` flag |
| `Sources/PreviewRenderer.swift` | Off-screen PNG renders of each UI state |
| `Tools/make-icon.swift` | Draws the app icon |
| `Assets/AppIcon.icns` | Generated icon (committed) |
| `build.sh` | Compiles with `swiftc` and assembles the `.app` bundle |
