# Development notes

Project: **Paws Off**, a keyboard-blocking app for cleaning (Clean mode) and pets (Away mode), in two
native versions that share one design and one set of rules:
- **Mac** (`Sources/`): SwiftUI views in an AppKit app (menu bar panel + window). No Xcode project;
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
  Each platform shows the same card in two places: the menu bar panel / tray pop-up, and the window.
  Settings slide in *inside* the card (`SettingsPage.swift`, the `SettingsPage` grid in CardView.xaml),
  at the same size; don't add separate settings windows.
- **Mac:** a plain AppKit app (`LSUIElement`, so it starts without a Dock icon). `MenuBarController`
  (MenuBar.swift) owns the status item: left-click drops the card down in a `DropDownPanel` (centred
  under the paw, no arrow, like the system's own menu bar panels), right-click shows the quick-actions
  menu; tips and the "Updated to …" note use the same panel. Switching to a Dock app while frontmost
  leaves dead menus, so `MainWindow.show()` steps back to the Dock for a moment first. `MainWindow` (WindowSetup.swift) creates the window itself; the card sits
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
- **Icon:** drawn in code by `Tools/make-icon.swift` (a coral keycap with a white paw on a white tile; one
  solid colour per surface, no gradients; tiny sizes are a plain coral paw). Never use SF Symbols in the icon or installer art
  (their licence forbids it). `Tools/make-icons.sh` regenerates every copy: `Assets/AppIcon.icns`,
  `windows/Assets/PawsOff.ico` (also the tray icon), `docs/images/icon.png` and the installer art.
- **DMG first-launch guide:** while the app isn't notarized, the DMG window (660 x 520) shows three
  steps for the one-time "Open Anyway" prompt, each with the button to look for. Once notarized,
  build with `NOTARIZED=1 Tools/make-dmg.sh` (set it in the CI `macos` job) for the clean 660 x 400
  window (`dmg-background-notarized`), and drop the "Open Anyway" steps from the README and website.
- Installers: `Tools/make-installer-art.swift` draws the DMG background and the Inno Setup wizard bitmaps
  into `Assets/installer`. The DMG layout lives in `Tools/dmg-settings.py`. The Windows wizard is
  `windows/installer/PawsOff.iss`; CI screenshots it and tests a silent install and uninstall.
- README images come from `Tools/make-readme-art.sh` (Mac) and the `windows-previews` artifact (Windows).
- **Website and one-line installers** live in `site/` and publish to GitHub Pages
  (https://enigmaticzee.github.io/PawsOff/) via `.github/workflows/site.yml`, which copies in the
  README images. `install.sh` / `install.ps1` always fetch the latest release; downloads made with
  curl / Invoke-WebRequest carry no "downloaded from the internet" mark, so they open without the
  Gatekeeper / SmartScreen prompt. `.github/workflows/installers.yml` runs both on clean machines.
  Public copy is for first-time visitors: describe what the app does today.
- Before a launch or big release, hand-test with `docs/TESTING.md`.
- `docs/HISTORY.md` entries are the release notes, everywhere: the GitHub release page and, through
  `Tools/release-notes-html.py`, the Mac update window (carried inside the appcast, so it never loads
  a web page). Check one with `python3 Tools/release-notes-html.py <version>`.
- **Release-notes voice.** Write like a friend who's a little proud of the work:
  - Open with one short line that sets the mood ("New face, same paws.").
  - Each bullet leads with **what changed, in bold**, then one or two sentences on why it's nicer.
  - Be specific. "Bug fixes and improvements" is banned; if it's not worth describing, leave it out.
  - Humour comes from the product: cats, paws, keyboards, the little dramas of a menu bar. Never at
    the user's expense, never at the cost of clarity. One emoji per release at most.
  - Write for users only: no build, CI or tooling details. Mark platform-specific bullets "Mac:" or
    "Windows:".
- **Releasing:** `./build.sh <version>` (writes `VERSION`, which both apps read), log it in
  `docs/HISTORY.md`, commit, tag `vX.Y.Z`, push the tag. The `release` job publishes the DMG, the
  Windows installer and the appcast. Then submit to winget: `Tools/winget-submit.sh <version>`.
  Homebrew needs nothing: the tap (EnigmaticZee/homebrew-tap) always points at the latest release.

## What's verified, and what isn't
- **Automatic:** Mac and Windows builds; Windows install, relaunch and uninstall; the one-line
  installers and the Homebrew cask on clean machines (weekly); and a hands-on Windows test
  (`.github/scripts/windows-hands-on.ps1`) that locks with the button and the shortcut, proves typing
  is blocked, unlocks with a click, the shortcut and the unlock word, and checks CPU, memory and
  the event log.
- **Verified by hand (Mac, 2.0.x):** automatic updates end to end, the menu bar panel, window menus,
  Appearance sync.
- **Still needs hands:** everything in `docs/TESTING.md` on a real Mac and PC, especially paw
  detection (the Windows test types with simulated keys, which paw detection ignores on purpose)
  and auto-release on lock, sleep and user switch.
