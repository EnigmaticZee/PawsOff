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
    }

    /// Owns one low-level keyboard hook for the app's lifetime. While unlocked it passes every
    /// key through (watching only for the global shortcut and paw patterns); while locked it
    /// swallows every key. Locking the PC, sleeping or signing out releases the keyboard.
    public sealed class KeyboardBlocker : IDisposable
    {
        public static readonly int[] TimerChoices = { 0, 30, 60, 120 };
        public const string ShortcutLabel = "Ctrl+Alt+Shift+L";

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

        readonly Dispatcher dispatcher;
        readonly LowLevelKeyboardProc hookProc; // kept in a field so the GC can't collect it
        IntPtr hook = IntPtr.Zero;
        DispatcherTimer unlockTimer;
        string typed = "";
        readonly HashSet<int> pressed = new HashSet<int>();
        readonly Dictionary<int, DateTime> heldKeys = new Dictionary<int, DateTime>();

        /// Pass a dispatcher to install the hook; null makes an inert instance for previews.
        public KeyboardBlocker(Settings settings, Dispatcher dispatcher)
        {
            Settings = settings;
            this.dispatcher = dispatcher;
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
            ActiveMode = requested ?? Settings.Mode;
            PawTriggered = byPaws;
            KeysCaught = byPaws ? heldKeys.Count : 0;
            typed = "";
            heldKeys.Clear();
            LastSummary = null;
            var now = DateTime.Now;
            LockedAt = now;

            if (ActiveMode == LockMode.Clean && Settings.TimerSeconds > 0)
            {
                EndsAt = now.AddSeconds(Settings.TimerSeconds);
                unlockTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(Settings.TimerSeconds) };
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
            IsActive = false;
            LockedAt = null;
            EndsAt = null;
            PawTriggered = false;
            typed = "";
            heldKeys.Clear();
            Notify();
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

        static bool IsShortcut(int vk) =>
            vk == 'L' && IsDown(VK_CONTROL) && IsDown(VK_MENU) && IsDown(VK_SHIFT)
            && !IsDown(VK_LWIN) && !IsDown(VK_RWIN);

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
            "cleanReady", "cleanTimer", "awayReady", "awayLocked", "pawsDetected", "backFromAway", "autoReleased",
        };

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
                    b.Settings.TimerSeconds = 60;
                    break;
                case "cleanTimer":
                    b.Settings.TimerSeconds = 60;
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
            }
            return b;
        }

        // MARK: Win32

        const int WH_KEYBOARD_LL = 13;
        const int WM_KEYDOWN = 0x0100;
        const int WM_SYSKEYDOWN = 0x0104;
        const uint LLKHF_INJECTED = 0x10;
        const int VK_SHIFT = 0x10, VK_CONTROL = 0x11, VK_MENU = 0x12, VK_LWIN = 0x5B, VK_RWIN = 0x5C;

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
