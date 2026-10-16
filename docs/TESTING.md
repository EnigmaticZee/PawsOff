# Hand-testing checklist

CI covers building, installing, updating and the off-screen renders. These need a real person at a
real keyboard. Run through them before a launch or a big release, on a Mac **and** a PC. About 15
minutes each. If anything ever gets stuck: click **Unlock**, or lock the computer (Mac: Apple menu →
Lock Screen; Windows: Ctrl+Alt+Delete → Lock), and Paws Off lets go.

## Install (fresh machine or user account if you can)
- [ ] One-line installer (from the website) installs and opens the app, without an "Open Anyway" prompt.
- [ ] Mac: **Grant Access** → Accessibility switch on → the card switches to "Ready to clean?".
- [ ] DMG path: drag to Applications, "Open Anyway", grant access: works too.
- [ ] Windows installer path: SmartScreen "Run anyway", setup, app starts in the tray.

## Clean mode
- [ ] Click **Lock**: letters, numbers, modifiers (⌘/Ctrl, ⌥/Alt, ⇧), arrows, F-keys and media keys (volume, brightness) do nothing.
- [ ] The trackpad/mouse still works; **keys caught** counts up.
- [ ] Click **Unlock**: typing works again immediately.
- [ ] **2 min** timer: locks, counts down, unlocks on its own.
- [ ] **Custom** timer: type `0:30`, lock, unlocks after 30 s; the timer goes back to No timer afterwards.

## Away mode
- [ ] Lock in Away mode, type `unlock`: it unlocks. A wrong word does nothing.
- [ ] Change the unlock word in Settings; the new one works.
- [ ] **Paw detection:** with it unlocked, hold 4+ letter keys at once (or 2 for 3 seconds): it locks and says "Caught a paw".
- [ ] Turn Paw detection off: holding keys no longer locks.

## Never locks you out
- [ ] While locked: lock the screen → log back in with your password (typing works).
- [ ] While locked: close the lid / sleep → wake → typing works.
- [ ] While locked: switch user (if you have a second account) → typing works.

## Menu bar / tray and window
- [ ] Click the paw: the panel drops down under it. Click the paw again: it closes. Click elsewhere: it closes.
- [ ] Open Settings in the panel, close the panel, reopen: it's back on the main screen.
- [ ] Right-click the paw: Lock for Cleaning / Lock While Away / Unlock / Open Window / Check for Updates / Quit all work.
- [ ] Global shortcut (⌃⌥⌘L / Ctrl+Alt+Shift+L) locks and unlocks from another app.
- [ ] Window: opens from the panel's window button; menus (Mac: Paws Off, Edit, Window) open; closing it leaves the app in the menu bar.
- [ ] **Start in → Window**, quit, reopen: the window opens. Back to Menu bar: it starts quietly.
- [ ] Appearance Light / Dark / Auto: the window and the panel both follow.
- [ ] Launch at login / sign-in: restart and it's there.

## Updates
- [ ] Settings shows the right version; **Check** finds nothing new on the latest release.
- [ ] (When a new version is out) it updates by itself and shows "Updated to …".
