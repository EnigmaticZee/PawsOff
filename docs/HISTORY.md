# Version history

## 1.5.0 — 2026-10-15
- **Mac: light mode.** Appearance setting in Settings with Auto (default, follows the macOS light/dark
  setting and switches live), Light and Dark, matching the Windows app: soft lilac background, white
  selected pills, milky glass on the big button and softer glows.
- **Windows: rounded Nunito font**, bundled inside the app, to match the Mac app's rounded look on every
  PC. Headings are bold.
- `--render-previews` (Mac) now writes every state in both looks (`dark-…png` and `light-…png`).

## 1.4.0 — 2026-10-15
- **Windows: light mode.** Appearance setting with Auto (default, follows the Windows light/dark
  setting and switches live), Light and Dark.
- Windows: redesigned paw icon, sparkles for Clean, a text-cursor icon for the unlock phrase, and drawn
  icons in the summary card (no more text symbols).
- Windows: frosted-glass centre on the big button, Windows 11-style caption buttons (Close turns red on
  hover), semibold headings and more room under the title bar.
- Windows: Settings is now a full page that slides in, with the title and switch on one line so
  descriptions no longer wrap awkwardly.

## 1.3.0 — 2026-10-15
- **Windows app**: same look and features (Clean/Away, timer, unlock phrase, paw detection, tray icon,
  launch at sign-in). Single .exe, no install, no admin rights. Shortcut: Ctrl+Alt+Shift+L.
- **One-click downloads**: GitHub Releases now carry PawsOff-mac.dmg (universal: Apple Silicon + Intel)
  and PawsOff-Windows.exe, built by GitHub Actions.
- README: download buttons and first-launch steps for both platforms.

## 1.2.0 — 2026-10-15
- Fix: Accessibility access no longer goes stale after a rebuild (builds are signed with a stable
  `identifier "local.pawsoff"` requirement instead of the per-build cdhash).
- "Already switched on? Reset and ask again" link on the permission screen clears a stale grant.
- Launch at login toggle in Settings.
- Menu bar icon is a filled paw (circled while locked).

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
