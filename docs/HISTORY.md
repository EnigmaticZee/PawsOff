# Version history

## 1.1.1 — 2026-10-15
- "Made by Zaid" credit in Settings and the About window (new About item in the menu bar menu).
- Development notes moved to docs/DEVELOPMENT.md.
- Small cleanups: modern window activation, timers released on quit.

## 1.1.0 — 2026-10-15
- Renamed Spotless → **Paws Off**; new paw print icon.
- Clean / Away modes in one app.
- Clean: optional auto-unlock timer (30 s / 1 min / 2 min) with countdown ring.
- Away: unlock phrase (default `unlock`) releases the keyboard by typing.
- Paw detection: locks automatically when several keys are mashed or held (toggle in Settings).
- Global shortcut ⌃⌥⌘L to lock/unlock from anywhere.
- Menu bar paw with lock/unlock actions; app keeps running when the window is closed.
- Summary card after unlocking (keys stopped, duration, auto-release reason).
- Settings sheet.

## 1.0.0 — 2026-10-15
- First release (as Spotless): one-click keyboard lock using a session event tap (keys, modifiers, media keys).
- Auto-release on screen lock, screen saver, display/system sleep, user switch and shutdown.
- Keys-caught counter, Accessibility permission onboarding.
- Dark glass UI with coral/violet (ready) and teal/blue (locked) accents; subtle app icon.
- `--render-previews <dir>` flag for off-screen UI checks.
