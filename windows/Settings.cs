using System;
using System.Diagnostics;
using Microsoft.Win32;

namespace PawsOff
{
    /// Auto follows the Windows light/dark app setting.
    public enum ThemeChoice { Auto, Light, Dark }

    /// Where Paws Off opens when it starts. The tray icon is always there.
    public enum StartPlace { Tray, Window }

    /// User settings, stored in HKCU\Software\PawsOff. Preview instances never touch the registry.
    public sealed class Settings
    {
        const string KeyPath = @"Software\PawsOff";
        const string RunKeyPath = @"Software\Microsoft\Windows\CurrentVersion\Run";
        const string RunValueName = "PawsOff";

        readonly bool persists;
        LockMode mode = LockMode.Clean;
        int timerSeconds;
        string unlockPhrase = "unlock";
        bool pawDetection = true;
        ThemeChoice theme = ThemeChoice.Auto;
        StartPlace startIn = StartPlace.Tray;

        /// True the very first time Paws Off runs (nothing saved yet).
        public bool IsFirstRun { get; private set; }

        Settings(bool persists) { this.persists = persists; }

        public static Settings InMemory() => new Settings(false);

        public static Settings Load()
        {
            var s = new Settings(true);
            using (var key = Registry.CurrentUser.OpenSubKey(KeyPath))
            {
                if (key == null) { s.IsFirstRun = true; return s; }
                if (Enum.TryParse(key.GetValue("Mode") as string, out LockMode m)) s.mode = m;
                if (key.GetValue("TimerSeconds") is int t) s.timerSeconds = t;
                if (key.GetValue("UnlockPhrase") is string p) s.unlockPhrase = p;
                if (key.GetValue("PawDetection") is int paw) s.pawDetection = paw != 0;
                if (Enum.TryParse(key.GetValue("Theme") as string, out ThemeChoice th)) s.theme = th;
                if (Enum.TryParse(key.GetValue("StartIn") as string, out StartPlace sp)) s.startIn = sp;
            }
            return s;
        }

        public LockMode Mode
        {
            get => mode;
            set { mode = value; Save("Mode", value.ToString()); }
        }

        public int TimerSeconds
        {
            get => timerSeconds;
            set { timerSeconds = value; Save("TimerSeconds", value); }
        }

        public string UnlockPhrase
        {
            get => unlockPhrase;
            set { unlockPhrase = value ?? ""; Save("UnlockPhrase", unlockPhrase); }
        }

        public bool PawDetection
        {
            get => pawDetection;
            set { pawDetection = value; Save("PawDetection", value ? 1 : 0); }
        }

        public StartPlace StartIn
        {
            get => startIn;
            set { startIn = value; Save("StartIn", value.ToString()); }
        }

        public ThemeChoice Theme
        {
            get => theme;
            set { theme = value; Save("Theme", value.ToString()); }
        }

        /// True when the app should draw dark: the user's choice, or the Windows setting on Auto.
        public bool UsesDarkTheme
        {
            get
            {
                if (theme != ThemeChoice.Auto) return theme == ThemeChoice.Dark;
                using (var personalize = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"))
                    return personalize?.GetValue("AppsUseLightTheme") is int light && light == 0;
            }
        }

        /// Lowercased phrase with surrounding spaces removed; empty means "click to unlock only".
        public string TrimmedPhrase => unlockPhrase.Trim().ToLowerInvariant();

        /// Starts Paws Off (hidden in the tray) when the user signs in.
        public bool LaunchAtLogin
        {
            get
            {
                using (var run = Registry.CurrentUser.OpenSubKey(RunKeyPath))
                    return run?.GetValue(RunValueName) != null;
            }
            set
            {
                if (!persists) return;
                using (var run = Registry.CurrentUser.CreateSubKey(RunKeyPath))
                {
                    if (value)
                        run.SetValue(RunValueName, $"\"{ExePath}\" --minimized");
                    else
                        run.DeleteValue(RunValueName, false);
                }
            }
        }

        static string ExePath
        {
            get { using (var p = Process.GetCurrentProcess()) return p.MainModule.FileName; }
        }

        void Save(string name, object value)
        {
            if (!persists) return;
            using (var key = Registry.CurrentUser.CreateSubKey(KeyPath))
                key.SetValue(name, value);
        }
    }
}
