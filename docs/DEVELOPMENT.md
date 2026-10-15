# Development notes

Project: **Paws Off**, a keyboard-blocking app for cleaning (Clean mode) and pets (Away mode), in two
native versions that share one design and one set of rules:
- **Mac** (`Sources/`): SwiftUI views in an AppKit app (menu bar popover + window). No Xcode project;
  built with `swiftc` via `build.sh`.
- **Windows** (`windows/`): WPF on .NET Framework 4.8 (tray pop-up + window). Built by `dotnet publish`
  (CI only; it can't be built on a Mac).

Read `README.md` first, then these rules before changing anything.

## Rules of the road

### Safety (both platforms)
- **There must always be a way to unlock.** The keyboard must never stay locked through a lock, sleep
  or user switch: keep every observer in `watchForLockAndSleep()` (Mac) / `WatchForLockAndSleep()`
  (Windows); add new ones there, never remove. The mouse/trackpad must never be blocked. If a future
  feature blocks the trackpad (e.g. screen cleaning), it must still release via timer, unlock phrase and
  the auto-release observers.
- All keyboard handling lives in `Sources/KeyboardBlocker.swift` / `windows/KeyboardBlocker.cs`. One
  event tap / low-level hook lives for the app's lifetime and passes everything through unless locked.
  It runs on every keystroke, so keep it cheap; on Windows it must never touch UI directly (Windows
  silently removes slow hooks): state changes are synchronous, UI updates go through `Notify()`.
- Paw detection must never lock while the screen is locked, and it is user-toggleable. Its thresholds
  (4 held keys, or 2 held for 3 s) are untested on real pets; tune with care.
- Never store or log what the user types; the phrase buffer only exists while locked. Paw stats are
  counts only, kept locally (UserDefaults / registry); never send them anywhere without a new, explicit opt-in.
- The only network request is the update check (Sparkle on Mac, `windows/Updater.cs`). Keep it that way,
  and keep the switch that turns it off.

### Structure
- The whole UI is one **card** (320 x 430): `Sources/CardView.swift` and `windows/CardView.xaml`.
  Each platform shows the same card in two places: the menu bar popover / tray pop-up, and the window.
  Settings slide in *inside* the card (`SettingsPage.swift`, the `SettingsPage` grid in CardView.xaml),
  at the same size; don't add separate settings windows.
- **Mac:** a plain AppKit app (`LSUIElement`, so it starts without a Dock icon). `MenuBarController`
  (MenuBar.swift) owns the status item: left-click opens the card in an `NSPopover`, right-click shows
  the quick-actions menu. `MainWindow` (WindowSetup.swift) creates the window itself; the card sits
  below the title bar and its background runs up behind the window buttons, so SwiftUI sizes the window
  to card + title bar. The app is in the Dock only while the window is open. `Start in` decides whether
  the window opens at launch (always while Accessibility isn't granted). `AppMenu` provides the menu bar
  menus (Edit is needed for copy/paste in text fields).
- **Windows:** `MainWindow` (slim title row + card) and `TrayPanel` (borderless pop-up above the tray)
  each host a `CardView`; `TrayIcon` toggles the pop-up on left-click. Colours apply app-wide through
  `ThemeManager` (Theme.cs), so both stay in sync.
- Keep both apps in step: a feature or copy change on one side should land on the other (or be noted in
  HISTORY as platform-specific).

### Look
- Colours live in `Palette` (Sources/Theme.swift) and `windows/Theme.cs`; `Tools/make-icon.swift`
  mirrors them. Anything that changes with light/dark goes through `Ink` (Mac) or DynamicResource keys
  (Windows); never hard-code a colour that should change with the theme. Switches use the brand
  coral-to-violet; teal/blue is reserved for the locked state of the big button.
- Windows UI font is Nunito, embedded from `windows/Fonts` (static weights cut from the official
  variable font with fontTools; WPF mis-spaces variable fonts, so never ship a variable font). Keep
  `Fonts/OFL.txt` with it.
- After ANY UI change, render and look at every state in both themes:
  `./build.sh && "Paws Off.app/Contents/MacOS/PawsOff" --render-previews <dir>` (Mac; TextFields render as
  yellow boxes off-screen) and the `windows-previews` CI artifact (Windows). Add a preview state when you
  add a UI state. To check the real Mac window, `--snapshot-window <file.png>` photographs it (title bar
  included; blur effects don't show).

### Build, sign, update, release
- Build with `./build.sh`; it must print `Built ...` with no errors. Compile mode is Swift 5.
- Keep the stable signing requirement in `build.sh` (`designated => identifier "local.pawsoff"`); the
  default ad-hoc requirement is a per-build cdhash, which silently invalidates the Accessibility grant
  and would break Sparkle's update check. A Developer ID signature (for sharing) replaces this.
- **Sparkle** (Mac updates) is vendored in `Vendor/Sparkle` (2.10.0); never edit the framework.
  `build.sh` embeds and signs it. Updates are found via `appcast.xml` on the latest GitHub release and
  must be signed with the EdDSA key: the private key lives in the owner's Keychain (account `pawsoff`)
  and as the `SPARKLE_PRIVATE_KEY` Actions secret; the public key is `SUPublicEDKey` in `build.sh`.
  Never put the private key in the repo. The CI `macos` job signs the DMG and writes the appcast on tags.
- **Windows updates** (`windows/Updater.cs`): checks the GitHub API for the latest release, downloads
  `PawsOff-Windows-Setup.exe` and runs it with `/SILENT`; the installer restarts the app after a silent
  install (CI tests that).
- Installers: `Tools/make-installer-art.swift` draws the DMG background and the Inno Setup wizard bitmaps
  into `Assets/installer`. The DMG layout lives in `Tools/dmg-settings.py`. The Windows wizard is
  `windows/installer/PawsOff.iss`; CI screenshots it and tests a silent install and uninstall.
- README images come from `Tools/make-readme-art.sh` (Mac) and the `windows-previews` artifact (Windows).
- `docs/HISTORY.md` entries are published verbatim as the release notes, so write them for users: what
  changed for them, no build or tooling details.
- **Releasing:** `./build.sh <version>` (writes `VERSION`, which both apps read), log it in
  `docs/HISTORY.md`, commit, tag `vX.Y.Z`, push the tag. The `release` job publishes the DMG, the
  Windows installer and the appcast. Then submit to winget: `Tools/winget-submit.sh <version>`.
  Homebrew needs nothing: the tap (EnigmaticZee/homebrew-tap) always points at the latest release.

## Not verified
Version C (menu bar / tray card, both platforms): checked through off-screen renders, real-window
snapshots (Mac) and CI install tests (Windows) only. Still to be tested by hand: actual key blocking,
unlock phrase, shortcut, paw detection on a real keyboard, menu bar / tray clicks and right-click
menus, Start in, launch at login/sign-in, timer auto-unlock, auto-release on lock / sleep / user
switch, and an end-to-end automatic update on each platform.
