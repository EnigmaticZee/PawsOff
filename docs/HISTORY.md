# Version history

## 2.0.6 — 2026-10-15
A quiet one. Nothing to see here, and that's the point.

- **Behind-the-scenes tidy-up.** No new buttons, no moved menus, nothing to relearn. This update
  mostly exists to prove updates arrive on their own, and since you're reading this, they do. 🐾

## 2.0.5 — 2026-10-15
Release notes got a glow-up. You're looking at it.

- **Notes, right in the update window.** This box used to load an entire GitHub page, sign-in button
  and all, then leave you to scroll for the good bit. Now it shows just what changed, in light or dark
  to match your Mac.
- **Written by humans, for humans.** No "bug fixes and performance improvements" here, ever. If
  something changed, we'll tell you what, and probably make a cat joke about it.

## 2.0.4 — 2026-10-15
Two small fixes, both found the best way: by actually clicking things.

- **Click the paw to open. Click it again to close.** Revolutionary, we know. Before, the second
  click closed the panel and reopened it in the same breath, like a cat that can't decide which
  side of the door it wants.
- **The panel always opens on the main screen.** Left it in Settings? It used to wait there for you.
  Now it tidies up behind itself.

## 2.0.3 — 2026-10-15
New face, same paws.

- **A new app icon:** one coral key, one white paw, on a clean white tile. No gradients were harmed
  in the making of it (they were all let go).
- **Mac: the panel drops straight down from the paw**, just like the system's own menu bar panels.
  The little pointy arrow has retired with full honours.
- **Mac: notes show up where you'd look.** "Updated to…" and the first-time tip now open right
  under the paw, instead of wherever they fancied.

## 2.0.2 — 2026-10-15
Paws Off now tells you when it has updated itself. Quietly, and only once.

- **A small "Updated to…" note** appears under the menu bar paw (Mac) or by the tray icon (Windows)
  after an update, with a link to what's new. If you're reading this, it probably worked. Hi. 👋

## 2.0.1 — 2026-10-15
Updates now take care of themselves.

- **Updates install on their own.** Paws Off checks shortly after it starts and about once a day,
  downloads quietly, installs, and is back in a blink. Never while your keyboard is locked. Rather do
  it yourself? Turn it off in **Settings → Updates**.
- **Mac: the menus at the top of the screen work again** when you open the window from the menu bar.
  Before, they were purely decorative.
- **Mac: the menu bar panel follows your Appearance choice.** Pick Light and it stays light, instead
  of copying the menu bar's mood.

## 2.0.0 — 2026-10-15
Paws Off moved into your menu bar. It's cosier up there.

- **It lives in your menu bar (Mac) and system tray (Windows).** Click the paw for a compact panel
  with everything in it. Right-click for the speedy stuff: lock for cleaning, lock while away,
  unlock, open the window, quit.
- **A smaller window**, if you like windows. It's the same compact card. Choose **Start in → Menu bar
  / Tray** (the default) or **Window** in Settings.
- **Settings open inside the card**, at the same size, one tidy row each. No more settings bigger than
  the app they're setting.
- **Automatic updates** on both platforms, so you'll never miss a paw-sitive change.
- **Windows caught up:** paw stats (rotating one-liners, kept on your PC) and the custom timer (No
  timer, 2 min, or any length from 2:01), just like the Mac.
- **Install with Homebrew** on Mac: `brew install --cask enigmaticzee/tap/paws-off`.
- **A one-time tip** shows where Paws Off is hiding the first time it starts in the menu bar or tray.
- **A new app icon:** a white key with a paw on a coral-to-violet tile. (It has since had a makeover;
  see 2.0.3.)

## 1.6.0 — 2026-10-15
- **Mac: your paw stats.** Paws Off keeps lifetime totals on your Mac (never sent anywhere) and shows
  them as rotating one-liners, like "≈ 486 words typed by paws, never sent". Reset them in Settings.
- Mac: tidier top of the window. The settings button sits in a native toolbar slot, level with and
  sized to the window buttons, and the empty band above the Clean/Away switch is gone. Spacing follows
  one even rhythm from the timer row down.
- Mac: auto-unlock timer is now No timer, 2 min or **Custom**: set any length from 2:01 right in the row
  (type "5" or "3:30", or use − / +). Clicking elsewhere cancels it, and a custom length is a one-off:
  the timer goes back to No timer after that lock.
- Mac: switches use the app's own pink-to-violet colours.
- Mac: closing the window removes Paws Off from the Dock; it keeps running in the menu bar and comes
  back to the Dock when you open the window again.
- The Windows app is unchanged in this release.

## 1.5.0 — 2026-10-15
- **Mac: light mode.** Appearance setting in Settings with Auto (default, follows the macOS light/dark
  setting and switches live), Light and Dark, matching the Windows app: soft lilac background, white
  selected pills, milky glass on the big button and softer glows.
- **Windows: rounded Nunito font**, bundled inside the app, to match the Mac app's rounded look on every
  PC. Headings are bold.
- **Beautiful Mac installer:** the DMG opens to a branded window with a drag-to-Applications arrow, the
  paw as the disk icon and a first-launch tip.
- **Windows installer:** a proper Setup wizard (PawsOff-Windows-Setup.exe) with Paws Off artwork. Installs
  per user without admin rights, adds a Start menu entry, can add a desktop shortcut and start at sign-in,
  closes a running copy before upgrading, and uninstalls cleanly from Settings → Apps. The portable .exe is
  still available.
- Release notes now include file sizes, install steps and SHA-256 checksums.
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
