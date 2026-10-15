<div align="center">

<img src="docs/images/icon.png" width="128" alt="Paws Off icon">

# Paws Off

**Pause your keyboard with one click.**<br>
Wipe it down without typing gibberish — or step away without your cat writing your emails.

<a href="https://github.com/EnigmaticZee/PawsOff/releases/latest/download/PawsOff-mac.dmg"><img src="https://img.shields.io/badge/Download_for_Mac-111?style=for-the-badge&logo=apple&logoColor=white" alt="Download for Mac" height="44"></a>
&nbsp;
<a href="https://github.com/EnigmaticZee/PawsOff/releases/latest/download/PawsOff-Windows.exe"><img src="https://img.shields.io/badge/Download_for_Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white" alt="Download for Windows" height="44"></a>

<sub>Free · macOS 14+ (Apple Silicon & Intel) · Windows 10 & 11 · <a href="https://github.com/EnigmaticZee/PawsOff/releases">All releases</a></sub>

<br>

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111?logo=apple&logoColor=white)
![Windows 10/11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows&logoColor=white)
![Version](https://img.shields.io/badge/version-1.3.0-8A63D2)
![No network](https://img.shields.io/badge/network-none-2EA44F)
![License: MIT](https://img.shields.io/badge/license-MIT-F2C14E)

[Features](#-features) · [Screenshots](#-screenshots) · [Install](#-install) · [How it works](#-how-it-works) · [FAQ](#-faq) · [Development](#-development) · [License](#-license)

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
- **Trackpad and mouse stay on**, so you can always click **Unlock**.

</td>
<td width="50%" valign="top">

### 🐾 Away mode
For leaving your computer running near curious pets.

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
| ⌨️ **Global shortcut** | Mac: <kbd>⌃</kbd> <kbd>⌥</kbd> <kbd>⌘</kbd> <kbd>L</kbd> · Windows: <kbd>Ctrl</kbd> <kbd>Alt</kbd> <kbd>Shift</kbd> <kbd>L</kbd>. Locks and unlocks from any app. |
| 🐾 **Menu bar / tray paw** | Lock for cleaning, lock while away, or unlock, even with the window closed. |
| 🚀 **Launch at login** | So the shortcut and paw detection are always on. |
| 🔓 **Never locks you out** | The keyboard is released the moment your computer locks, sleeps, switches user or shuts down, so you can always type your password. |

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

### 🍎 Mac

1. **[Download PawsOff-mac.dmg](https://github.com/EnigmaticZee/PawsOff/releases/latest/download/PawsOff-mac.dmg)**, open it, and drag **Paws Off** into **Applications**.
2. Open Paws Off. The first time, macOS says it can't verify the developer, because the app isn't notarized by Apple yet. Click **Done**, then go to **System Settings → Privacy & Security**, scroll down, and click **Open Anyway**.
3. Click **Grant Access**, and switch on **Paws Off** in **System Settings → Privacy & Security → Accessibility**. The button changes to **Lock**. That's it.

> [!TIP]
> If the Accessibility switch is already on but nothing gets locked, click **Already switched on? Reset and ask again** in the app.

### 🪟 Windows

1. **[Download PawsOff-Windows.exe](https://github.com/EnigmaticZee/PawsOff/releases/latest/download/PawsOff-Windows.exe)** and open it. There's nothing to install, and it doesn't need admin rights.
2. The first time, Windows SmartScreen may say *"Windows protected your PC"*, because the app isn't code-signed yet. Click **More info → Run anyway**.
3. Paws Off appears with a paw in the system tray. Closing the window keeps it running there.

> [!NOTE]
> Move the `.exe` somewhere permanent (for example `Documents\PawsOff`) before turning on **Launch at sign-in**, so Windows can find it later.

### 🛠️ Build it yourself

```sh
# Mac (needs the Xcode command line tools: xcode-select --install)
git clone https://github.com/EnigmaticZee/PawsOff.git && cd PawsOff
./build.sh && open "Paws Off.app"
```

```powershell
# Windows (needs the .NET SDK)
git clone https://github.com/EnigmaticZee/PawsOff.git; cd PawsOff
dotnet publish windows/PawsOff.csproj -c Release -o out; .\out\PawsOff.exe
```

<br>

## 🎮 Using it

| To… | Do this |
| --- | --- |
| Lock for cleaning | Pick **Clean**, choose a timer (optional), click **Lock** |
| Lock while you step away | Pick **Away**, click **Lock** |
| Lock from anywhere | The shortcut (Mac <kbd>⌃</kbd><kbd>⌥</kbd><kbd>⌘</kbd><kbd>L</kbd>, Windows <kbd>Ctrl</kbd><kbd>Alt</kbd><kbd>Shift</kbd><kbd>L</kbd>), or the 🐾 in the menu bar / tray |
| Unlock | Click **Unlock**, type your unlock phrase, or press the shortcut again |
| Change the phrase, paw detection or launch at login | ⚙️ in the top-right corner |

<br>

## 🔍 How it works

```
 keyboard ──▶ Paws Off keyboard hook ──▶ unlocked? ──yes──▶ your apps
                      │                     │
                      │                     no ──▶ swallowed (counted, checked for unlock phrase)
                      │
                      └──▶ watching for the shortcut and paw patterns
```

- **Mac:** a session event tap (`CGEventTap`). **Windows:** a low-level keyboard hook (`WH_KEYBOARD_LL`). Both see key presses before any app does. While unlocked they pass everything straight through; while locked they drop them.
- **Auto-release** listens for screen lock, sleep, user switching and shutdown (plus screen saver and display sleep on Mac), and unlocks immediately.
- **Paw detection** only looks at *how many keys are held and for how long*, never at what you type. It never fires while the screen is locked.

### 🔒 Privacy & safety

- **No network access.** Paws Off never connects to the internet.
- **Nothing you type is stored or logged.** While locked it keeps only the last few characters, enough to spot your unlock phrase, and discards them on unlock.
- **There is always a way out:** mouse or trackpad click, unlock phrase, shortcut, timer, or locking your computer.

<br>

## ❓ FAQ

<details>
<summary><b>Why does the Mac version need Accessibility access?</b></summary>
<br>
macOS only lets apps with Accessibility access intercept keystrokes. Paws Off uses it solely to drop key presses while locked and to notice the shortcut and paw patterns. Windows needs no permission.
</details>

<details>
<summary><b>Why do macOS and Windows warn me the first time?</b></summary>
<br>
Apple and Microsoft show a one-time warning for apps that aren't signed with a paid developer certificate. Paws Off is open source, so you can read every line or build it yourself. Signed builds are on the roadmap.
</details>

<details>
<summary><b>Can it block the Touch ID / power button, or Ctrl+Alt+Delete?</b></summary>
<br>
No. The system handles those itself. If one gets pressed, your computer locks, and Paws Off releases the keyboard so you can log back in.
</details>

<details>
<summary><b>Paw detection triggered while I was gaming or typing fast.</b></summary>
<br>
Holding four or more letter keys at once looks like a paw. Turn <b>Paw detection</b> off in Settings ⚙️. Clean and Away locks keep working.
</details>

<details>
<summary><b>Does the trackpad or mouse get locked too?</b></summary>
<br>
Never. The trackpad and mouse always work, so you can click <b>Unlock</b>.
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
- [ ] Signed and notarized builds, so there's no first-launch warning
- [ ] Lifetime stats: *"1,203 paw presses blocked"*

<br>

## 🛠️ Development

```sh
./build.sh                    # Mac: build "Paws Off.app"
Tools/make-dmg.sh             # Mac: universal app + dist/PawsOff-mac.dmg
"Paws Off.app/Contents/MacOS/PawsOff" --render-previews /tmp/previews   # PNG of every UI state
Tools/make-readme-art.sh      # refresh the images in this README
```

GitHub Actions builds both apps on every push and renders the Windows screens (the `windows-previews` artifact). Pushing a tag like `v1.4.0` publishes a Release with both downloads.

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
| `windows/` | The Windows app (WPF, .NET Framework 4.8): same structure, `KeyboardBlocker.cs` holds the hook |
| `.github/workflows/build.yml` | Builds both apps; publishes Releases on tags |
| `Tools/` | Icon, Windows icon, DMG and README art generators |
| `docs/DEVELOPMENT.md` | **Rules to read before changing code** |
| `docs/HISTORY.md` | Version history |

**Releasing:** `./build.sh <version>`, add an entry to [docs/HISTORY.md](docs/HISTORY.md), update the version badge above, commit, then `git tag v<version> && git push --tags`. CI does the rest.

## 🤝 Contributing

Issues and pull requests are welcome. Please read [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) first. The one rule that matters most: **there must always be a way to unlock.**

## 📄 License

[MIT](LICENSE) © 2026 Zaid

<br>

---

<div align="center">

Made with 🐾 by **Zaid**

</div>
