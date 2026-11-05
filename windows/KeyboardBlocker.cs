using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;
using System.Windows.Threading;
using Microsoft.Win32;

namespace PawsOff
{
    public enum LockMode { Clean, Away }

    /// What happened during the last lock, shown after the keyboard is released.
    public sealed class LockSummary
    {
        public LockMode Mode;
        public TimeSpan Duration;
        public int Keys;
        public bool PawTriggered;
        public string Reason; // set when released automatically (PC locked, sleep, ...)
        public DateTime EndedAt = DateTime.Now;
    }

    [Flags]
    public enum ShortcutModifiers { None = 0, Ctrl = 1, Alt = 2, Shift = 4, Win = 8 }

    /// The key combination that locks and unlocks from any app. Default Ctrl+Alt+L.
    public sealed class Shortcut
    {
        public static readonly Shortcut Standard = new Shortcut('L', ShortcutModifiers.Ctrl | ShortcutModifiers.Alt);

        public int Key { get; }
        public ShortcutModifiers Modifiers { get; }

        public Shortcut(int key, ShortcutModifiers modifiers)
        {
            Key = key;
            Modifiers = modifiers;
        }

        public bool IsStandard => Key == Standard.Key && Modifiers == Standard.Modifiers;

        /// "Ctrl+Alt+L", with the key named for the current keyboard layout.
        public string Label
        {
            get
            {
                var parts = new List<string>();
                if (Modifiers.HasFlag(ShortcutModifiers.Ctrl)) parts.Add("Ctrl");
                if (Modifiers.HasFlag(ShortcutModifiers.Alt)) parts.Add("Alt");
                if (Modifiers.HasFlag(ShortcutModifiers.Shift)) parts.Add("Shift");
                parts.Add(KeyName(Key));
                return string.Join("+", parts);
            }
        }

        static string KeyName(int vk)
        {
            if (vk >= 0x70 && vk <= 0x87) return "F" + (vk - 0x6F);
            if (vk >= 0x60 && vk <= 0x69) return "Num" + (vk - 0x60);
            switch (vk)
            {
                case 0x08: return "Backspace";
                case 0x09: return "Tab";
                case 0x0D: return "Enter";
                case 0x20: return "Space";
                case 0x21: return "PgUp";
                case 0x22: return "PgDn";
                case 0x23: return "End";
                case 0x24: return "Home";
                case 0x25: return "Left";
                case 0x26: return "Up";
                case 0x27: return "Right";
                case 0x28: return "Down";
                case 0x2D: return "Ins";
                case 0x2E: return "Del";
            }
            uint ch = MapVirtualKey((uint)vk, MAPVK_VK_TO_CHAR) & 0x7FFF; // the top bit marks dead keys
            return ch != 0 ? char.ToUpperInvariant((char)ch).ToString() : $"Key {vk}";
        }

        const uint MAPVK_VK_TO_CHAR = 2;

        [DllImport("user32.dll")]
        static extern uint MapVirtualKey(uint uCode, uint uMapType);
    }

    /// While the Settings shortcut field is listening for a new combination.
    public enum ShortcutRecording { Off, Listening, NeedsModifier }

    /// Owns one low-level keyboard hook for the app's lifetime. While unlocked it passes every
    /// key through (watching only for the global shortcut and paw patterns); while locked it
    /// swallows every key. Locking the PC, sleeping or signing out releases the keyboard.
    public sealed class KeyboardBlocker : IDisposable
    {
        /// Custom lengths start just above the 2 min preset and go up to 99:59.
        public const int CustomMin = 121, CustomMax = 5999;

        public event Action Changed;
        public event Action PawsDetected;

        public Settings Settings { get; }
        public bool IsActive { get; private set; }
        public LockMode ActiveMode { get; private set; }
        public int KeysCaught { get; private set; }
        public bool PawTriggered { get; private set; }
        public DateTime? LockedAt { get; private set; }
        public DateTime? EndsAt { get; private set; }
        public LockSummary LastSummary { get; private set; }
        /// A custom length is a one-off choice: not saved as the selection, and back to No timer
        /// once that lock ends.
        public bool TimerIsCustom { get; private set; }
        public PawStats Stats { get; private set; }
        public ShortcutRecording Recording { get; private set; }

        readonly Dispatcher dispatcher;
        readonly LowLevelKeyboardProc hookProc; // kept in a field so the GC can't collect it
        IntPtr hook = IntPtr.Zero;
        DispatcherTimer unlockTimer;
        DispatcherTimer recordingTimer;
        string typed = "";
        readonly HashSet<int> pressed = new HashSet<int>();
        readonly Dictionary<int, DateTime> heldKeys = new Dictionary<int, DateTime>();

        /// Pass a dispatcher to install the hook; null makes an inert instance for previews.
        public KeyboardBlocker(Settings settings, Dispatcher dispatcher)
        {
            Settings = settings;
            this.dispatcher = dispatcher;
            Stats = settings.LoadStats();
            if (dispatcher == null) return;

            hookProc = HookCallback;
            using (var process = Process.GetCurrentProcess())
            using (var module = process.MainModule)
                hook = SetWindowsHookEx(WH_KEYBOARD_LL, hookProc, GetModuleHandle(module.ModuleName), 0);
            if (hook == IntPtr.Zero)
                throw new Win32Exception(Marshal.GetLastWin32Error(), "Could not install the keyboard hook.");

            WatchForLockAndSleep();
        }

        // MARK: Lock / unlock

        public void Toggle()
        {
            if (IsActive) Stop(); else Start();
        }

        public void Start(LockMode? requested = null, bool byPaws = false)
        {
            if (IsActive) return;
            StopRecordingShortcut();
            ActiveMode = requested ?? Settings.Mode;
            PawTriggered = byPaws;
            KeysCaught = byPaws ? heldKeys.Count : 0;
            typed = "";
            heldKeys.Clear();
            LastSummary = null;
            var now = DateTime.Now;
            LockedAt = now;

            int timer = EffectiveTimerSeconds;
            if (ActiveMode == LockMode.Clean && timer > 0)
            {
                EndsAt = now.AddSeconds(timer);
                unlockTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(timer) };
                unlockTimer.Tick += (s, e) => Stop();
                unlockTimer.Start();
            }
            else
            {
                EndsAt = null;
            }
            IsActive = true;
            Notify();
            if (byPaws) dispatcher?.BeginInvoke(new Action(() => PawsDetected?.Invoke()));
        }

        public void Stop(string reason = null)
        {
            if (!IsActive) return;
            unlockTimer?.Stop();
            unlockTimer = null;
            LastSummary = new LockSummary
            {
                Mode = ActiveMode,
                Duration = DateTime.Now - (LockedAt ?? DateTime.Now),
                Keys = KeysCaught,
                PawTriggered = PawTriggered,
                Reason = reason,
            };
            Stats.KeysStopped += KeysCaught;
            if (ActiveMode == LockMode.Away) { Stats.PawKeys += KeysCaught; Stats.AwaySessions++; }
            else Stats.CleanSessions++;
            if (PawTriggered) Stats.PawAmbushes++;
            Settings.SaveStats(Stats);

            IsActive = false;
            LockedAt = null;
            EndsAt = null;
            PawTriggered = false;
            typed = "";
            heldKeys.Clear();
            if (TimerIsCustom) SelectTimer(0);
            Notify();
        }

        // MARK: Timer choices

        /// Picks one of the preset lengths (0 = no timer).
        public void SelectTimer(int seconds)
        {
            TimerIsCustom = false;
            Settings.TimerSeconds = seconds;
        }

        /// Switches to a custom length, starting from the last one entered. It isn't saved as the
        /// selection, so a restart is back on the saved preset.
        public void SelectCustomTimer()
        {
            TimerIsCustom = true;
        }

        /// Seconds the next Clean lock runs for (0 = until unlocked).
        public int EffectiveTimerSeconds => TimerIsCustom ? Settings.CustomSeconds : Settings.TimerSeconds;

        public void SetCustomSeconds(int seconds) => Settings.CustomSeconds = Math.Min(Math.Max(seconds, CustomMin), CustomMax);

        /// − / + move to the previous or next whole minute (2:01 → 3:00 → 4:00, and back down to 2:01).
        public void StepCustom(bool up)
        {
            int s = Settings.CustomSeconds;
            SetCustomSeconds(up ? (s / 60 + 1) * 60 : (s % 60 == 0 ? s - 60 : s / 60 * 60));
        }

        public void ResetStats()
        {
            Stats = new PawStats();
            Settings.SaveStats(Stats);
        }

        // MARK: Shortcut

        /// Listens for the next key combination (through the hook, so no app sees it) and makes it
        /// the shortcut. Esc cancels. It gives up on its own after 10 seconds, so keys are never
        /// held back for long.
        public void RecordShortcut()
        {
            if (IsActive || dispatcher == null) return;
            Recording = ShortcutRecording.Listening;
            recordingTimer?.Stop();
            recordingTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(10) };
            recordingTimer.Tick += (s, e) => StopRecordingShortcut();
            recordingTimer.Start();
            Notify();
        }

        public void StopRecordingShortcut()
        {
            recordingTimer?.Stop();
            recordingTimer = null;
            if (Recording == ShortcutRecording.Off) return;
            Recording = ShortcutRecording.Off;
            Notify();
        }

        public void ResetShortcut()
        {
            Settings.Shortcut = Shortcut.Standard;
            Notify();
        }

        /// "2:01", "15:00"
        public static string Clock(int seconds) => $"{seconds / 60}:{seconds % 60:00}";

        /// Accepts "5" (minutes) or "2:15" (minutes:seconds).
        public static int? ParseClock(string text)
        {
            var parts = (text ?? "").Trim().Split(':');
            if (parts.Length < 1 || parts.Length > 2 || !int.TryParse(parts[0], out int minutes)) return null;
            int seconds = 0;
            if (parts.Length == 2 && (!int.TryParse(parts[1], out seconds) || seconds < 0 || seconds > 59)) return null;
            return minutes * 60 + seconds;
        }

        /// UI work never runs inside the hook callback: Windows drops hooks that answer slowly.
        void Notify() => dispatcher?.BeginInvoke(new Action(() => Changed?.Invoke()));

        // MARK: Keyboard hook

        IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
        {
            if (nCode >= 0)
            {
                var info = (KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(KBDLLHOOKSTRUCT));
                int message = wParam.ToInt32();
                bool down = message == WM_KEYDOWN || message == WM_SYSKEYDOWN;
                bool injected = (info.flags & LLKHF_INJECTED) != 0;
                if (ShouldSwallow((int)info.vkCode, down, injected))
                    return (IntPtr)1;
            }
            return CallNextHookEx(hook, nCode, wParam, lParam);
        }

        /// Runs for every keystroke on the UI thread. Keep it cheap.
        bool ShouldSwallow(int vk, bool down, bool injected)
        {
            bool repeat = down && !pressed.Add(vk);
            if (!down) pressed.Remove(vk);

            // Recording a new shortcut: keys go to the shortcut field only; modifiers pass through.
            // Win combinations stay with Windows (swallowing them would open Start on release).
            if (Recording != ShortcutRecording.Off && !IsActive)
            {
                if (Modifiers.Contains(vk) || IsDown(VK_LWIN) || IsDown(VK_RWIN)) return false;
                if (down && !repeat) Record(vk);
                return true;
            }
            if (down && !repeat && IsShortcut(vk))
            {
                Toggle();
                return true;
            }
            if (IsActive)
            {
                if (down)
                {
                    KeysCaught++;
                    Notify();
                    if (PhraseTyped(vk)) Stop();
                }
                return true;
            }
            if (!injected && Settings.PawDetection && LooksLikePaws(vk, down))
            {
                Start(LockMode.Away, byPaws: true);
                return true;
            }
            return false;
        }

        /// AltGr types characters on many layouts (ł, €, @) and arrives as Ctrl+Alt, so a Ctrl+Alt
        /// shortcut never fires while it's held.
        bool IsShortcut(int vk)
        {
            var shortcut = Settings.Shortcut;
            if (vk != shortcut.Key) return false;
            var held = HeldModifiers();
            var ctrlAlt = ShortcutModifiers.Ctrl | ShortcutModifiers.Alt;
            return held == shortcut.Modifiers && !((held & ctrlAlt) == ctrlAlt && IsDown(VK_RMENU));
        }

        /// A shortcut needs Ctrl or Alt, so it can't take a plain letter away from every app.
        void Record(int vk)
        {
            var held = HeldModifiers();
            if (vk == VK_ESCAPE && held == ShortcutModifiers.None)
            {
                StopRecordingShortcut();
            }
            else if ((held & (ShortcutModifiers.Ctrl | ShortcutModifiers.Alt)) == 0)
            {
                Recording = ShortcutRecording.NeedsModifier;
                Notify();
            }
            else
            {
                Settings.Shortcut = new Shortcut(vk, held);
                StopRecordingShortcut();
            }
        }

        static ShortcutModifiers HeldModifiers() =>
            (IsDown(VK_CONTROL) ? ShortcutModifiers.Ctrl : 0)
            | (IsDown(VK_MENU) ? ShortcutModifiers.Alt : 0)
            | (IsDown(VK_SHIFT) ? ShortcutModifiers.Shift : 0)
            | (IsDown(VK_LWIN) || IsDown(VK_RWIN) ? ShortcutModifiers.Win : 0);

        static bool IsDown(int vk) => (GetAsyncKeyState(vk) & 0x8000) != 0;

        /// Keeps the last few typed characters and reports when they spell the unlock phrase.
        bool PhraseTyped(int vk)
        {
            string phrase = Settings.TrimmedPhrase;
            char? c = CharFor(vk);
            if (phrase.Length == 0 || c == null) return false;
            typed += c.Value;
            if (typed.Length > phrase.Length) typed = typed.Substring(typed.Length - phrase.Length);
            return typed == phrase;
        }

        /// Letters, digits and space map directly from virtual-key codes on every layout.
        static char? CharFor(int vk)
        {
            if (vk >= 'A' && vk <= 'Z') return char.ToLowerInvariant((char)vk);
            if (vk >= '0' && vk <= '9') return (char)vk;
            if (vk >= 0x60 && vk <= 0x69) return (char)('0' + vk - 0x60); // numpad
            if (vk == 0x20) return ' ';
            return null;
        }

        static readonly HashSet<int> Modifiers = new HashSet<int>
        {
            0x10, 0x11, 0x12, 0x14, 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0x5B, 0x5C,
        };

        /// A paw walking across the keyboard holds several keys at once; a sitting cat holds a
        /// couple of keys down for seconds. People rarely do either while typing.
        bool LooksLikePaws(int vk, bool down)
        {
            if (Modifiers.Contains(vk)) return false;
            var now = DateTime.Now;
            if (!down)
            {
                heldKeys.Remove(vk);
                return false;
            }
            if (!heldKeys.ContainsKey(vk)) heldKeys[vk] = now;

            foreach (var stale in heldKeys.Where(k => (now - k.Value).TotalSeconds >= 30).Select(k => k.Key).ToList())
                heldKeys.Remove(stale); // forget missed key-ups

            bool mashing = heldKeys.Count >= 4;
            bool sitting = heldKeys.Count >= 2 && heldKeys.Values.All(t => (now - t).TotalSeconds >= 3);
            return mashing || sitting;
        }

        // MARK: Auto-release

        /// Any of these mean the user is heading to (or already at) the lock or sign-in screen,
        /// so hand the keyboard back immediately.
        void WatchForLockAndSleep()
        {
            SystemEvents.SessionSwitch += OnSessionSwitch;
            SystemEvents.PowerModeChanged += OnPowerModeChanged;
            SystemEvents.SessionEnding += OnSessionEnding;
        }

        void OnSessionSwitch(object sender, SessionSwitchEventArgs e)
        {
            string reason = null;
            switch (e.Reason)
            {
                case SessionSwitchReason.SessionLock: reason = "PC locked"; break;
                case SessionSwitchReason.SessionLogoff: reason = "Signed out"; break;
                case SessionSwitchReason.ConsoleDisconnect:
                case SessionSwitchReason.RemoteDisconnect: reason = "Switched user"; break;
            }
            if (reason != null) Release(reason);
        }

        void OnPowerModeChanged(object sender, PowerModeChangedEventArgs e)
        {
            if (e.Mode == PowerModes.Suspend) Release("PC went to sleep");
        }

        void OnSessionEnding(object sender, SessionEndingEventArgs e) => Release("Shutting down");

        void Release(string reason)
        {
            // SystemEvents may fire on its own thread; all state lives on the UI thread.
            dispatcher?.Invoke(new Action(() =>
            {
                pressed.Clear();
                StopRecordingShortcut();
                Stop(reason);
            }));
        }

        public void Dispose()
        {
            if (dispatcher == null) return;
            SystemEvents.SessionSwitch -= OnSessionSwitch;
            SystemEvents.PowerModeChanged -= OnPowerModeChanged;
            SystemEvents.SessionEnding -= OnSessionEnding;
            if (hook != IntPtr.Zero)
            {
                UnhookWindowsHookEx(hook);
                hook = IntPtr.Zero;
            }
        }

        // MARK: Preview states

        public static readonly string[] PreviewStates =
        {
            "cleanReady", "cleanCustom", "withStats", "cleanTimer", "awayReady", "awayLocked", "pawsDetected", "backFromAway", "autoReleased",
        };

        /// Rendered with Settings open.
        public static readonly string[] SettingsPreviewStates = { "shortcutListening", "shortcutNeedsModifier", "shortcutCustom" };

        public static KeyboardBlocker Preview(string state)
        {
            var b = new KeyboardBlocker(Settings.InMemory(), null);
            var now = DateTime.Now;
            void Lock(LockMode mode, int keys, int since)
            {
                b.Settings.Mode = mode;
                b.ActiveMode = mode;
                b.IsActive = true;
                b.KeysCaught = keys;
                b.LockedAt = now.AddSeconds(-since);
            }
            switch (state)
            {
                case "cleanReady":
                    b.Settings.TimerSeconds = 120;
                    break;
                case "cleanCustom":
                    b.Settings.CustomSeconds = 150;
                    b.SelectCustomTimer();
                    break;
                case "withStats":
                    b.Stats = new PawStats { KeysStopped = 3118, PawKeys = 2431, PawAmbushes = 9, CleanSessions = 14, AwaySessions = 22 };
                    break;
                case "cleanTimer":
                    b.Settings.TimerSeconds = 120;
                    Lock(LockMode.Clean, 18, 20);
                    b.EndsAt = now.AddSeconds(40);
                    break;
                case "awayReady":
                    b.Settings.Mode = LockMode.Away;
                    break;
                case "awayLocked":
                    Lock(LockMode.Away, 7, 300);
                    break;
                case "pawsDetected":
                    Lock(LockMode.Away, 63, 45);
                    b.PawTriggered = true;
                    break;
                case "backFromAway":
                    b.Settings.Mode = LockMode.Away;
                    b.LastSummary = new LockSummary
                    {
                        Mode = LockMode.Away, Duration = TimeSpan.FromMinutes(47), Keys = 214, PawTriggered = true,
                    };
                    break;
                case "autoReleased":
                    b.LastSummary = new LockSummary
                    {
                        Mode = LockMode.Clean, Duration = TimeSpan.FromSeconds(95), Keys = 31, Reason = "PC locked",
                    };
                    break;
                case "shortcutListening":
                    b.Recording = ShortcutRecording.Listening;
                    break;
                case "shortcutNeedsModifier":
                    b.Recording = ShortcutRecording.NeedsModifier;
                    break;
                case "shortcutCustom":
                    b.Settings.Shortcut = new Shortcut('K', ShortcutModifiers.Ctrl | ShortcutModifiers.Shift);
                    break;
            }
            return b;
        }

        // MARK: Win32

        const int WH_KEYBOARD_LL = 13;
        const int WM_KEYDOWN = 0x0100;
        const int WM_SYSKEYDOWN = 0x0104;
        const uint LLKHF_INJECTED = 0x10;
        const int VK_SHIFT = 0x10, VK_CONTROL = 0x11, VK_MENU = 0x12, VK_ESCAPE = 0x1B, VK_LWIN = 0x5B, VK_RWIN = 0x5C, VK_RMENU = 0xA5;

        delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

        [StructLayout(LayoutKind.Sequential)]
        struct KBDLLHOOKSTRUCT
        {
            public uint vkCode;
            public uint scanCode;
            public uint flags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        [DllImport("user32.dll", SetLastError = true)]
        static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

        [DllImport("user32.dll", SetLastError = true)]
        static extern bool UnhookWindowsHookEx(IntPtr hhk);

        [DllImport("user32.dll")]
        static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("user32.dll")]
        static extern short GetAsyncKeyState(int vKey);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern IntPtr GetModuleHandle(string lpModuleName);
    }
}
