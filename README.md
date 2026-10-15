<div align="center">

<img src="docs/images/icon.png" width="128" alt="Paws Off icon">

# Paws Off

**Pause your keyboard with one click.**<br>
Wipe it down without typing gibberish — or step away without your cat writing your emails.

<a href="https://github.com/EnigmaticZee/PawsOff/releases/latest/download/PawsOff-mac.dmg"><img src="https://img.shields.io/badge/Download_for_Mac-111?style=for-the-badge&logo=apple&logoColor=white" alt="Download for Mac" height="44"></a>
&nbsp;
<a href="https://github.com/EnigmaticZee/PawsOff/releases/latest/download/PawsOff-Windows-Setup.exe"><img src="https://img.shields.io/badge/Download_for_Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white" alt="Download for Windows" height="44"></a>

<sub>Free · macOS 14+ (Apple Silicon & Intel) · Windows 10 & 11 · or <code>brew install --cask enigmaticzee/tap/paws-off</code></sub>

<br>

[![Latest release](https://img.shields.io/github/v/release/EnigmaticZee/PawsOff?color=8A63D2&label=release)](https://github.com/EnigmaticZee/PawsOff/releases)
![Network: update checks only](https://img.shields.io/badge/network-update_checks_only-2EA44F)
[![License: MIT](https://img.shields.io/badge/license-MIT-F2C14E)](LICENSE)

[Features](#-features) · [Install](#-install) · [How it works](#-how-it-works) · [FAQ](#-faq) · [Development](#%EF%B8%8F-development)

<br>

<img src="docs/images/hero.png" alt="Paws Off in the menu bar, locked with a timer, and after catching a paw" width="100%">

</div>

<br>

## ✨ Features

<table>
<tr>
<td width="50%" valign="top">

### 🧽 Clean mode
For wiping down your keyboard.

- **One click** and every key is ignored, including modifiers and media keys.
- **Auto-unlock timer:** 2 min, or any length you type in (from 2:01), with a countdown ring.
- **Your trackpad and mouse keep working**, so you can always click **Unlock**.

</td>
<td width="50%" valign="top">

### 🐾 Away mode
For leaving your computer running near curious pets.

- **Unlock phrase:** type `unlock` (or your own word) to release it. Pets can't spell.
- **Paw detection** locks on its own when a cat walks or sits on the keyboard.
- Downloads, renders and calls **keep running**. No need to lock the screen.

</td>
</tr>
</table>

| | |
| --- | --- |
| 🐾 **Lives in your menu bar / tray** | Click the paw for the panel; right-click for quick actions (lock for cleaning, lock while away, unlock, quit). Prefer a window? Choose **Start in → Window** in Settings. |
| ⌨️ **Global shortcut** | Lock or unlock from any app: <kbd>⌃</kbd><kbd>⌥</kbd><kbd>⌘</kbd><kbd>L</kbd> on Mac, <kbd>Ctrl</kbd><kbd>Alt</kbd><kbd>Shift</kbd><kbd>L</kbd> on Windows. |
| 📊 **Your paw stats** | Lifetime totals, kept only on your computer, shown as rotating one-liners like *"≈ 486 words by paws, never sent"*. |
| 🔓 **Never locks you out** | The keyboard is released the moment your computer locks, sleeps, switches user or shuts down, so you can always type your password. |
| 🌗 **Light and dark** | Follows your system (Auto), or pick Light or Dark in ⚙️ Settings. |
| 🔄 **Stays up to date** | Checks for new versions about once a day and installs them for you. Turn it off in Settings. |

<details>
<summary><b>📸 More screenshots</b></summary>
<br>

<table>
<tr>
<td align="center" width="33%"><img src="docs/images/screen-cleanReady.png" alt="Clean mode, ready"><br><sub><b>Ready to clean</b></sub></td>
<td align="center" width="33%"><img src="docs/images/screen-cleanCustom.png" alt="Custom timer"><br><sub><b>Custom timer</b></sub></td>
<td align="center" width="33%"><img src="docs/images/screen-awayLocked.png" alt="Away mode, locked"><br><sub><b>Paws off</b></sub></td>
</tr>
<tr>
<td align="center"><img src="docs/images/screen-pawsDetected.png" alt="Paws detected"><br><sub><b>Caught a paw</b></sub></td>
<td align="center"><img src="docs/images/screen-menu-bar-panel.png" alt="Menu bar panel with paw stats"><br><sub><b>Menu bar panel</b></sub></td>
<td align="center"><img src="docs/images/screen-settings.png" alt="Settings inside the card"><br><sub><b>Settings</b></sub></td>
</tr>
</table>

<img src="docs/images/windows.png" alt="Paws Off on Windows: the window and the tray pop-up" width="100%">
<p align="center"><sub><b>On Windows</b>: the window and the tray pop-up</sub></p>

</details>

<br>

## 📦 Install

Paws Off isn't signed with a paid Apple or Microsoft developer certificate yet, so both systems ask you to confirm the first time you open it. It's open source: you can read every line, or [build it yourself](#%EF%B8%8F-development).

### 🍎 Mac

1. **[Download PawsOff-mac.dmg](https://github.com/EnigmaticZee/PawsOff/releases/latest/download/PawsOff-mac.dmg)**, open it, and drag **Paws Off** into **Applications**. (Or: `brew install --cask enigmaticzee/tap/paws-off`.)
2. **Open it once.** Double-click **Paws Off** in Applications. macOS says *"Paws Off" Not Opened*. Click **Done**.
3. **Allow it.** Open **System Settings → Privacy & Security**, scroll down to **Security**, and next to *"Paws Off" was blocked* click **Open Anyway**. Enter your password, then click **Open Anyway** again.
4. **Give it keyboard access.** In Paws Off, click **Grant Access**, then switch on **Paws Off** in **System Settings → Privacy & Security → Accessibility**.

From then on Paws Off starts in your menu bar: look for the 🐾 at the top of your screen.

<details>
<summary>Prefer Terminal? Skip steps 2–3 with one command</summary>
<br>

This removes the "downloaded from the internet" flag that macOS checks, for this app only:

```sh
xattr -dr com.apple.quarantine "/Applications/Paws Off.app"
```

</details>

<details>
<summary>The Accessibility switch is on, but nothing gets locked</summary>
<br>

Open the Paws Off window and click **Already switched on? Reset and ask again**. This clears an old permission, for example one left by an earlier version, and asks again.

</details>

### 🪟 Windows

1. **[Download PawsOff-Windows-Setup.exe](https://github.com/EnigmaticZee/PawsOff/releases/latest/download/PawsOff-Windows-Setup.exe)** and open it. If SmartScreen says *"Windows protected your PC"*, click **More info → Run anyway**.
2. Click through the short setup. It installs just for you (no admin rights) and can add a desktop shortcut or start Paws Off when you sign in.
3. Paws Off lives in the system tray, by the clock: click the 🐾 for the panel. Uninstall any time from **Settings → Apps**.

<br>

## 🔍 How it works

```
 keyboard ──▶ Paws Off keyboard hook ──▶ unlocked? ──yes──▶ your apps
                      │                     │
                      │                     no ──▶ swallowed (counted, checked for unlock phrase)
                      │
                      └──▶ watching for the shortcut and paw patterns
```

- **Mac:** a session event tap (`CGEventTap`). **Windows:** a low-level keyboard hook (`WH_KEYBOARD_LL`). Both see key presses before any app does: passed straight through while unlocked, dropped while locked.
- **Paw detection** only looks at *how many keys are held and for how long*, never at what you type, and never fires while the screen is locked.
- **Nothing you type is stored or sent.** While locked it keeps only the last few characters, enough to spot your unlock phrase, and discards them on unlock. Paw stats are counts only, kept on your computer.
- **The only network request is the update check:** about once a day it asks GitHub whether there's a newer release. Turn it off in Settings.

<br>

## ❓ FAQ

<details>
<summary><b>Where did the window go?</b></summary>
<br>
Paws Off starts in your menu bar (Mac) or system tray (Windows). Click the 🐾 for the panel, or the window button in its bottom bar to open the window. To have the window open every time, choose <b>Start in → Window</b> in ⚙️ Settings.
</details>

<details>
<summary><b>Why does the Mac version need Accessibility access?</b></summary>
<br>
macOS only lets apps with Accessibility access intercept keystrokes. Paws Off uses it only to drop key presses while locked and to notice the shortcut and paw patterns. Windows needs no permission.
</details>

<details>
<summary><b>Can it block the Touch ID / power button, or Ctrl+Alt+Delete?</b></summary>
<br>
No. The system handles those keys itself. If one is pressed, your computer locks and Paws Off releases the keyboard.
</details>

<details>
<summary><b>Paw detection triggered while I was gaming or typing fast.</b></summary>
<br>
Holding four or more letter keys at once looks like a paw. Turn <b>Paw detection</b> off in ⚙️ Settings. Locking by hand keeps working.
</details>

<details>
<summary><b>On Windows, some keys still reach an app running as administrator.</b></summary>
<br>
Windows doesn't let normal apps block input to apps running with admin rights. Everything else is blocked as usual.
</details>

<br>

## 🗺️ Roadmap

- [ ] Screen-cleaning mode: a black fullscreen that shows smudges, with trackpad clicks paused
- [ ] Key tester to check every key after cleaning
- [ ] Custom global shortcut
- [ ] Signed and notarized builds, so there's no first-launch prompt
- [ ] `winget install EnigmaticZee.PawsOff`

<br>

## 🛠️ Development

```sh
git clone https://github.com/EnigmaticZee/PawsOff.git && cd PawsOff

# Mac (needs the Xcode command line tools: xcode-select --install)
./build.sh && open "Paws Off.app"   # build and run
Tools/make-dmg.sh                    # universal app + dist/PawsOff-mac.dmg (needs: pip install dmgbuild)
Tools/make-readme-art.sh             # refresh the images in this README

# Windows (needs the .NET SDK, run on Windows)
dotnet publish windows/PawsOff.csproj -c Release -o out
```

| Path | What |
| --- | --- |
| `Sources/` | Mac app (SwiftUI + AppKit). `KeyboardBlocker.swift` holds the event tap and all lock logic; `CardView.swift` is the UI shown in the window and the menu bar popover. |
| `windows/` | Windows app (WPF, .NET Framework 4.8). `KeyboardBlocker.cs` holds the hook; `CardView.xaml` is the UI shown in the window and the tray pop-up. |
| `Vendor/Sparkle/` | [Sparkle](https://sparkle-project.org) 2.10.0, the Mac updater (MIT). |
| `.github/workflows/build.yml` | Builds both apps on every push; publishes a Release (with the Sparkle appcast) when a `v*` tag is pushed. |
| `packaging/winget/`, `Tools/winget-submit.sh` | winget manifests and the script that submits a release. Homebrew: [EnigmaticZee/homebrew-tap](https://github.com/EnigmaticZee/homebrew-tap). |
| `Tools/` | Icon, installer art, DMG and README art generators. |
| [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) | **Rules to read before changing code.** |
| [`docs/HISTORY.md`](docs/HISTORY.md) | Version history. |

**Releasing:** `./build.sh <version>`, add the version to `docs/HISTORY.md`, commit, then `git tag v<version> && git push --follow-tags`. GitHub Actions builds both apps, signs the Mac update and publishes the downloads. Then run `Tools/winget-submit.sh <version>`.

**Contributing:** issues and pull requests are welcome. The one rule that matters most: **there must always be a way to unlock.**

<br>

---

<div align="center">

Made with 🐾 by **Zaid** · [MIT License](LICENSE)<br>
<sub>Windows app font: [Nunito](https://github.com/googlefonts/nunito) by the Nunito Project Authors, [SIL Open Font License](windows/Fonts/OFL.txt) · Updates by [Sparkle](https://sparkle-project.org)</sub>

</div>
