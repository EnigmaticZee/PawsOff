# Development notes

Project: **Paws Off**, a keyboard-blocking app for cleaning (Clean mode) and pets (Away mode), in two
native versions that share one design and one set of rules:
- **Mac** (`Sources/`): SwiftUI, window + menu bar. No Xcode project; built with `swiftc` via `build.sh`.
- **Windows** (`windows/`): WPF on .NET Framework 4.8, window + tray. Built by `dotnet publish` (CI only;
  it can't be built on a Mac). Read `README.md` first, then these rules before changing anything.

## Rules of the road
- Build with `./build.sh`; it must print `Built ...` with no errors. Compile mode is Swift 5 (`-swift-version 5`).
- All keyboard handling lives in `Sources/KeyboardBlocker.swift`. One event tap lives for the app's
  lifetime and passes everything through unless locked; `shouldSwallow` runs on every keystroke, so keep it cheap.
- **There must always be a way to unlock.** The keyboard must never stay locked through a lock, sleep
  or user switch: keep every observer in `watchForLockAndSleep()`; add new ones there, never remove.
  The mouse/trackpad must never be blocked. If a future feature blocks the trackpad (e.g. screen
  cleaning), it must still release via timer, unlock phrase, and the auto-release observers.
- Paw detection must never lock while the screen is locked (`screenIsLocked()`), and it is
  user-toggleable. Its thresholds (4 held keys, or 2 held for 3 s) are untested on real pets; tune with care.
- Never store or log what the user types; the phrase buffer only exists while locked.
- Settings persist via the `didSet`/`save` pattern in KeyboardBlocker; preview instances never persist.
- Colours live in `Palette` (Sources/Theme.swift); `Tools/make-icon.swift` mirrors them. Anything that
  changes with light/dark goes through `Ink` (`@Environment(\.ink)`); never hard-code `.white` outside the
  big button, which sits on the accent gradient in both looks. Keep the
  icon subtle (dark base, faint glow, white paw), not a bright multi-colour gradient.
- After ANY UI change: `./build.sh && "Paws Off.app/Contents/MacOS/PawsOff" --render-previews <dir>` and
  look at the PNGs (light and dark; handy when you can't screenshot the live window). Add a case
  to `KeyboardBlocker.PreviewState` when you add a UI state. TextFields render as yellow boxes off-screen.
- Keep the stable signing requirement in `build.sh` (`designated => identifier "local.pawsoff"`); the
  default ad-hoc requirement is a per-build cdhash, which silently invalidates the Accessibility grant.
  A Developer ID signature (for sharing) replaces this.
- README images come from `Tools/make-readme-art.sh`; rerun it after UI changes and update the version
  badge in README.md on release.
- **Windows:** all keyboard handling lives in `windows/KeyboardBlocker.cs` (one `WH_KEYBOARD_LL` hook).
  The hook callback must stay fast and never touch UI directly (Windows silently removes slow hooks):
  state changes are synchronous, UI updates go through `Notify()` → `Dispatcher.BeginInvoke`.
  Auto-release observers live in `WatchForLockAndSleep()`; same rule as Mac, never remove one.
- Windows UI colours come from `windows/Theme.cs` (light and dark) via DynamicResource keys; never
  hard-code a colour in XAML that should change with the theme. The UI font is Nunito, embedded from `windows/Fonts`
  (static weights cut from the official variable font with fontTools; WPF mis-spaces variable fonts, so
  never ship a variable font). Keep `Fonts/OFL.txt` with it. CI renders every screen in both themes.
- Keep both apps in step: a feature or copy change on one side should land on the other (or be noted in
  HISTORY as platform-specific). Colours mirror `Palette`. Windows preview states are
  `KeyboardBlocker.PreviewStates`; CI renders them as the `windows-previews` artifact — check those PNGs
  after any Windows UI change.
- Installers: `Tools/make-installer-art.swift` draws the DMG background and the Inno Setup wizard bitmaps
  into `Assets/installer` (rerun it after brand changes). The DMG layout lives in `Tools/dmg-settings.py`
  (icon positions must match the arrow in the art). The Windows wizard is `windows/installer/PawsOff.iss`;
  CI screenshots it (`installer-screens` artifact) and tests a silent install and uninstall.
- Releases: bump with `./build.sh <version>` (writes `VERSION`, which both apps read), log it in
  `docs/HISTORY.md`, commit, tag `vX.Y.Z`, push the tag (the README release badge updates by itself). The
  `release` job in `.github/workflows/build.yml` builds and attaches both downloads.
- Bump the version with `./build.sh <version>`, log it in `docs/HISTORY.md`, commit, and tag `vX.Y.Z`.

## Not verified
Windows 1.3.0: compiled and screen renders checked in CI only; never run interactively. Untested:
key blocking, unlock phrase, shortcut, paw detection, tray menu, launch at sign-in, auto-release.

Mac v1.2.0: UI checked only through off-screen renders. Still to be tested by hand with Accessibility
granted: actual key blocking, unlock phrase, ⌃⌥⌘L shortcut, paw detection on a real keyboard, menu bar
actions, launch at login, timer auto-unlock, and auto-release on lock / sleep / user switch.
