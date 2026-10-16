# Security

Paws Off can see key presses, because that's how it blocks them. That deserves a clear explanation
and an easy way to report problems.

## What Paws Off does with your keys

- **Nothing is stored or sent.** While the keyboard is locked, Paws Off keeps only the last few
  characters in memory, just enough to recognise your unlock word, and clears them on unlock. When
  it's unlocked, key presses pass straight through and aren't looked at, except to notice the
  global shortcut and paw patterns.
- **Paw detection counts keys, it doesn't read them:** it only looks at how many keys are held,
  and for how long.
- **Paw stats are counts only** (keys stopped, sessions), kept on your computer.
- **The only network request is the update check** to GitHub's releases. Turn it off in Settings.
- **Updates are signed.** Mac updates are only installed if they carry the project's EdDSA
  signature.
- **It never locks you out:** the keyboard is released whenever the computer locks, sleeps,
  switches user or shuts down.

All of this lives in `Sources/KeyboardBlocker.swift` (Mac) and `windows/KeyboardBlocker.cs`
(Windows) if you'd like to check.

## Reporting a vulnerability

Please **don't open a public issue.** Report it privately through
[GitHub's private vulnerability reporting](https://github.com/EnigmaticZee/PawsOff/security/advisories/new).
You'll get a reply within a few days, and a fix will ship as a normal update (which reaches
everyone automatically).

## Supported versions

Only the latest release. Paws Off updates itself, so that's what almost everyone runs.
