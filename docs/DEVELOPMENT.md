# Development notes

Project: **Paws Off**, a SwiftUI macOS app (window + menu bar) that blocks keyboard input while the
user cleans their keyboard (Clean mode) or steps away from pets (Away mode). No Xcode project; built
with `swiftc` via `build.sh`. Read `README.md` first, then these rules before changing anything.

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
- Colours live in `Palette` (Sources/Theme.swift); `Tools/make-icon.swift` mirrors them. Keep the
  icon subtle (dark base, faint glow, white paw), not a bright multi-colour gradient.
- After ANY UI change: `./build.sh && "Paws Off.app/Contents/MacOS/PawsOff" --render-previews <dir>` and
  look at the PNGs (handy when you can't screenshot the live window). Add a case
  to `KeyboardBlocker.PreviewState` when you add a UI state. TextFields render as yellow boxes off-screen.
- Keep the stable signing requirement in `build.sh` (`designated => identifier "local.pawsoff"`); the
  default ad-hoc requirement is a per-build cdhash, which silently invalidates the Accessibility grant.
  A Developer ID signature (for sharing) replaces this.
- README images come from `Tools/make-readme-art.sh`; rerun it after UI changes and update the version
  badge in README.md on release.
- Bump the version with `./build.sh <version>`, log it in `docs/HISTORY.md`, commit, and tag `vX.Y.Z`.

## Not verified
v1.2.0: UI checked only through off-screen renders. Still to be tested by hand with Accessibility
granted: actual key blocking, unlock phrase, ⌃⌥⌘L shortcut, paw detection on a real keyboard, menu bar
actions, launch at login, timer auto-unlock, and auto-release on lock / sleep / user switch.
