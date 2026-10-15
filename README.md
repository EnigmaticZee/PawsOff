<div align="center">

<img src="docs/images/icon.png" width="128" alt="Paws Off icon">

# Paws Off

**Pause your Mac's keyboard with one click.**<br>
Wipe it down without typing gibberish — or step away without your cat writing your emails.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-5-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0A84FF)
![Version](https://img.shields.io/badge/version-1.2.0-8A63D2)
![No network](https://img.shields.io/badge/network-none-2EA44F)

[Features](#-features) · [Screenshots](#-screenshots) · [Install](#-install) · [How it works](#-how-it-works) · [FAQ](#-faq) · [Development](#-development)

<br>

<img src="docs/images/hero.png" alt="Paws Off in Away, Clean and Paws Detected states" width="100%">

</div>

<br>

## ✨ Features

<table>
<tr>
<td width="50%" valign="top">

### 🧽 Clean mode
For wiping down your keyboard.

- **One-click lock.** Every key is ignored, including modifiers and media keys.
- **Auto-unlock timer:** 30 s, 1 min or 2 min, with a countdown ring.
- **Trackpad stays on**, so you can always click **Unlock**.

</td>
<td width="50%" valign="top">

### 🐾 Away mode
For leaving your Mac running near curious pets.

- **Unlock phrase.** Type `unlock` (or your own word) to release it. Pets can't spell.
- **Welcome-back summary:** *"Paws detected while you were away · 214 keys stopped in 47 min."*
- **Keeps downloads, renders and calls running.** No need to lock the screen.

</td>
</tr>
</table>

### Always ready

| | |
| --- | --- |
| 🐈 **Paw detection** | Locks on its own when a cat walks or sits on the keyboard (4+ keys held at once, or 2+ held for 3 seconds). |
| ⌨️ **Global shortcut** | <kbd>⌃</kbd> <kbd>⌥</kbd> <kbd>⌘</kbd> <kbd>L</kbd> locks and unlocks from any app. |
| 🔝 **Menu bar paw** | Lock for cleaning, lock while away, or unlock, even with the window closed. |
| 🚀 **Launch at login** | So the shortcut and paw detection are always on. |
| 🔓 **Never locks you out** | The keyboard is released the moment your Mac locks, sleeps, starts the screen saver, switches user or shuts down, so you can always type your password. |

<br>

## 📸 Screenshots

<table>
<tr>
<td align="center" width="33%"><img src="docs/images/screen-cleanReady.png" alt="Clean mode, ready"><br><sub><b>Ready to clean</b><br>Pick an optional auto-unlock timer</sub></td>
<td align="center" width="33%"><img src="docs/images/screen-cleanTimer.png" alt="Clean mode, locked with timer"><br><sub><b>Wiping away</b><br>Countdown ring and keys caught</sub></td>
<td align="center" width="33%"><img src="docs/images/screen-awayReady.png" alt="Away mode, ready"><br><sub><b>Stepping away</b><br>Set your unlock phrase</sub></td>
</tr>
<tr>
<td align="center"><img src="docs/images/screen-awayLocked.png" alt="Away mode, locked"><br><sub><b>Paws off</b><br>Type the phrase to unlock</sub></td>
<td align="center"><img src="docs/images/screen-pawsDetected.png" alt="Paws detected"><br><sub><b>Caught a paw</b><br>Locked automatically</sub></td>
<td align="center"><img src="docs/images/screen-backFromAway.png" alt="Summary after returning"><br><sub><b>Welcome back</b><br>What happened while you were gone</sub></td>
</tr>
</table>

<br>

## 📦 Install

Paws Off is built from source in one command. You need **macOS 14 or later** and the Xcode command line tools.

```sh
xcode-select --install          # once, if you don't have the tools yet
git clone <this-repo> PawsOff && cd PawsOff
./build.sh                      # → "Paws Off.app"
open "Paws Off.app"
```

Drag **Paws Off.app** into `/Applications` to keep it.

### First launch

1. Click **Grant Access**.
2. In **System Settings → Privacy & Security → Accessibility**, switch on **Paws Off**.
3. The button changes to **Lock**. That's it.

> [!TIP]
> If the switch is already on but nothing gets locked, click **Already switched on? Reset and ask again** in the app. This clears a grant left behind by an older build.

<br>

## 🎮 Using it

| To… | Do this |
| --- | --- |
| Lock for cleaning | Pick **Clean**, choose a timer (optional), click **Lock** |
| Lock while you step away | Pick **Away**, click **Lock** |
| Lock from anywhere | <kbd>⌃</kbd> <kbd>⌥</kbd> <kbd>⌘</kbd> <kbd>L</kbd>, or the 🐾 in the menu bar |
| Unlock | Click **Unlock**, type your unlock phrase, or press <kbd>⌃</kbd> <kbd>⌥</kbd> <kbd>⌘</kbd> <kbd>L</kbd> again |
| Change the phrase or paw detection | ⚙️ in the top-right corner |

<br>

## 🔍 How it works

```
 keyboard ──▶ Paws Off event tap ──▶ unlocked? ──yes──▶ your apps
                     │                   │
                     │                   no ──▶ swallowed (counted, checked for unlock phrase)
                     │
                     └──▶ watching for ⌃⌥⌘L and paw patterns
```

- A **session event tap** (`CGEventTap`) sees keyboard events before any app does. While unlocked it passes everything straight through. While locked it drops them.
- **Auto-release** listens for screen lock, screen saver, display and system sleep, user switching and shutdown, and unlocks immediately.
- **Paw detection** only looks at *how many keys are held and for how long*, never at what you type. It never fires while the screen is locked.

### 🔒 Privacy & safety

- **No network access.** Paws Off never connects to the internet.
- **Nothing you type is stored or logged.** While locked it keeps only the last few characters, enough to spot your unlock phrase, and discards them on unlock.
- **There is always a way out:** trackpad click, unlock phrase, shortcut, timer, or locking your Mac.

<br>

## ❓ FAQ

<details>
<summary><b>Why does it need Accessibility access?</b></summary>
<br>
macOS only lets apps with Accessibility access intercept keystrokes. Paws Off uses it solely to drop key presses while locked and to notice the shortcut and paw patterns.
</details>

<details>
<summary><b>Can it block the Touch ID / power button?</b></summary>
<br>
No. macOS handles that key itself. If it gets pressed, your Mac locks, and Paws Off releases the keyboard so you can log back in.
</details>

<details>
<summary><b>Paw detection triggered while I was gaming or typing fast.</b></summary>
<br>
Holding four or more letter keys at once looks like a paw. Turn <b>Paw detection</b> off in Settings ⚙️. Clean and Away locks keep working.
</details>

<details>
<summary><b>Does the trackpad get locked too?</b></summary>
<br>
Never. The trackpad and mouse always work, so you can click <b>Unlock</b>.
</details>

<details>
<summary><b>Can I share the app with friends?</b></summary>
<br>
Builds are signed for your own Mac only, so other Macs will block them. Sharing needs a Developer ID–signed, notarized build (see the roadmap).
</details>

<br>

## 🗺️ Roadmap

- [ ] Screen-cleaning mode: a black fullscreen that shows smudges, with trackpad clicks paused
- [ ] Key tester to check every key after cleaning
- [ ] Custom global shortcut
- [ ] Developer ID signing, notarization and a DMG for sharing
- [ ] Lifetime stats: *"1,203 paw presses blocked"*

<br>

## 🛠️ Development

```sh
./build.sh                    # build "Paws Off.app"
./build.sh 1.3.0              # bump VERSION and build
"Paws Off.app/Contents/MacOS/PawsOff" --render-previews /tmp/previews   # PNG of every UI state
Tools/make-readme-art.sh      # refresh the images in this README
```

| Path | What |
| --- | --- |
| `Sources/KeyboardBlocker.swift` | Event tap, lock/unlock, timer, unlock phrase, paw detection, shortcut, auto-release, settings |
| `Sources/ContentView.swift` | Main window |
| `Sources/SettingsView.swift` | Settings sheet |
| `Sources/MenuBarContent.swift` | Menu bar menu |
| `Sources/LaunchAtLogin.swift` | Login item toggle |
| `Sources/Theme.swift` | `Palette` colours and shared controls |
| `Sources/PawsOffApp.swift` | App entry point, window and menu bar scenes |
| `Sources/PreviewRenderer.swift` | Off-screen renders used for checks and README art |
| `Tools/` | Icon and README art generators |
| `docs/DEVELOPMENT.md` | **Rules to read before changing code** |
| `docs/HISTORY.md` | Version history |

**Releasing:** `./build.sh <version>`, add an entry to [docs/HISTORY.md](docs/HISTORY.md), update the version badge above, commit, then `git tag v<version>`.

<br>

---

<div align="center">

Made with 🐾 by **Zaid**

<sub>© Zaid. All rights reserved.</sub>

</div>
